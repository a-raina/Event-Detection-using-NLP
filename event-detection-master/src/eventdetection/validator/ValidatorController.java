package eventdetection.validator;

import java.io.Closeable;
import java.io.IOException;
import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLClassLoader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.Collection;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.stream.Collectors;

import org.postgresql.util.PGobject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import toberumono.json.JSONArray;
import toberumono.json.JSONData;
import toberumono.json.JSONObject;
import toberumono.json.JSONString;
import toberumono.json.JSONSystem;
import toberumono.structures.tuples.Triple;

import static eventdetection.common.ThreadingUtils.pool;

import eventdetection.common.Article;
import eventdetection.common.ArticleManager;
import eventdetection.common.DBConnection;
import eventdetection.common.Query;
import eventdetection.common.ThreadingUtils;
import eventdetection.pipeline.PipelineComponent;
import eventdetection.validator.types.ArticleOnlyValidator;
import eventdetection.validator.types.ManyToManyValidator;
import eventdetection.validator.types.ManyToOneValidator;
import eventdetection.validator.types.OneToManyValidator;
import eventdetection.validator.types.OneToOneValidator;
import eventdetection.validator.types.QueryOnlyValidator;
import eventdetection.validator.types.Validator;
import eventdetection.validator.types.ValidatorType;

/**
 * A class that manages multiple validation algorithms and allows them to run in parallel.
 * 
 * @author Joshua Lipstone
 */
public class ValidatorController implements PipelineComponent, Closeable {
	private final Connection connection;
	private final Map<ValidatorType, Map<String, ValidatorWrapper<?>>> validators;
	private static final Logger logger = LoggerFactory.getLogger("ValidatorController");
	private final ArticleManager articleManager;
	private final String validatorsTable, resultsTable;
	
	/**
	 * Constructs a {@link ValidatorController} with the given configuration data.
	 * 
	 * @param config
	 *            the {@link JSONObject} holding the configuration data
	 * @throws SQLException
	 *             if an error occurs while connecting to the database
	 */
	public ValidatorController(JSONObject config) throws SQLException {
		this.connection = DBConnection.getConnection();
		this.validators = new EnumMap<>(ValidatorType.class);
		for (ValidatorType vt : ValidatorType.values())
			validators.put(vt, new LinkedHashMap<>());
		JSONObject paths = (JSONObject) config.get("paths");
		JSONObject articles = (JSONObject) config.get("articles");
		this.articleManager = new ArticleManager(connection, ((JSONObject) config.get("tables")).get("articles").value().toString(), paths, articles);
		validatorsTable = ((JSONString) ((JSONObject) config.get("tables")).get("validators")).value();
		resultsTable = ((JSONString) ((JSONObject) config.get("tables")).get("results")).value();
		loadValidators(((JSONArray) paths.get("validators")).value().stream().map(a -> Paths.get(((JSONString) a).value())).collect(Collectors.toList()));
	}
	
