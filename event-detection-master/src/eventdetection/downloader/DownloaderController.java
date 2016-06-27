package eventdetection.downloader;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import toberumono.json.JSONArray;
import toberumono.json.JSONBoolean;
import toberumono.json.JSONData;
import toberumono.json.JSONObject;
import toberumono.json.JSONSystem;

import eventdetection.common.Article;
import eventdetection.common.ArticleManager;
import eventdetection.common.DBConnection;
import eventdetection.common.Query;
import eventdetection.common.ThreadingUtils;
import eventdetection.pipeline.Pipeline;
import eventdetection.pipeline.PipelineComponent;
import eventdetection.validator.ValidationResult;

/**
 * Main class of the downloader. Controls startup and and article management.
 *
 * @author Joshua Lipstone
 */
public class DownloaderController extends DownloaderCollection implements PipelineComponent {
	private final ArticleManager am;
	private boolean closed;

	/**
	 * Constructs a new {@link DownloaderController} with the given configuration data. This is for use with
	 * {@link Pipeline}.
	 *
	 * @param config
	 *            the configuration data
	 * @throws SQLException
	 *             if an error occurs while connecting to the database
	 * @throws IOException
	 *             if an error occurs while loading data from the file system
	 */
	public DownloaderController(JSONObject config) throws SQLException, IOException {
		super();
		updateJSONConfiguration(config);
		Connection connection = DBConnection.getConnection();
		JSONObject paths = (JSONObject) config.get("paths");
		JSONObject articles = (JSONObject) config.get("articles");
		JSONObject tables = (JSONObject) config.get("tables");
		am = new ArticleManager(connection, tables.get("articles").value().toString(), paths, articles);
		Downloader.loadSource(connection, tables.get("sources").value().toString());
		for (JSONData<?> str : ((JSONArray) paths.get("sources")).value())
			Downloader.loadSource(Paths.get(str.toString()));

		FeedManager fm = new FeedManager(connection);
		for (JSONData<?> str : ((JSONArray) paths.get("scrapers")).value())
			fm.addScraper(Paths.get(str.toString()));
		for (JSONData<?> str : ((JSONArray) paths.get("feeds")).value()) //We can load Feeds from both the file system and the database
			fm.addFeed(Paths.get(str.toString()));
		fm.addFeed(connection, tables.get("feeds").value().toString());
		addDownloader(fm);
	}

	/**
	 * The main method.
	 *
	 * @param args
	 *            command line arguments
	 * @throws SQLException
	 *             if an SQL error occurs
	 * @throws IOException
	 *             if an I/O error occurs
	 */
	public static void main(String[] args) throws IOException, SQLException {
		Path configPath = Paths.get(args.length > 0 ? args[0] : "configuration.json");
		JSONObject config = (JSONObject) JSONSystem.loadJSON(configPath);
		if (config.get("test-downloader") != null && ((JSONBoolean) config.get("test-downloader")).value()) {
			return;
		}
		updateJSONConfiguration(config);
		if (config.isModified())
			JSONSystem.writeJSON(config, configPath);
		DBConnection.configureConnection((JSONObject) config.get("database"));
		try (DownloaderController dc = new DownloaderController(config)) {
			dc.execute();
		}
	}

	@Override
	public void execute(Map<Integer, Query> queries, Map<Integer, Article> articles, Collection<ValidationResult> results) throws IOException, SQLException {
		List<Article> downloaded = get();
		ThreadingUtils.executeTask(() -> { //We need to hold the file system lock before we can store Articles
			for (Article article : downloaded) {
				article = am.store(article);
				articles.put(article.getID(), article);
			}
		});
	}

	private static void updateJSONConfiguration(JSONObject config) {
		JSONObject articles = (JSONObject) config.get("articles");
		JSONSystem.transferField("enable-pos-tagging", new JSONBoolean(true), articles, (JSONObject) articles.get("pos-tagging"));
		JSONSystem.transferField("enable-tag-simplification", new JSONBoolean(false), (JSONObject) articles.get("pos-tagging"));
	}

	@Override
	public void close() throws IOException {
		if (closed)
			return;
		closed = true;
		am.close();
		super.close();
	}
}
