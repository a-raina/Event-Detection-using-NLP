package eventdetection.downloader;

import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.net.URL;
import java.nio.file.Path;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;
import java.util.function.Function;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import toberumono.json.JSONArray;
import toberumono.json.JSONData;
import toberumono.json.JSONObject;
import toberumono.json.JSONRepresentable;
import toberumono.json.JSONString;
import toberumono.json.JSONSystem;
import toberumono.structures.tuples.Pair;

import eventdetection.common.IDAble;

/**
 * A mechanism for scraping article text from online sources
 * 
 * @author Joshua Lipstone
 */
public class Scraper implements IDAble<String>, JSONRepresentable {
	private static final Logger logger = LoggerFactory.getLogger("Scraper");
	
	private static final Function<Pair<Pattern, String>, JSONData<?>> filterToJSON = e -> {
		JSONArray arr = new JSONArray();
		arr.add(new JSONString(e.getX().toString()));
		arr.add(new JSONString(e.getY()));
		return arr;
	};
	
	private final List<Pair<Pattern, String>> sectioning;
	private final List<Pair<Pattern, String>> filtering;
	private final String id;
	private final JSONObject json;
	private int hashCode;
	
	/**
	 * Creates a {@link Scraper} using the given configuration data.
	 * 
	 * @param json
	 *            the {@link Path} to the JSON file that describes the {@link Scraper}
	 * @param config
	 *            a {@link JSONObject} containing the configuration data for the {@link Scraper}
	 */
	public Scraper(Path json, JSONObject config) {
		this((String) config.get("id").value(), config.get("sectioning") != null ? jsonArrayToPairs((JSONArray) config.get("sectioning")) : new ArrayList<>(),
				config.get("filtering") != null ? jsonArrayToPairs((JSONArray) config.get("filtering")) : new ArrayList<>(), config);
	}
	
	/**
	 * Creates a {@link Scraper} with the given id and patterns.
	 * 
	 * @param id
	 *            the ID of the {@link Scraper}
	 * @param sectioning
	 *            the pattern/replacement combinations used to extract article text from an article
	 * @param filtering
	 *            the pattern/replacement combinations used to clean the extracted text
	 */
	public Scraper(String id, List<Pair<Pattern, String>> sectioning, List<Pair<Pattern, String>> filtering) {
		this(id, sectioning, filtering, null);
	}
	
	/**
	 * Creates a {@link Scraper} with the given id and patterns.
	 * 
	 * @param id
	 *            the ID of the {@link Scraper}
	 * @param sectioning
	 *            the pattern/replacement combinations used to extract article text from an article
	 * @param filtering
	 *            the pattern/replacement combinations used to clean the extracted text
	 * @param json
	 *            the {@link JSONObject} on which the {@link Scraper} is based
	 */
	public Scraper(String id, List<Pair<Pattern, String>> sectioning, List<Pair<Pattern, String>> filtering, JSONObject json) {
		this.sectioning = sectioning;
		this.id = id;
		this.filtering = filtering;
		if (json == null) {
			json = new JSONObject();
			json.put("id", new JSONString(getID()));
			json.put("sectioning", JSONArray.wrap(sectioning, filterToJSON));
			json.put("filtering", JSONArray.wrap(filtering, filterToJSON));
		}
		this.json = json;
	}
	
	/**
	 * Scrapes the text from the page at the given URL.
	 * 
	 * @param url
	 *            the URL of the page as a {@link String}
	 * @return the scraped text
	 * @throws IOException
	 *             if the text cannot be read from the URL
	 */
	public String scrape(String url) throws IOException {
		return scrape(new URL(url));
	}
	
	/**
	 * Scrapes the text from the page at the given {@link URL}.
	 * 
	 * @param url
	 *            the {@link URL} of the page
	 * @return the scraped text
	 * @throws IOException
	 *             if the text cannot be read from the {@link URL}
	 */
	public String scrape(URL url) throws IOException {
		try (InputStream is = url.openStream()) {
			return scrape(is);
		}
	}
	
	/**
	 * Scrapes the text in the given {@link InputStream}.
	 * 
	 * @param is
	 *            the {@link InputStream} containing the text to scrape
	 * @return the scraped text
	 */
	public String scrape(InputStream is) {
		//This disables the delimiter and then uses the scanner to convert the stream from the URL into text
		try (Scanner s = new Scanner(is); Scanner sc = s.useDelimiter("\\A")) {
			return scrape(sc);
		}
	}
	
	/**
	 * Scrapes the text in the given {@link Scanner}.
	 * 
	 * @param sc
	 *            the {@link Scanner} containing the text to scrape
	 * @return the scraped text
	 */
	public String scrape(Scanner sc) {
		StringBuilder sb = new StringBuilder();
		while (sc.hasNext())
			sb.append(sc.next());
		String separated = separate(sb.toString(), sectioning);
		if (separated == null || (separated = separated.trim()).length() < 1) //We don't want Strings of length 0
			return null;
		String filtered = filter(separated, filtering);
		if (filtered == null || filtered.length() < 1) //We don't want Strings of length 0
			return null;
		return filtered;
	}
	