	private void loadValidators(Collection<Path> paths) {
		ClassLoader classloader = new URLClassLoader(paths.stream().map(p -> { //Yes, I swear that the this code converts the Paths into URLs and stores them in an array.
			try {
				return p.toUri().toURL();
			}
			catch (MalformedURLException e) { //This should never happen because we are generating a URL from a known path
				logger.error(p + " could not be converted to a valid URL.");
				return null;
			}
		}).collect(Collectors.toList()).toArray(new URL[0]));
		try (PreparedStatement stmt = connection.prepareStatement("select * from " + validatorsTable); ResultSet rs = stmt.executeQuery()) {
			while (rs.next()) {
				try {
					if (rs.getBoolean("enabled")) {
						PGobject sqlParameters = (PGobject) rs.getObject("parameters");
						JSONData<?> rawJSON = null;
						if (sqlParameters != null) {
							sqlParameters.setType("jsonb");
							rawJSON = JSONSystem.parseJSON(sqlParameters.getValue());
						}
						JSONObject parameters = null;
						if (rawJSON instanceof JSONString) { //If it is a JSON String, then it is the path to a JSON file
							Path loc = null;
							String filename = ((JSONString) rawJSON).value();
							for (Path p : paths)
								if (Files.exists(loc = p.resolve(filename)))
									break;
							parameters = (JSONObject) JSONSystem.loadJSON(loc);
						}
						else if (rawJSON instanceof JSONObject) //If it is a JSON Object, then it holds the parameters
							parameters = (JSONObject) rawJSON;
						else if (rawJSON != null) //If the parameters field is null, then there isn't a problem
							logger.warn("The parameters column for the validator, " + rs.getString("algorithm") + ", was not null, but could not be interpreted as a JSON Object or JSON String.");
						ValidatorType type = ValidatorType.valueOf(rs.getString("validator_type"));
						ValidatorWrapper<?> vw = null;
						switch (type) {
							case ManyToMany:
								vw = new ManyToManyValidatorWrapper(rs, classloader, parameters);
								break;
							case ManyToOne:
								vw = new ManyToOneValidatorWrapper(rs, classloader, parameters);
								break;
							case OneToMany:
								vw = new OneToManyValidatorWrapper(rs, classloader, parameters);
								break;
							case OneToOne:
								vw = new OneToOneValidatorWrapper(rs, classloader, parameters);
								break;
							case QueryOnly:
								vw = new QueryOnlyValidatorWrapper(rs, classloader, parameters);
								break;
							case ArticleOnly:
								vw = new ArticleOnlyValidatorWrapper(rs, classloader, parameters);
								break;
							default:
								break;
						}
						validators.get(type).put(vw.getName(), vw);
					}
				}
				catch (SQLException | ClassCastException | SecurityException | IOException | ReflectiveOperationException e) {
					logger.error("Unable to initialize the validator, " + rs.getString("algorithm") + ".", e);
				}
			}
		}
		catch (SQLException e) {
			logger.error("A major SQL error occured while attempting to load the validators from the " + validatorsTable + " table.");
		}
	}
	
	/**
	 * Main method of the validation program.
	 * 
	 * @param args
	 *            the command line arguments
	 * @throws IOException
	 *             if an I/O error occurs
	 * @throws SQLException
	 *             if an SQL error occurs
	 */
	public static void main(String[] args) throws IOException, SQLException {
		Path configPath = Paths.get("./configuration.json"); //The configuration file defaults to "./configuration.json", but can be changed with arguments
		int action = 0;
		Collection<Integer> articleIDs = new LinkedHashSet<>();
		Collection<Integer> queryIDs = new LinkedHashSet<>();
		for (String arg : args) {
			if (arg.equalsIgnoreCase("-c"))
				action = 0;
			else if (arg.equalsIgnoreCase("-a"))
				action = 1;
			else if (arg.equalsIgnoreCase("-q"))
				action = 2;
			else if (action == 0)
				configPath = Paths.get(arg);
			else if (action == 1)
				articleIDs.add(Integer.parseInt(arg));
			else if (action == 2)
				queryIDs.add(Integer.parseInt(arg));
		}
		JSONObject config = (JSONObject) JSONSystem.loadJSON(configPath);
		DBConnection.configureConnection((JSONObject) config.get("database"));
		try (Connection connection = DBConnection.getConnection(); ValidatorController vc = new ValidatorController(config);) {
			vc.executeValidators(queryIDs, articleIDs);
		}
	}
	
	/**
	 * Executes the {@link Validator Validators} registered with the {@link ValidatorController} on the given
	 * {@link Collection} of {@link Query} IDs and {@link Collection} of {@link Article} IDs after loading them from the
	 * database and writes the results to the database.
	 * 
	 * @param queryIDs
	 *            the IDs of the {@link Query Queries} to be validated
	 * @param articleIDs
	 *            the IDs of the {@link Article Articles} against which the {@link Query Queries} are to be validated
	 * @throws SQLException
	 *             if an error occurs while reading from or writing to the database
	 * @throws IOException
	 *             if an error occurs while securing access to the serialized {@link Article Articles}
	 */
	public void executeValidators(Collection<Integer> queryIDs, Collection<Integer> articleIDs) throws SQLException, IOException {
		synchronized (connection) {
			execute(ThreadingUtils.loadQueries(queryIDs), ThreadingUtils.loadArticles(articleManager, articleIDs));
		}
	}
	
