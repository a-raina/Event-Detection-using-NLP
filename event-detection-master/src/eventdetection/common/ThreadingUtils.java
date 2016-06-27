package eventdetection.common;

import java.io.IOException;
import java.nio.channels.FileChannel;
import java.nio.channels.FileLock;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.locks.ReentrantLock;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * A simple class that holds threading related constants and methods for the rest of the classes in this project.
 * 
 * @author Joshua Lipstone
 */
public class ThreadingUtils {
	/**
	 * A work stealing pool for use by all classes in this program.
	 */
	public static final ExecutorService pool = Executors.newWorkStealingPool();
	
	private static final Logger logger = LoggerFactory.getLogger("ThreadingUtils");
	private static final ReentrantLock lock = new ReentrantLock();
	private static final Path active = Paths.get(System.getProperty("user.home"), ".event-detection-active");
	private static FileLock fsLock = null;
	private static FileChannel chan = null;
	
	static {
		if (!Files.exists(active))
			try {
				Files.createDirectories(active.getParent());
				Files.createFile(active);
			}
			catch (IOException e) {
				logger.error("Unable to create the file for the filesystem lock", e);
			}
		Runtime.getRuntime().addShutdownHook(new Thread() {
			@Override
			public void run() {
				if (fsLock != null) {
					try {
						fsLock.close();
					}
					catch (IOException e) {
						logger.error("Unable to release the filesystem lock.", e);
					}
					try {
						chan.close();
					}
					catch (IOException e) {
						logger.error("Unable to close the filesystem lock's filechannel.", e);
					}
				}
			}
		});
	}
	
	private ThreadingUtils() {/* This class should not be initialized */}
	
	/**
	 * Provides a means of acquiring a combination intraprocess and interprocess lock.
	 * 
	 * @throws IOException
	 *             if an error occurs while acquiring the interprocess lock
	 */
	public static void acquireLock() throws IOException {
		lock.lock();
		try {
			if (chan != null)
				return;
			chan = FileChannel.open(active, StandardOpenOption.CREATE, StandardOpenOption.WRITE);
			fsLock = chan.lock();
		}
		catch (IOException e) {
			if (fsLock != null)
				fsLock.close();
			if (chan != null)
				chan.close();
			fsLock = null;
			chan = null;
			lock.unlock();
			logger.error("Failed to acquire the interprocess lock.", e);
			throw e;
		}
	}
	
	/**
	 * Provides a means of releasing a combination intraprocess and interprocess lock.
	 * 
	 * @throws IOException
	 *             if an error occurs while releasing the interprocess lock
	 */
	public static void releaseLock() throws IOException {
		if (!lock.isHeldByCurrentThread()) {
			logger.warn("A thread that does not own the filesystem lock attempted to release it.");
			return;
		}
		lock.unlock();
		if (!lock.isHeldByCurrentThread()) { //Reentrancy support
			fsLock.close();
			chan.close();
			fsLock = null;
			chan = null;
		}
	}
	
	/**
	 * Executes the given task synchronously with regard to the locks provided by this class.
	 * 
	 * @param task
	 *            the task to execute
	 * @return the result of executing the task
	 * @throws IOException
	 *             if an error occurs while interacting with the interprocess lock or an IO error occurs within the function
	 * @throws SQLException
	 *             if an SQL error occurs within the function
	 */
	public static <T> T executeTask(IOSQLExceptedSupplier<T> task) throws IOException, SQLException {
		try {
			acquireLock();
			return task.get();
		}
		finally {
			releaseLock();
		}
	}
	
	/**
	 * Executes the given task synchronously with regard to the locks provided by this class.
	 * 
	 * @param task
	 *            the task to execute
	 * @throws IOException
	 *             if an error occurs while interacting with the interprocess lock or an IO error occurs within the function
	 * @throws SQLException
	 *             if an SQL error occurs within the function
	 */
	public static void executeTask(IOSQLExceptedRunnable task) throws IOException, SQLException {
		try {
			acquireLock();
			task.run();
		}
		finally {
			releaseLock();
		}
	}
	
	/**
	 * A thread-safe method for loading {@link Article Articles} from disk.
	 * 
	 * @param articleManager
	 *            the {@link ArticleManager} to use
	 * @param articleIDs
	 *            the IDs of the {@link Article Articles} to load. If this is empty or {@code null}, then every
	 *            {@link Article} in the database is loaded
	 * @return a {@link Map} that maps the {@link Integer} ID of each loaded {@link Article} to the corresponding
	 *         {@link Article}
	 * @throws IOException
	 *             if an error occurs while interacting with the interprocess lock
	 * @throws SQLException
	 *             if an SQL error occurs while reading the {@link Article Article's} metadata from the SQL database
	 */
	public static Map<Integer, Article> loadArticles(ArticleManager articleManager, Collection<Integer> articleIDs) throws IOException, SQLException {
		return loadArticles(articleManager, articleIDs, new LinkedHashMap<>());
	}
	