	/**
	 * Extracts the text that composes an article from the given page using the rules stored in the {@link Scraper}.
	 * 
	 * @param page
	 *            the page from which to extract the text as a {@link String}
	 * @return the extracted text
	 */
	public String separate(String page) {
		return separate(page, sectioning);
	}
	
	/**
	 * Extracts the text that composes an article from the given page.
	 * 
	 * @param page
	 *            the page from which to extract the text as a {@link String}
	 * @param rules
	 *            the rules to use to extract the text
	 * @return the extracted text
	 */
	public String separate(String page, List<Pair<Pattern, String>> rules) {
		StringBuffer sb = new StringBuffer();
		boolean didFind = false;
		for (Pair<Pattern, String> rule : rules) {
			int offset = 0, lastEnd = 0;
			boolean found = false;
			Matcher m = rule.getX().matcher(page);
			//There is no easy way to "replace" parts of a String into a StringBuffer
			while (m.find()) { //this is the simplest way I could find
				found = true;
				m.appendReplacement(sb, rule.getY());
				sb.delete(offset, offset + m.start() - lastEnd);
				offset = sb.length();
				lastEnd = m.end();
			}
			if (found) {
				didFind = true;
				page = sb.toString();
			}
			sb.delete(0, sb.length()); //Clear the buffer
		}
		if (!didFind)
			return null;
		return page.trim();
	}
	
	/**
	 * Filters already scraped text using the rules stored in the {@link Scraper}.
	 * 
	 * @param text
	 *            the text to filter
	 * @return the filtered text
	 */
	public String filter(String text) {
		return filter(text, filtering);
	}
	
	/**
	 * Filters already scraped text.
	 * 
	 * @param text
	 *            the text to filter
	 * @param rules
	 *            the rules to use to filter the text
	 * @return the filtered text
	 */
	public String filter(String text, List<Pair<Pattern, String>> rules) {
		for (Pair<Pattern, String> rule : rules)
			text = rule.getX().matcher(text).replaceAll(rule.getY());
		return text;
	}
	
	/**
	 * @return the ID of the {@link Scraper}
	 */
	@Override
	public String getID() {
		return id;
	}
	
	@Override
	public JSONObject toJSONObject() {
		return json;
	}
	
	@Override
	public boolean equals(Object o) {
		if (!(o instanceof Scraper))
			return false;
		Scraper s = (Scraper) o;
		return getID().equals(s.getID()) && sectioning.equals(s.sectioning) && filtering.equals(s.filtering);
	}
	
	@Override
	public int hashCode() {
		if (hashCode == 0) {
			hashCode = 17;
			hashCode = hashCode * 31 + getID().hashCode();
			hashCode = hashCode * 31 + sectioning.hashCode();
			hashCode = hashCode * 31 + filtering.hashCode();
		}
		return hashCode;
	}
	
	/**
	 * Loads a {@link Feed} from SQL data.
	 * 
	 * @param rs
	 *            the {@link ResultSet} thats currently select row should be used to generate the {@link Feed}
	 * @return the {@link Feed} described in the current row in the SQL table
	 * @throws SQLException
	 *             an SQL error occurs
	 */
	public static Scraper loadFromSQL(ResultSet rs) throws SQLException {
		return new Scraper(rs.getString("id"), jsonArrayToPairs(rs.getString("sectioning")), jsonArrayToPairs(rs.getString("filtering")));
	}
	
	private static final List<Pair<Pattern, String>> jsonArrayToPairs(String json) {
		return jsonArrayToPairs((JSONArray) JSONSystem.parseJSON(json));
	}
	
	private static final List<Pair<Pattern, String>> jsonArrayToPairs(JSONArray array) {
		List<Pair<Pattern, String>> pairs = new ArrayList<>();
		for (JSONData<?> s : array) {
			JSONArray a = (JSONArray) s;
			pairs.add(new Pair<>(Pattern.compile(a.get(0).toString()), a.get(1).toString()));
		}
		return pairs;
	}
	
	/**
	 * Loads a {@link Scraper} from a JSON file
	 * 
	 * @param json
	 *            a {@link Path} to the JSON file
	 * @param classloader
	 *            a {@link ClassLoader} for the directory in which the JSON file was contained
	 * @return the {@link Scraper} described in the JSON file
	 * @throws IOException
	 *             an I/O error occurs
	 */
	public static Scraper loadFromJSON(Path json, ClassLoader classloader) throws IOException {
		JSONObject config = (JSONObject) JSONSystem.loadJSON(json);
		JSONSystem.transferField("class", new JSONString(Scraper.class.getName()), config);
		try {
			Constructor<?> constructor = classloader.loadClass((String) config.get("class").value()).getConstructor(Path.class, JSONObject.class);
			constructor.setAccessible(true);
			return (Scraper) constructor.newInstance(json, config);
		}
		catch (InstantiationException | IllegalAccessException | IllegalArgumentException | InvocationTargetException | NoSuchMethodException | ClassNotFoundException e) {
			logger.error("Unable to initialize the Scraper defined in " + json.toString(), e);
			return new Scraper(json, config);
		}
	}
}