	/**
	 * Executes the {@link Validator Validators} registered with the {@link ValidatorController} on the given
	 * {@link Collection} of {@link Query} IDs and {@link Collection} of {@link Article} IDs after loading them from the
	 * database and writes the results to the database.
	 * 
	 * @param queries
	 *            the IDs of the {@link Query Queries} to be validated
	 * @param articles
	 *            the IDs of the {@link Article Articles} against which the {@link Query Queries} are to be validated
	 * @throws SQLException
	 *             if an error occurs while reading from or writing to the database
	 */
	public void execute(Map<Integer, Query> queries, Map<Integer, Article> articles) throws SQLException {
		execute(queries, articles, new ArrayList<>());
	}
		
	@Override
	public void execute(Map<Integer, Query> queries, Map<Integer, Article> articles, Collection<ValidationResult> results) throws SQLException {
		synchronized (connection) {
			List<Triple<Integer, ValidationAlgorithm, Future<ValidationResult[]>>> futureResults = new ArrayList<>();
			for (ValidatorWrapper<?> vw : validators.get(ValidatorType.ManyToMany).values()) {
				try {
					futureResults.add(new Triple<>(null, vw, pool.submit(() -> vw.validate(queries.values(), articles.values()))));
				}
				catch (IllegalArgumentException e) {
					logger.error("Unable to initialize the validator, " + vw.getName() + ", for queries " + queries.keySet().toString() + " and articles " + articles.keySet().toString(), e);
				}
			}
			for (ValidatorWrapper<?> vw : validators.get(ValidatorType.OneToMany).values()) {
				for (Query query : queries.values()) {
					try {
						futureResults.add(new Triple<>(query.getID(), vw, pool.submit(() -> vw.validate(query, articles))));
					}
					catch (IllegalArgumentException e) {
						logger.error("Unable to initialize the validator, " + vw.getName() + ", for query " + query.getID() + " and articles " + articles.keySet().toString(), e);
					}
				}
			}
			for (ValidatorWrapper<?> vw : validators.get(ValidatorType.ManyToOne).values()) {
				for (Article article : articles.values()) {
					try {
						futureResults.add(new Triple<>(null, vw, pool.submit(() -> vw.validate(queries.values(), article))));
					}
					catch (IllegalArgumentException e) {
						logger.error("Unable to initialize the validator, " + vw.getName() + ", for queries " + queries.keySet().toString() + " and article " + article.getID(), e);
					}
				}
			}
			//Unfortunately, we can only perform existence checks for one-to-one validation algorithms
			try (PreparedStatement stmt = connection.prepareStatement("select * from " + resultsTable + " as vr where vr.query = ? and vr.algorithm = ? and vr.article = ?")) {
				for (Query query : queries.values()) {
					stmt.setInt(1, query.getID());
					for (Article article : articles.values()) {
						stmt.setInt(3, article.getID());
						for (ValidatorWrapper<?> vw : validators.get(ValidatorType.OneToOne).values()) {
							stmt.setInt(2, vw.getID());
							try (ResultSet rs = stmt.executeQuery()) {
								if (rs.next()) { //If we've already processed the current article with the current validator for the current query
									results.add(new ValidationResult(rs, vw)); //Add the results for (query, article, algorithm) tuples that we have already processed
									continue;
								}
							}
							try {
								futureResults.add(new Triple<>(query.getID(), vw, pool.submit(() -> vw.validate(query, article))));
							}
							catch (IllegalArgumentException e) {
								logger.error("Unable to initialize the validator, " + vw.getName() + ", for query " + query.getID() + " and article " + article.getID(), e);
							}
						}
					}
				}
			}
			String statement = "insert into " + resultsTable + " as vr (query, algorithm, article, validates, invalidates) values (?, ?, ?, ?, ?) " +
					"ON CONFLICT (query, algorithm, article) DO UPDATE set (validates, invalidates) = (EXCLUDED.validates, EXCLUDED.invalidates)"; //This is valid as of PostgreSQL 9.5
			try (PreparedStatement stmt = connection.prepareStatement(statement)) {
				for (Triple<Integer, ValidationAlgorithm, Future<ValidationResult[]>> result : futureResults) {
					try {
						ValidationResult[] ress = result.getZ().get();
						for (ValidationResult res : ress) {
							if (res.getQueryID() == null) //This updates the queryID in the object so that it continues on to other algorithms correctly.
								res = new ValidationResult(result.getX(), res.getArticleID(), res.getValidates(), res.getInvalidates());
							String stringVer = "(" + res.getQueryID() + ", " + result.getY().getID() + ", " + res.getArticleID() + ") -> (" + res.getValidates() + ", " +
									(res.getInvalidates() == null ? "null" : res.getInvalidates()) + ")";
							if (res.getValidates().isNaN() || (res.getInvalidates() != null && res.getInvalidates().isNaN())) {
								logger.error("Cannot add " + stringVer + " to the database because it has NaN values.");
								continue;
							}
							stmt.setInt(1, res.getQueryID());
							stmt.setInt(2, result.getY().getID());
							stmt.setInt(3, res.getArticleID());
							stmt.setFloat(4, res.getValidates().floatValue());
							if (res.getInvalidates() != null)
								stmt.setFloat(5, res.getInvalidates().floatValue());
							else
								stmt.setNull(5, Types.REAL);
							stmt.executeUpdate();
							logger.info("Added " + stringVer + " to the database.");
							res.setAlgorithm(result.getY());
							results.add(res);
						}
					}
					catch (InterruptedException e) {
						e.printStackTrace();
					}
					catch (ExecutionException e) {
						e.getCause().printStackTrace();
					}
				}
			}
		}
	}
	
