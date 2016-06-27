package eventdetection.common;

import java.io.Closeable;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.attribute.BasicFileAttributes;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collection;
import java.util.Iterator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import toberumono.json.JSONArray;
import toberumono.json.JSONObject;

import static eventdetection.common.ThreadingUtils.pool;

/**
 * A mechanism for managing articles.
 * 
 * @author Joshua Lipstone
 */
public class ArticleManager implements Closeable {
	private static final Logger logger = LoggerFactory.getLogger("ArticleManager");
	
	private final Connection connection;
	private final String table;
	private final Collection<Path> storage;
	private final Instant articleTimeLimit;
	private static final ReadWriteLock fsLock = new ReentrantReadWriteLock();
	private boolean closed;
	
	/**
	 * Initializes an {@link ArticleManager} from JSON configuration data that connects to the database with a new
	 * {@link Connection}.
	 * 
	 * @param config
	 *            the {@link JSONObject} holding the configuration data
	 * @throws SQLException
	 *             if an error occurs while getting the SQL connection
	 */
	public ArticleManager(JSONObject config) throws SQLException {
		this(DBConnection.getConnection(), ((JSONObject) config.get("tables")).get("articles").value().toString(), (JSONObject) config.get("paths"), (JSONObject) config.get("articles"));
	}
	
	/**
	 * Initializes an {@link ArticleManager} from JSON configuration data that connects to the database with the given
	 * {@link Connection}.
	 * 
	 * @param connection
	 *            a {@link Connection} to the database in use
	 * @param config
	 *            the {@link JSONObject} holding the configuration data
	 */
	public ArticleManager(Connection connection, JSONObject config) {
		this(connection, ((JSONObject) config.get("tables")).get("articles").value().toString(), (JSONObject) config.get("paths"), (JSONObject) config.get("articles"));
	}
	
	/**
	 * Initializes an {@link ArticleManager} from JSON configuration data.
	 * 
	 * @param connection
	 *            a {@link Connection} to the database in use
	 * @param articleTable
	 *            the name of the table holding the {@link Article Articles}
	 * @param paths
	 *            the "paths" section of the configuration file
	 * @param articles
	 *            the "articles" section of the configuration file
	 */
	public ArticleManager(Connection connection, String articleTable, JSONObject paths, JSONObject articles) {
		this.connection = connection;
		this.table = articleTable;
		this.storage = ((JSONArray) paths.get("articles")).stream().collect(LinkedHashSet::new, (s, p) -> s.add(Paths.get(p.toString())), LinkedHashSet::addAll);
		this.articleTimeLimit = computeOldest((JSONObject) articles.get("deletion-delay")).toInstant();
	}
	
	private static Calendar computeOldest(JSONObject deletionDelay) {
		Calendar oldest = Calendar.getInstance();
		oldest.add(Calendar.YEAR, -((Number) deletionDelay.get("years").value()).intValue());
		oldest.add(Calendar.MONTH, -((Number) deletionDelay.get("months").value()).intValue());
		oldest.add(Calendar.WEEK_OF_MONTH, -((Number) deletionDelay.get("weeks").value()).intValue());
		oldest.add(Calendar.DAY_OF_MONTH, -((Number) deletionDelay.get("days").value()).intValue());
		oldest.add(Calendar.HOUR_OF_DAY, -((Number) deletionDelay.get("hours").value()).intValue());
		oldest.add(Calendar.MINUTE, -((Number) deletionDelay.get("minutes").value()).intValue());
		oldest.add(Calendar.SECOND, -((Number) deletionDelay.get("seconds").value()).intValue());
		return oldest;
	}
	
	/**
	 * Removes all articles with a file creation date earlier than the oldest allowable time specified in the configuration
	 * file.
	 * 
	 * @return the IDs of the removed articles
	 * @throws SQLException
	 *             if an SQL error occurs
	 * @throws IOException
	 *             if an I/O error occurs
	 * @see #removeArticlesBefore(Instant)
	 */
	public Collection<Integer> cleanUp() throws SQLException, IOException {
		return removeArticlesBefore(articleTimeLimit);
	}
	
