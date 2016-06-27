package eventdetection.downloader;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.rometools.rome.feed.synd.SyndEntry;
import com.rometools.rome.feed.synd.SyndFeed;
import com.rometools.rome.io.FeedException;
import com.rometools.rome.io.SyndFeedInput;
import com.rometools.rome.io.XmlReader;

import toberumono.json.JSONArray;
import toberumono.json.JSONNumber;
import toberumono.json.JSONObject;
import toberumono.json.JSONRepresentable;
import toberumono.json.JSONString;
import toberumono.json.JSONSystem;

import eventdetection.common.Article;
import eventdetection.common.DBConnection;
import eventdetection.common.IDAble;
import eventdetection.common.Source;

import static eventdetection.common.ThreadingUtils.pool;

/**
 * Represents an RSS feed and provides methods for getting the articles from it.
 * 
 * @author Joshua Lipstone
 */
public class Feed extends Downloader implements IDAble<Integer>, JSONRepresentable {
	private static final SyndFeedInput input = new SyndFeedInput();
	private static final Logger logger = LoggerFactory.getLogger("Feed");
	
	private final int id;
	private final String name;
	private final List<String> scraperIDs;
	private String lastSeen;
	private final Source source;
	private final URL url;
	private final Map<String, Scraper> scrapers;
	private final JSONObject json;
	private final Path file;
	private final Connection connection;
	private boolean closed;
	private boolean writeSQL;
	
	/**
	 * Initializes a {@link Feed}
	 * 
	 * @param id
	 *            the ID of the {@link Feed}
	 * @param name
	 *            the name of the {@link Feed}
	 * @param source
	 *            the {@link Source} of the {@link Feed}
	 * @param lastSeen
	 *            the url of the last-seen article
	 * @param scraperIDs
	 *            the IDs of the {@link Scraper Scrapers} that the {@link Feed} can use
	 * @param url
	 *            the specific {@link URL} of the {@link Feed}
	 * @param scrapers
	 *            the {@link Scraper Scrapers} available to the {@link Feed}
	 * @throws SQLException
	 *             if an error occurs while getting the {@link Connection}
	 */
	public Feed(int id, String name, Source source, List<String> scraperIDs, String lastSeen, URL url, Map<String, Scraper> scrapers) throws SQLException {
		this(id, name, source, scraperIDs, lastSeen, url, scrapers, null, null, DBConnection.getConnection());
	}
	
	/**
	 * Initializes a {@link Feed}
	 * 
	 * @param id
	 *            the ID of the {@link Feed}
	 * @param name
	 *            the name of the {@link Feed}
	 * @param source
	 *            the {@link Source} of the {@link Feed}
	 * @param lastSeen
	 *            the url of the last-seen article
	 * @param scraperIDs
	 *            the IDs of the {@link Scraper Scrapers} that the {@link Feed} can use
	 * @param url
	 *            the specific {@link URL} of the {@link Feed}
	 * @param scrapers
	 *            the {@link Scraper Scrapers} available to the {@link Feed}
	 * @param json
	 *            the {@link JSONObject} on which the {@link Feed} is based
	 * @param file
	 *            the {@link Path} to the file from which the {@link Feed} was loaded
	 * @param connection
	 *            a {@link Connection} to the database to use
	 */
	public Feed(int id, String name, Source source, List<String> scraperIDs, String lastSeen, URL url, Map<String, Scraper> scrapers, JSONObject json, Path file, Connection connection) {
		this.id = id;
		this.name = name;
		this.source = source;
		this.url = url;
		this.lastSeen = lastSeen;
		this.scraperIDs = scraperIDs;
		this.scrapers = scrapers;
		this.connection = connection;
		if (json == null) {
			json = new JSONObject();
			json.put("id", new JSONNumber<>(getID()));
			json.put("name", new JSONString(getName()));
			json.put("source", new JSONNumber<>(source.getID()));
			json.put("url", new JSONString(getURL().toString()));
			json.put("scraperIDs", JSONArray.wrap(scraperIDs));
			json.put("lastSeen", new JSONString(lastSeen));
		}
		this.json = json;
		this.file = file;
		closed = false;
	}
	
	@Override
	public synchronized List<Article> get() {
		List<Article> out = new ArrayList<>();
		Scraper s = getScraper();
		if (s == null)
			return out;
		List<SyndEntry> entries = new ArrayList<>();
		SyndFeed feed = null;
		try (Connection connection = DBConnection.getConnection(); PreparedStatement stmt = connection.prepareStatement("select * from articles where articles.url = ?")) {
			feed = input.build(new XmlReader(url));
			for (SyndEntry e : feed.getEntries()) {
				stmt.setString(1, e.getLink());
				try {
					if (stmt.executeQuery().next())
						continue;
				}
				catch (SQLException ex) {
					continue;
				}
				entries.add(e);
			}
		}
		catch (SQLException | IllegalArgumentException | FeedException | IOException e) {
			e.printStackTrace();
		}
		finally {
			if (feed != null)
				lastSeen = feed.getEntries().get(0).getLink();
		}
		List<Future<Article>> futures = new ArrayList<>();
		for (SyndEntry entry : entries) {
			futures.add(pool.submit(() -> {
				String text = s.scrape(new URL(entry.getLink()));
				if (text == null || (text = text.trim()).length() < 1)
					return null;
				return new Article(entry.getTitle(), text, entry.getLink(), getSource());
			}));
		}
		for (Future<Article> future : futures)
			try {
				Article article = future.get();
				if (article != null)
					out.add(article);
			}
			catch (InterruptedException e) {
				e.printStackTrace();
			}
			catch (ExecutionException e) {
				e.getCause().printStackTrace();
			}
		return out;
	}
	