	/**
	 * A thread-safe method for loading {@link Article Articles} from disk into an existing {@link Map}.<br>
	 * <b>Note:</b> the {@link Map} is modified directly - it is <i>not</i> cloned.
	 * 
	 * @param articleManager
	 *            the {@link ArticleManager} to use
	 * @param articleIDs
	 *            the IDs of the {@link Article Articles} to load. If this is empty or {@code null}, then every
	 *            {@link Article} in the database is loaded
	 * @param articles
	 *            the {@link Map} into which the loaded {@link Article Articles} will be placed. Any IDs that exist in
	 *            {@code articles} will be skipped
	 * @return the {@code articles} {@link Map}
	 * @throws IOException
	 *             if an error occurs while interacting with the interprocess lock
	 * @throws SQLException
	 *             if an SQL error occurs while reading the {@link Article Article's} metadata from the SQL database
	 */
	public static Map<Integer, Article> loadArticles(ArticleManager articleManager, Collection<Integer> articleIDs, Map<Integer, Article> articles) throws IOException, SQLException {
		Collection<Integer> aIDs =
				articleIDs == null ? Collections.emptyList() : (articles.size() == 0 ? articleIDs : articleIDs.stream().filter(id -> !articles.keySet().contains(id)).collect(Collectors.toList()));
		for (Article a : executeTask(() -> articleManager.loadArticles(aIDs)))
			articles.put(a.getID(), a);
		return articles;
	}
	
	/**
	 * A thread-safe method deleting old {@link Article Articles} from disk.<br>
	 * 
	 * @param articleManager
	 *            the {@link ArticleManager} to use
	 * @return the IDs of the deleted articles
	 * @throws IOException
	 *             if an error occurs while interacting with the interprocess lock
	 * @throws SQLException
	 *             if an SQL error occurs while reading the {@link Article Article's} metadata from the SQL database
	 */
	public static Collection<Integer> cleanUpArticles(ArticleManager articleManager) throws IOException, SQLException {
		return executeTask(articleManager::cleanUp);
	}
	
	/**
	 * A thread-safe method for loading {@link Query Queries} from disk.
	 * 
	 * @param queryIDs
	 *            the IDs of the {@link Query Queries} to load. If this is empty or {@code null}, then every {@link Query} in
	 *            the database is loaded
	 * @return a {@link Map} that maps the {@link Integer} ID of each loaded {@link Query} to the corresponding {@link Query}
	 * @throws IOException
	 *             if an error occurs while interacting with the interprocess lock
	 * @throws SQLException
	 *             if an SQL error occurs while reading the {@link Query Queries} from the SQL database
	 */
	public static Map<Integer, Query> loadQueries(Collection<Integer> queryIDs) throws IOException, SQLException {
		return loadQueries(queryIDs, new LinkedHashMap<>());
	}
	
	/**
	 * A thread-safe method for loading {@link Query Queries} from disk into an existing {@link Map}.<br>
	 * <b>Note:</b> the {@link Map} is modified directly - it is <i>not</i> cloned.
	 * 
	 * @param queryIDs
	 *            the IDs of the {@link Query Queries} to load. If this is empty or {@code null}, then every {@link Query} in
	 *            the database is loaded
	 * @param queries
	 *            a {@link Map} into which the loaded {@link Query Queries} will be placed. Any IDs that exist in
	 *            {@code queries} will be skipped
	 * @return the {@code queries} {@link Map}
	 * @throws IOException
	 *             if an error occurs while interacting with the interprocess lock
	 * @throws SQLException
	 *             if an SQL error occurs while reading the {@link Query Queries} from the SQL database
	 */
	public static Map<Integer, Query> loadQueries(Collection<Integer> queryIDs, Map<Integer, Query> queries) throws IOException, SQLException {
		Collection<Integer> qIDs =
				queryIDs == null ? Collections.emptyList() : (queries.size() == 0 ? queryIDs : queryIDs.stream().filter(id -> !queries.keySet().contains(id)).collect(Collectors.toList()));
		executeTask(() -> {
			try (ResultSet rs = DBConnection.getConnection().prepareStatement("select * from queries").executeQuery()) {
				if (qIDs.size() > 0) {
					int id = 0;
					while (qIDs.size() > 0 && rs.next()) {
						id = rs.getInt("id");
						if (qIDs.contains(id)) {
							qIDs.remove(id); //Prevents queries from being loaded more than once
							queries.put(id, new Query(rs));
						}
					}
				}
				else
					while (rs.next())
						queries.put(rs.getInt("id"), new Query(rs));
			}
		});
		if (queryIDs.size() > 0)
			logger.warn("Did not find queries with ids matching " + queryIDs.stream().reduce("", (a, b) -> a + ", " + b.toString(), (a, b) -> a + b).substring(2));
		return queries;
	}
}