	/**
	 * Removes all articles with a file creation date earlier than <tt>oldest</tt>.
	 * 
	 * @param oldest
	 *            a {@link Calendar} containing the oldest date from which {@link Article Articles} should be kept
	 * @return the IDs of the removed articles
	 * @throws SQLException
	 *             if an SQL error occurs
	 * @throws IOException
	 *             if an I/O error occurs
	 */
	public Collection<Integer> removeArticlesBefore(Calendar oldest) throws SQLException, IOException {
		return removeArticlesBefore(oldest.toInstant());
	}
	
	/**
	 * Removes all articles with a file creation date earlier than <tt>oldest</tt>.
	 * 
	 * @param oldest
	 *            an {@link Instant} containing the oldest date from which {@link Article Articles} should be kept
	 * @return the IDs of the removed articles
	 * @throws SQLException
	 *             if an SQL error occurs
	 * @throws IOException
	 *             if an I/O error occurs
	 */
	public Collection<Integer> removeArticlesBefore(Instant oldest) throws SQLException, IOException {
		String statement = "select * from " + table;
		Collection<Integer> removed = new LinkedHashSet<>();
		try (PreparedStatement stmt = connection.prepareStatement(statement)) {
			ResultSet rs = stmt.executeQuery();
			while (rs.next()) { //While the next row is valid
				boolean deleted = false, found = false;
				for (Path store : storage) {
					if (!Files.exists(store))
						continue;
					String filename = rs.getString("filename");
					Path path = store.resolve(filename);
					if (!Files.exists(path))
						continue;
					found = true;
					BasicFileAttributes attrs = Files.readAttributes(path, BasicFileAttributes.class);
					if (attrs.creationTime().toInstant().compareTo(oldest) >= 0)
						continue;
					Files.delete(path);
					
					Path serialized = toSerializedPath(path);
					if (Files.exists(serialized))
						Files.delete(serialized);
					deleted = true;
				}
				if (deleted || !found) {
					try (Statement stm = connection.createStatement()) {
						removed.add(rs.getInt("id"));
						stm.executeUpdate("delete from " + table + " where id = " + rs.getLong("id"));
					}
				}
			}
		}
		return removed;
	}
	
