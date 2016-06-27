package eventdetection.aggregator;

import java.io.Closeable;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import toberumono.json.JSONNumber;
import toberumono.json.JSONObject;
import toberumono.json.JSONSystem;

import eventdetection.common.Article;
import eventdetection.common.ArticleManager;
import eventdetection.common.DBConnection;
import eventdetection.common.IOSQLExceptedRunnable;
import eventdetection.common.Query;
import eventdetection.common.ThreadingUtils;
import eventdetection.pipeline.Pipeline;
import eventdetection.pipeline.PipelineComponent;
import eventdetection.validator.ValidationResult;
import eventdetection.validator.ValidatorController;

/**
 * A class that manages the aggregator algorithm that combines the results from all of the validation methods to finally
 * determine whether a {@link Query} has happened.
 * 
 * @author Joshua Lipstone
 */
public class AggregatorController implements PipelineComponent, Closeable {
	private final Connection connection;
	private static final Logger logger = LoggerFactory.getLogger("AggregatorController");
	private final PreparedStatement query;
	private final double globalThreshold;
	private boolean closed;
	
	/**
	 * Constructs a {@link ValidatorController} with the given configuration data.
	 * 
	 * @param config
	 *            the {@link JSONObject} holding the configuration data
	 * @throws SQLException
	 *             if an error occurs while connecting to the database
	 */
	public AggregatorController(JSONObject config) throws SQLException {
		connection = DBConnection.getConnection();
		query = constructQuery((JSONObject) config.get("tables"));
		globalThreshold = ((JSONNumber<?>) ((JSONObject) config.get("aggregator")).get("global-threshold")).value().doubleValue();
	}
	
	private PreparedStatement constructQuery(JSONObject tables) throws SQLException {
		String statement = "select vr.query as \"vr.query\", vr.algorithm as \"vr.algorithm\", vr.article as \"vr.article\", " +
				"vr.validates as \"vr.validates\", vr.invalidates as \"vr.invalidates\", va.threshold as \"va.threshold\" " +
				"from validation_results as vr inner join validation_algorithms as va on vr.algorithm = va.id;";
		return connection.prepareStatement(statement);
	}
	
	@Override
	public void execute(Map<Integer, Query> queries, Map<Integer, Article> articles, Collection<ValidationResult> results) throws IOException, SQLException {
		executeAggregator(queries, articles, results);
	}
	
	/**
	 * Runs the aggregator algorithm using the given {@link Query Queries} and {@link Article Articles}.<br>
	 * This method is thread-safe and uses the interprocess lock from
	 * {@link ThreadingUtils#executeTask(IOSQLExceptedRunnable)}.
	 * 
	 * @param queries
	 *            the {@link Query Queries} to validate
	 * @param articles
	 *            the {@link Article Articles} on which to validate them
	 * @return a {@link List} containing the {@link Query Queries} that were validated
	 * @throws IOException
	 *             if an error occurs while interacting with the interprocess lock
	 * @throws SQLException
	 *             if an SQL error occurs while reading the {@link Query Queries} from the database
	 */
	public List<Query> executeAggregator(Map<Integer, Query> queries, Map<Integer, Article> articles) throws IOException, SQLException {
		return executeAggregator(queries, articles, new ArrayList<>());
	}
	
	/**
	 * Runs the aggregator algorithm using the given {@link Query Queries} and {@link Article Articles}.<br>
	 * This method is thread-safe and uses the interprocess lock from
	 * {@link ThreadingUtils#executeTask(IOSQLExceptedRunnable)}.
	 * 
	 * @param queries
	 *            the {@link Query Queries} to validate
	 * @param articles
	 *            the {@link Article Articles} on which to validate them
	 * @param results
	 *            a {@link Collection} containing {@link ValidationResult} objects (for chaining within {@link Pipeline})
	 * @return a {@link List} containing the {@link Query Queries} that were validated
	 * @throws IOException
	 *             if an error occurs while interacting with the interprocess lock
	 * @throws SQLException
	 *             if an SQL error occurs while reading the {@link Query Queries} from the database
	 */
	public List<Query> executeAggregator(Map<Integer, Query> queries, Map<Integer, Article> articles, Collection<ValidationResult> results) throws IOException, SQLException {
		Map<Integer, Double> sum = new HashMap<>(), count = new HashMap<>();
		for (Integer id : queries.keySet()) {
			sum.put(id, 0.0);
			count.put(id, 0.0);
		}
		if (results.size() == 0) {
			ThreadingUtils.executeTask(() -> {
				try (ResultSet rs = query.executeQuery()) {
					Integer query, article;
					while (rs.next()) {
						if (!queries.containsKey(query = rs.getInt("vr.query")) || !articles.containsKey(article = rs.getInt("vr.article")))
							continue;
						if (rs.getFloat("vr.validates") >= rs.getFloat("va.threshold")) {
							sum.put(query, sum.get(query) + 1);
							logger.info("Article " + article + " validates query " + query);
						}
						count.put(query, count.get(query) + 1);
					}
				}
			});
		}
		else {
			for (ValidationResult res : results) {
				if (res.doesValidate()) {
					if (!sum.containsKey(res.getQueryID()))
						sum.put(res.getQueryID(), 0.0);
					sum.put(res.getQueryID(), sum.get(res.getQueryID()) + 1);
					logger.info("Article " + res.getArticleID() + " validates query " + res.getQueryID());
				}
			}
		}
		Integer key;
		for (Iterator<Integer> iter = sum.keySet().iterator(); iter.hasNext();) {
			key = iter.next();
			if (sum.get(key) < globalThreshold)
				iter.remove();
		}
		List<Query> output = sum.keySet().stream().map(id -> queries.get(id)).collect(Collectors.toList());
		ValidationResult res;
		for (Iterator<ValidationResult> iter = results.iterator(); iter.hasNext();) {
			res = iter.next();
			if (!sum.containsKey(res.getQueryID()) || !res.doesValidate())
				iter.remove();
		}
		return output;
	}
	
	/**
	 * Main method of the aggregator program.
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
		try (Connection connection = DBConnection.getConnection(); AggregatorController vc = new AggregatorController(config); ArticleManager articleManager = new ArticleManager(connection, config)) {
			vc.executeAggregator(ThreadingUtils.loadQueries(queryIDs), ThreadingUtils.loadArticles(articleManager, articleIDs));
		}
	}
	
	@Override
	public void close() throws IOException {
		if (closed)
			return;
		closed = true;
		try {
			connection.close();
		}
		catch (SQLException e) {
			logger.error("An SQL error occured while closing a AggregatorController's Connection.", e);
		}
	}
}