	@Override
	public void close() throws IOException {
		articleManager.close();
		try {
			connection.close();
		}
		catch (SQLException e) {
			logger.error("An SQL error occured while closing a ValidatorController's Connection.", e);
		}
	}
}

abstract class ValidatorWrapper<T> implements ValidationAlgorithm { //We're doing this to save memory
	private static final Logger logger = LoggerFactory.getLogger("ValidatorWrapper");
	
	private final int id;
	private final String name;
	protected final T instance;
	private final double threshold;
	
	@SuppressWarnings("unchecked")
	public ValidatorWrapper(ResultSet rs, ClassLoader classloader, JSONObject parameters) throws SQLException, ReflectiveOperationException {
		id = rs.getInt("id");
		name = rs.getString("algorithm");
		threshold = rs.getDouble("threshold");
		Class<? extends T> clazz = (Class<? extends T>) classloader.loadClass(rs.getString("base_class"));
		if (parameters != null && parameters.containsKey("parameters")) //Backwards compatibility
			parameters = (JSONObject) parameters.get("parameters");
		JSONObject instanceParameters = parameters != null ? (JSONObject) parameters.get("instance") : null;
		
		Constructor<? extends T> constructor = null;
		if (instanceParameters != null)
			try {
				constructor = clazz.getConstructor(JSONObject.class);
			}
			catch (NoSuchMethodException e) {
				if (instanceParameters != null)
					logger.warn("Validator " + name + " has declared instance parameters but no constructor for them.");
				constructor = clazz.getConstructor();
			}
		else
			constructor = clazz.getConstructor();
		constructor.setAccessible(true);
		if (parameters != null && parameters.containsKey("static"))
			loadStaticProperties(clazz, (JSONObject) parameters.get("static"));
		if (constructor.getParameterCount() > 0)
			instance = constructor.newInstance(instanceParameters);
		else
			instance = constructor.newInstance();
	}
	