	/**
	 * Stores the given {@link Article} in the first path in the {@link Collection} of storage {@link Path Paths} as defined
	 * by its {@link Iterator}.
	 * 
	 * @param article
	 *            the {@link Article} to store
	 * @return the {@link Path} that points to the file in which the article was stored
	 * @throws SQLException
	 *             if an issue with the SQL server occurs
	 * @throws IOException
	 *             if the storage directory does not exist and cannot be created or the article file cannot be written to
	 *             disk
	 */
	public synchronized Article store(Article article) throws SQLException, IOException {
		synchronized (fsLock.writeLock()) {
			Path storagePath = storage.iterator().next(), serializedPath = storagePath.resolve("serialized");
			if (!Files.exists(serializedPath))
				Files.createDirectories(serializedPath);
			String statement = "insert into " + table + " (title, url, source) values (?, ?, ?)";
			try (PreparedStatement stmt = connection.prepareStatement(statement)) {
				String untaggedTitle = article.getUntaggedTitle();
				stmt.setString(1, untaggedTitle);
				stmt.setString(2, article.getURL().toString());
				stmt.setInt(3, article.getSource().getID());
				stmt.executeUpdate();
				String sql = "select * from " + table + " as arts group by arts.id having arts.id >= all (select a.id from " + table + " as a)";
				try (PreparedStatement ps = connection.prepareStatement(sql)) {
					ResultSet rs = ps.executeQuery();
					if (!rs.next())
						return null;
					String filename = makeFilename(rs.getInt("id"), article.getSource(), untaggedTitle);
					try (PreparedStatement stm = connection.prepareStatement("update " + table + " set filename = ? where id = ?")) {
						stm.setString(1, filename);
						stm.setLong(2, rs.getLong("id"));
						stm.executeUpdate();
					}
					Path filePath = storagePath.resolve(filename), serialPath = serializedPath.resolve(toSerializedName(filename));
					logger.info("Started Processing: " + article.getUntaggedTitle());
					article = article.copyWithID(rs.getInt("id"));
					try {
						StringBuilder fileText = new StringBuilder(article.getTaggedTitle().length() + article.getTaggedText().length() + 14); //14 is the length of the section dividers
						fileText.append("TITLE:\n").append(article.getTaggedTitle()).append("\nTEXT:\n").append(article.getTaggedText());
						Files.write(filePath, fileText.toString().getBytes());
						try (ObjectOutputStream serialOut = new ObjectOutputStream(new FileOutputStream(serialPath.toFile()))) {
							article.process();
							serialOut.writeObject(article);
						}
						catch (Throwable t) {
							throw t;
						}
						try (ObjectInputStream serialIn = new ObjectInputStream(new FileInputStream(serialPath.toFile()))) {
							serialIn.readObject(); //Test to be sure that the serialization worked
						}
						catch (Throwable t) {
							throw new IOException("Serialization failed", t); //If anything goes wrong with reading the Article
						}
					}
					catch (IOException e) {
						try (Statement stm = DBConnection.getConnection().createStatement()) {
							stm.executeUpdate("delete from " + table + " where id = " + rs.getLong("id"));
						}
						if (Files.exists(filePath))
							Files.delete(filePath);
						if (Files.exists(serialPath))
							Files.delete(serialPath);
						throw e;
					}
					logger.info("Finished Processing: " + article.getUntaggedTitle());
					return article;
				}
			}
		}
	}
	
	/**
	 * Loads the {@link Article} with the given {@code id} from disk using the information in the SQL database
	 * 
	 * @param id
	 *            the ID of the {@link Article} to load
	 * @return the {@link Article} if one was found, otherwise null
	 * @throws SQLException
	 * @throws ClassNotFoundException
	 * @throws IOException
	 */
	public Article load(int id) throws SQLException, ClassNotFoundException, IOException {
		synchronized (fsLock.readLock()) {
			try (PreparedStatement stmt = connection.prepareStatement("select * from articles where articles.id = ?")) {
				stmt.setInt(1, id);
				try (ResultSet rs = stmt.executeQuery()) {
					if (!rs.next()) {
						throw new IOException("Unable to locate an article with id = " + id + " in the SQL database.");
					}
					for (Path store : storage) {
						if (!Files.exists(store))
							continue;
						String filename = rs.getString("filename");
						Path serialized = ArticleManager.toSerializedPath(store.resolve(filename));
						if (!Files.exists(serialized))
							continue;
						try (ObjectInputStream serialIn = new ObjectInputStream(new FileInputStream(serialized.toFile()))) {
							Article article = (Article) serialIn.readObject();
							return article;
						}
					}
				}
			}
			throw new IOException("Unable to locate an article with id = " + id + " in the filesystem.");
		}
	}
	