	@Override
	public Integer getID() {
		return id;
	}
	
	/**
	 * @return the name
	 */
	public String getName() {
		return name;
	}
	
	/**
	 * @return the name of the last-seen article. Downloading proceeds from the article immediately after this one
	 */
	public String getLastSeen() {
		return lastSeen;
	}
	
	/**
	 * This is to account for news sites such as NYT and CNN having multiple feeds.
	 * 
	 * @return the {@link Source} that this {@link Feed} is from
	 */
	public Source getSource() {
		return source;
	}
	
	/**
	 * @return the {@link URL} of the {@link Feed}
	 */
	public URL getURL() {
		return url;
	}
	
	/**
	 * @return the {@link Scraper} to use or {@code null} if one is not found
	 */
	private Scraper getScraper() {
		Scraper out = null;
		for (String id : scraperIDs)
			if ((out = scrapers.get(id)) != null)
				return out;
		return out;
	}
	
	@Override
	public int hashCode() {
		return (getName() + getID()).hashCode();
	}
	
	@Override
	public boolean equals(Object o) {
		if (o == null || !(o instanceof Feed))
			return false;
		Feed f = (Feed) o;
		return getID() == f.getID() && getName().equals(f.getName());
	}
	
	/**
	 * Loads a {@link Feed} from a JSON file.
	 * 
	 * @param file
	 *            a {@link Path} to the JSON file
	 * @param scrapers
	 *            the available {@link Scraper Scrapers}
	 * @param connection
	 *            a {@link Connection} to the database to use
	 * @return the {@link Feed} described in the JSON file
	 * @throws IOException
	 *             an I/O error occurs
	 */
	@SuppressWarnings("unchecked")
	public static Feed loadFromJSON(Path file, Map<String, Scraper> scrapers, Connection connection) throws IOException {
		JSONObject json = (JSONObject) JSONSystem.loadJSON(file);
		List<String> scraperIDs = new ArrayList<>();
		for (JSONString s : (List<JSONString>) json.get("scraperIDs").value())
			scraperIDs.add(s.value());
		URL url = new URL((String) json.get("url").value());
		Source source = Downloader.sources.get(json.get("source"));
		String lastSeen = json.containsKey("lastSeen") ? (String) json.get("lastSeen").value() : null;
		return new Feed(-1, (String) json.get("name").value(), source, scraperIDs, lastSeen, url, scrapers, json, file, connection);
	}
	
	/**
	 * Loads a {@link Feed} from SQL data.
	 * 
	 * @param connection
	 *            a {@link Connection} to the database to use
	 * @param rs
	 *            the {@link ResultSet} thats currently select row should be used to generate the {@link Feed}
	 * @param scrapers
	 *            the available {@link Scraper Scrapers}
	 * @return the {@link Feed} described in the current row in the SQL table
	 * @throws SQLException
	 *             an SQL error occurs
	 * @throws MalformedURLException
	 *             an I/O error occurs
	 */
	public static Feed loadFromSQL(Connection connection, ResultSet rs, Map<String, Scraper> scrapers) throws SQLException, MalformedURLException {
		List<String> scraperIDs = new ArrayList<>();
		for (String s : (String[]) rs.getArray("scrapers").getArray())
			scraperIDs.add(s);
		Feed out = new Feed(rs.getInt("id"), rs.getString("feed_name"), Downloader.sources.get(rs.getInt("source")), scraperIDs, rs.getString("lastseen"), new URL(rs.getString("url")), scrapers);
		out.writeSQL = true;
		return out;
	}
	
	@Override
	public JSONObject toJSONObject() {
		return json;
	}
	
	@Override
	public void close() throws IOException {
		if (closed)
			return;
		closed = true;
		if (writeSQL) {
			try {
				PreparedStatement ps = connection.prepareStatement("update feeds set lastseen = ? where id = ?");
				ps.setString(1, getLastSeen());
				ps.setInt(2, getID());
				ps.executeUpdate();
			}
			catch (SQLException e) {
				logger.error("An SQL error occured while writing a Feed's data to the database.", e);
			}
		}
		if (lastSeen != null)
			json.put("lastSeen", new JSONString(getLastSeen()));
		if (file != null)
			JSONSystem.writeJSON(toJSONObject(), file);
		try {
			connection.close();
		}
		catch (SQLException e) {
			logger.error("An SQL error occured while closing a Feed's Connection.", e);
		}
	}
}
