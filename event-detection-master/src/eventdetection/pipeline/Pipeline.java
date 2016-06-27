package eventdetection.pipeline;

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
import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import toberumono.json.JSONObject;
import toberumono.json.JSONSystem;

import eventdetection.aggregator.AggregatorController;
import eventdetection.common.Article;
import eventdetection.common.ArticleManager;
import eventdetection.common.DBConnection;
import eventdetection.common.Query;
import eventdetection.common.SubprocessHelpers;
import eventdetection.common.ThreadingUtils;
import eventdetection.downloader.DownloaderController;
import eventdetection.validator.ValidationResult;
import eventdetection.validator.ValidatorController;

/**
 * Implements an easily-expanded pipeline system for the project.
 * 
 * @author Joshua Lipstone
 */
public class Pipeline implements PipelineComponent, Closeable {
	private static final Logger logger = LoggerFactory.getLogger("Pipeline");
	
	private final ArticleManager articleManager;
	private final List<PipelineComponent> components;
	private boolean closed;
	
	/**
	 * Creates a new {@link Pipeline} instance.
	 * 
	 * @param config
	 *            a {@link JSONObject} holding the configuration data for the {@link Pipeline} and its components
	 * @param queryIDs
	 *            the IDs of the {@link Query Queries} to use. This must be empty or {@code null} for the downloader to be
	 *            run
	 * @param articleIDs
	 *            the IDs of the {@link Article Articles} to use. This must be empty or {@code null} for the downloader to be
	 *            run
	 * @param addDefaultComponents
	 *            whether the default pipeline components should be added (Downloader, preprocessors, and Validator)
	 * @throws IOException
	 *             if an error occurs while initializing the Downloader
	 * @throws SQLException
	 *             if an error occurs while connecting to the database
	 */
	public Pipeline(JSONObject config, Collection<Integer> queryIDs, Collection<Integer> articleIDs, boolean addDefaultComponents) throws IOException, SQLException {
		final Collection<Integer> qIDs = queryIDs == null ? Collections.emptyList() : queryIDs, aIDs = articleIDs == null ? Collections.emptyList() : articleIDs;
		articleManager = new ArticleManager(config);
		
		components = new ArrayList<>();
		if (addDefaultComponents) {
			addComponent((queries, articles, results) -> ThreadingUtils.loadQueries(qIDs, queries));
			addComponent((queries, articles, results) -> ThreadingUtils.cleanUpArticles(articleManager));
			addComponent((queries, articles, results) -> ThreadingUtils.loadArticles(articleManager, aIDs, articles));
			if (articleIDs.size() == 0) { //Only run the Downloader if no articles are specified.
				addComponent(new DownloaderController(config));
				addComponent((queries, articles, results) -> {
					try {
						SubprocessHelpers.executePythonProcess(Paths.get("./Daemons/ArticleProcessorDaemon.py"), "--no-lock").waitFor();
					}
					catch (InterruptedException e) {}
				});
				addComponent((queries, articles, results) -> {
					try {
						SubprocessHelpers.executePythonProcess(Paths.get("./Daemons/QueryProcessorDaemon.py"), "--no-lock").waitFor();
					}
					catch (InterruptedException e) {}
				});
			}
			addComponent(new ValidatorController(config));
			addComponent(new AggregatorController(config));
			addComponent(Pipeline::filterUsedArticles);
			addComponent(new Notifier());
			
		}
	}
	
	private static void filterUsedArticles(Map<Integer, Query> queries, Map<Integer, Article> articles, Collection<ValidationResult> results) throws IOException, SQLException {
		Connection connection = DBConnection.getConnection();
		ValidationResult res;
		try (PreparedStatement seek = connection.prepareStatement("select * from query_articles where query = ? and article = ? and notification_sent = ?");
				PreparedStatement update = connection.prepareStatement("insert into query_articles (query, article, notification_sent) values (?, ?, ?) " +
						"on conflict (query, article) do update set (notification_sent) = (EXCLUDED.notification_sent)")) {
			seek.setBoolean(3, true);
			update.setBoolean(3, true);
			for (Iterator<ValidationResult> iter = results.iterator(); iter.hasNext();) {
				res = iter.next();
				seek.setInt(1, res.getQueryID());
				seek.setInt(2, res.getArticleID());
				try (ResultSet rs = seek.executeQuery()) {
					if (rs.next()) //If we've already used it, don't bother
						iter.remove();
					else {
						update.setInt(1, res.getQueryID());
						update.setInt(2, res.getArticleID());
						update.executeUpdate();
					}
				}
			}
		}
	}
	
	/**
	 * Main method for the {@link Pipeline} entry point.
	 * 
	 * @param args
	 *            the command-line arguments
	 * @throws IOException
	 *             if an error occurs while initializing the Downloader
	 * @throws SQLException
	 *             if an error occurs while connecting to the database
	 */
	public static void main(String[] args) throws IOException, SQLException {
		Path configPath = Paths.get("./configuration.json"); //The configuration file defaults to "./configuration.json", but can be changed with arguments
		int action = 0;
		boolean actionSet = false;
		final Collection<Integer> articleIDs = new LinkedHashSet<>(), queryIDs = new LinkedHashSet<>();
		for (String arg : args) {
			try {
				if (arg.equalsIgnoreCase("-c")) {
					action = 0;
					actionSet = true;
				}
				else if (arg.equalsIgnoreCase("-a")) {
					action = 1;
					actionSet = true;
				}
				else if (arg.equalsIgnoreCase("-q")) {
					action = 2;
					actionSet = true;
				}
				else if (action == 0)
					configPath = Paths.get(arg);
				else if (action == 1)
					articleIDs.add(Integer.parseInt(arg));
				else if (action == 2)
					queryIDs.add(Integer.parseInt(arg));
			}
			catch (NumberFormatException e) {
				logger.warn(arg + " is not an integer");
			}
			if (!actionSet)
				action++;
			if (action > 2)
				break;
		}
		JSONObject config = (JSONObject) JSONSystem.loadJSON(configPath);
		DBConnection.configureConnection((JSONObject) config.get("database"));
		
		try (Pipeline pipeline = new Pipeline(config, queryIDs, articleIDs, true)) {
			pipeline.execute();
		}
	}
	
	/**
	 * Adds a {@link PipelineComponent} to the {@link Pipeline}
	 * 
	 * @param component
	 *            the {@link PipelineComponent} to add
	 * @return the {@link Pipeline} for chaining purposes
	 */
	public Pipeline addComponent(PipelineComponent component) {
		components.add(component);
		return this;
	}
	
	@Override
	public void execute(Map<Integer, Query> queries, Map<Integer, Article> articles, Collection<ValidationResult> results) throws IOException, SQLException {
		ThreadingUtils.executeTask(() -> {
			for (PipelineComponent pc : components)
				pc.execute(queries, articles, results);
		});
	}
	
	@Override
	public void close() throws IOException {
		if (closed)
			return;
		closed = true;
		articleManager.close();
		IOException except = null;
		for (PipelineComponent comp : components) {
			try {
				if (comp instanceof Closeable)
					((Closeable) comp).close();
			}
			catch (IOException e) {
				except = e;
			}
		}
		if (except != null)
			throw except;
	}
}