	private void loadStaticProperties(Class<? extends T> clazz, JSONObject properties) {
		try {
			Method staticInit = clazz.getMethod("loadStaticParameters", JSONObject.class);
			staticInit.setAccessible(true);
			try {
				staticInit.invoke(null, properties);
			}
			catch (IllegalAccessException | IllegalArgumentException | InvocationTargetException e) {
				logger.error("Failed to invoke the found static property initialization method for " + name, e);
			}
		}
		catch (NoSuchMethodException | SecurityException e) {
			logger.warn("Validator " + name + " has declared static parameters but no static parameter initialization method for them.");
		}
	}
	
	@Override
	public Integer getID() {
		return id;
	}
	
	@Override
	public String toString() {
		return getID() + "/" + getName();
	}
	
	public String getName() {
		return name;
	}

	@Override
	public boolean doesValidate(ValidationResult result) {
		return result.getValidates() >= threshold;
	}
	
	public abstract ValidationResult[] validate(Object... args) throws Exception;
}

class OneToOneValidatorWrapper extends ValidatorWrapper<OneToOneValidator> {
	
	public OneToOneValidatorWrapper(ResultSet rs, ClassLoader classloader, JSONObject parameters) throws SQLException, ReflectiveOperationException {
		super(rs, classloader, parameters);
	}
	
	@Override
	public ValidationResult[] validate(Object... args) throws Exception {
		return instance.call((Query) args[0], (Article) args[1]);
	}
}

class OneToManyValidatorWrapper extends ValidatorWrapper<OneToManyValidator> {
	
	public OneToManyValidatorWrapper(ResultSet rs, ClassLoader classloader, JSONObject parameters) throws SQLException, ReflectiveOperationException {
		super(rs, classloader, parameters);
	}
	
	@Override
	@SuppressWarnings("unchecked")
	public ValidationResult[] validate(Object... args) throws Exception {
		return instance.call((Query) args[0], (Collection<Article>) args[1]);
	}
}

class ManyToOneValidatorWrapper extends ValidatorWrapper<ManyToOneValidator> {
	
	public ManyToOneValidatorWrapper(ResultSet rs, ClassLoader classloader, JSONObject parameters) throws SQLException, ReflectiveOperationException {
		super(rs, classloader, parameters);
	}
	
	@Override
	@SuppressWarnings("unchecked")
	public ValidationResult[] validate(Object... args) throws Exception {
		return instance.call((Collection<Query>) args[0], (Article) args[1]);
	}
}

class ManyToManyValidatorWrapper extends ValidatorWrapper<ManyToManyValidator> {
	
	public ManyToManyValidatorWrapper(ResultSet rs, ClassLoader classloader, JSONObject parameters) throws SQLException, ReflectiveOperationException {
		super(rs, classloader, parameters);
	}
	
	@Override
	@SuppressWarnings("unchecked")
	public ValidationResult[] validate(Object... args) throws Exception {
		return instance.call((Collection<Query>) args[0], (Collection<Article>) args[1]);
	}
}

class QueryOnlyValidatorWrapper extends ValidatorWrapper<QueryOnlyValidator> {
	
	public QueryOnlyValidatorWrapper(ResultSet rs, ClassLoader classloader, JSONObject parameters) throws SQLException, ReflectiveOperationException {
		super(rs, classloader, parameters);
	}
	
	@Override
	public ValidationResult[] validate(Object... args) throws Exception {
		return instance.call((Query) args[0]);
	}
}

class ArticleOnlyValidatorWrapper extends ValidatorWrapper<ArticleOnlyValidator> {
	
	public ArticleOnlyValidatorWrapper(ResultSet rs, ClassLoader classloader, JSONObject parameters) throws SQLException, ReflectiveOperationException {
		super(rs, classloader, parameters);
	}
	
	@Override
	public ValidationResult[] validate(Object... args) throws Exception {
		return instance.call((Article) args[0]);
	}
}
