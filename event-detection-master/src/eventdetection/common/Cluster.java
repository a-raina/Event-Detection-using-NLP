package eventdetection.common;

import java.io.IOException;
import java.nio.file.Paths;
import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.function.Function;

import toberumono.json.JSONArray;
import toberumono.json.JSONData;
import toberumono.json.JSONNumber;
import toberumono.json.JSONObject;
import toberumono.json.JSONString;
import toberumono.json.JSONSystem;

/**
 * Represents a cluster of related {@link Article Articles}
 * 
 * @author Joshua Lipstone
 */
public class Cluster {
	private final Collection<Article> articles, unmodifiableArticles;
	private final Collection<String> keywords, unmodifiableKeywords;
	private final int hashCode;
	
	/**
	 * Creates a new {@link Cluster} with the given article IDs and keywords and uses the provided {@link Map} to convert the
	 * article IDs into {@link Article Articles}
	 * 
	 * @param articleIDs
	 *            the IDs of the {@link Cluster Cluster's} {@link Article Articles} as {@link Integer Integers}
	 * @param keywords
	 *            the {@link Cluster Cluster's} keywords as {@link String Strings}
	 * @param loadedArticles
	 *            a {@link Map} that maps article IDs to {@link Article Articles}
	 */
	public Cluster(JSONArray articleIDs, JSONArray keywords, Map<Integer, Article> loadedArticles) {
		this(articleIDs, keywords, loadedArticles::get);
	}
	
	/**
	 * Creates a new {@link Cluster} with the given article IDs and keywords and uses the provided {@link Function} to
	 * convert the article IDs into {@link Article Articles}
	 * 
	 * @param articleIDs
	 *            the IDs of the {@link Cluster Cluster's} {@link Article Articles} as {@link Integer Integers}
	 * @param keywords
	 *            the {@link Cluster Cluster's} keywords as {@link String Strings}
	 * @param articleLoader
	 *            a {@link Function} that maps article IDs to {@link Article Articles}
	 */
	public Cluster(JSONArray articleIDs, JSONArray keywords, Function<Integer, Article> articleLoader) {
		this.articles = new LinkedHashSet<>();
		this.unmodifiableArticles = Collections.unmodifiableCollection(this.articles);
		this.keywords = new LinkedHashSet<>();
		this.unmodifiableKeywords = Collections.unmodifiableCollection(this.keywords);
		loader(articleIDs, keywords, articleLoader);
		int hash = 17;
		hash += 31 * hash + this.articles.hashCode();
		hash += 31 * hash + this.keywords.hashCode();
		hashCode = hash;
	}
	
	@SuppressWarnings("unchecked")
	private void loader(JSONArray articles, JSONArray keywords, Function<Integer, Article> loader) {
		for (JSONData<?> data : articles)
			this.articles.add(loader.apply(((JSONNumber<Number>) data).value().intValue()));
		for (JSONData<?> data : keywords)
			this.keywords.add(((JSONString) data).value());
	}
	
	/**
	 * @return an <i>unmodifiable</i> view of the {@link Article Articles} in the {@link Cluster}
	 */
	public Collection<Article> getArticles() {
		return unmodifiableArticles;
	}
	
	/**
	 * @return an <i>unmodifiable</i> view of the keywords in the {@link Cluster}
	 */
	public Collection<String> getKeywords() {
		return unmodifiableKeywords;
	}
	
	/**
	 * NOTE: This method just forwards to the clustering algorithm that Laura, Josie, and Julia wrote and wraps the result
	 * for use with Java programs. All credit for the clustering algorithm goes to them.
	 * 
	 * @param articleLoader
	 *            a {@link Function} that gets the {@link Article} that matches the provided id.
	 * @param articles
	 *            a list of article IDs to use in the clustering algorithm as a comma- or space-separated {@link String}
	 * @return a {@link Collection} of {@link Cluster Clusters}
	 * @throws IOException
	 *             if an error occurs while executing the subprocess or reading its output
	 */
	public static Collection<Cluster> loadClusters(Function<Integer, Article> articleLoader, String articles) throws IOException {
		return loadClusters(articleLoader, articles.split("(,\\s*|\\s+)"));
	}
	
	/**
	 * NOTE: This method just forwards to the clustering algorithm that Laura, Josie, and Julia wrote and wraps the result
	 * for use with Java programs. All credit for the clustering algorithm goes to them.
	 * 
	 * @param articleLoader
	 *            a {@link Function} that gets the {@link Article} that matches the provided id.
	 * @param articles
	 *            a list of article IDs to use in the clustering algorithm as {@link String Strings}
	 * @return a {@link Collection} of {@link Cluster Clusters}
	 * @throws IOException
	 *             if an error occurs while executing the subprocess or reading its output
	 */
	public static Collection<Cluster> loadClusters(Function<Integer, Article> articleLoader, String... articles) throws IOException {
		Process p = SubprocessHelpers.executePythonProcess(Paths.get("./Clustering/Cluster.py"), articles);
		Collection<Cluster> out = new LinkedHashSet<>();
		try {
			p.waitFor();
			JSONArray clusters = (JSONArray) JSONSystem.readJSON(p.getInputStream());
			for (JSONData<?> data : clusters)
				out.add(new Cluster((JSONArray) ((JSONObject) data).get("articles"), (JSONArray) ((JSONObject) data).get("keywords"), articleLoader));
		}
		catch (InterruptedException e) {
			e.printStackTrace();
		}
		return out;
	}
	
	@Override
	public boolean equals(Object obj) {
		if (!(obj instanceof Cluster))
			return false;
		Cluster o = (Cluster) obj;
		return articles.equals(o.articles) && keywords.equals(o.keywords);
	}
	
	@Override
	public int hashCode() {
		return hashCode;
	}
}