	/**
	 * Loads the {@link Article Articles} with the given {@code ids} from disk using the information in the SQL database.
	 * 
	 * @param ids
	 *            the IDs of the {@link Article} to load as a {@link Collection}
	 * @return the {@link Article} if one was found, otherwise null
	 * @throws SQLException
	 */
	public List<Article> loadArticles(Collection<Integer> ids) throws SQLException {
		synchronized (fsLock.readLock()) {
			List<Article> articles = new ArrayList<>();
			List<Future<Article>> futures = new ArrayList<>();
			try (ResultSet rs = connection.prepareStatement("select * from articles").executeQuery()) {
				logger.info("Starting to deserialize articles");
				if (ids.size() > 0) {
					int id = 0;
					while (ids.size() > 0 && rs.next()) {
						id = rs.getInt("id");
						if (ids.contains(id)) {
							futures.add(pool.submit(loadArticle(rs.getString("title"), rs.getString("filename"))));
							ids.remove(id);
						}
					}
				}
				else {
					while (rs.next())
						futures.add(pool.submit(loadArticle(rs.getString("title"), rs.getString("filename"))));
				}
			}
			Article article = null;
			for (Future<Article> future : futures) {
				try {
					article = future.get();
					if (article != null)
						articles.add(article);
				}
				catch (InterruptedException e) {
					logger.warn("A concurrency error occurred while deserializing articles", e);
				}
				catch (ExecutionException e) {
					logger.warn("An error occurred while deserializing articles", e.getCause());
				}
			}
			logger.info("Done deserializing articles");
			if (ids.size() > 0)
				logger.warn("Did not find articles with ids matching " + ids.stream().reduce("", (a, b) -> a + ", " + b.toString(), (a, b) -> a + b).substring(2));
			return articles;
		}
	}
	
	private Callable<Article> loadArticle(String title, String filename) {
		return () -> {
			Article article = null;
			for (Path store : storage) {
				if (!Files.exists(store))
					continue;
				Path serialized = ArticleManager.toSerializedPath(store.resolve(filename));
				if (!Files.exists(serialized))
					continue;
				try (ObjectInputStream serialIn = new ObjectInputStream(new FileInputStream(serialized.toFile()))) {
					article = (Article) serialIn.readObject();
				}
				catch (ClassNotFoundException | IOException e) {
					logger.debug("Error while deserializing data for " + title, e);
					article = null;
				}
			}
			if (article == null)
				logger.warn("Unable to find the serialized data for " + title + ".  Skipping.");
			return article;
		};
	}
	
	/**
	 * Constructs the file name for an {@link Article}.
	 * 
	 * @param id
	 *            the {@link Article Article's} id in the database
	 * @param source
	 *            the {@link Source} of the {@link Article}
	 * @param title
	 *            the title of the {@link Article}
	 * @return the file name as a {@link String}
	 */
	public static String makeFilename(int id, Source source, String title) {
		return makeFilename(id, source.getID(), title);
	}
	
	/**
	 * Constructs the file name for an {@link Article}.
	 * 
	 * @param id
	 *            the {@link Article Article's} id in the database
	 * @param source
	 *            the id of the {@link Source} of the {@link Article} as a {@link String}
	 * @param title
	 *            the title of the {@link Article}
	 * @return the file name as a {@link String}
	 */
	public static String makeFilename(int id, int source, String title) {
		return id + "_" + source + "_" + title.replaceAll("[:/\\s]", "_") + ".txt";
	}
	
	/**
	 * Converts an {@link Article Article's} filename from the .txt ending to a name ending in .data
	 * 
	 * @param filename
	 *            the filename to convert
	 * @return the converted filename
	 */
	public static String toSerializedName(String filename) {
		return filename.substring(0, filename.length() - 4) + ".data";
	}
	
	/**
	 * Converts the {@link Path} to the saved text of an article to the {@link Path} to the serialized form of the
	 * corresponding {@link Article} object
	 * 
	 * @param textPath
	 *            the {@link Path} to the saved text of an article
	 * @return the {@link Path} to the serialized form of the corresponding {@link Article} object
	 */
	public static Path toSerializedPath(Path textPath) {
		String filename = toSerializedName(textPath.getFileName().toString());
		return textPath.getParent().resolve("serialized").resolve(filename);
	}
	
	/**
	 * @return the {@link Connection}
	 */
	public Connection getConnection() {
		return connection;
	}
	
	/**
	 * @return the name of the SQL table
	 */
	public String getTable() {
		return table;
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
			logger.error("An SQL error occured while closing an ArticleManager's Connection.", e);
		}
	}
}
