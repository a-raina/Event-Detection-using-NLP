package eventdetection.textrank;

import java.io.BufferedWriter;
import java.io.Flushable;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStreamWriter;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Scanner;
import java.util.Set;
import java.util.function.Function;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import toberumono.json.JSONArray;
import toberumono.json.JSONNumber;
import toberumono.json.JSONObject;
import toberumono.json.JSONString;
import toberumono.json.JSONSystem;
import toberumono.json.exceptions.JSONException;
import toberumono.structures.tuples.Pair;

import edu.stanford.nlp.ling.CoreAnnotations.SentencesAnnotation;
import edu.stanford.nlp.pipeline.Annotation;
import edu.stanford.nlp.util.CoreMap;
import eventdetection.common.Article;
import eventdetection.common.ArticleManager;
import eventdetection.common.DBConnection;
import eventdetection.common.POSTagger;
import eventdetection.common.Source;

/**
 * A static class that implements the TextRank algorithm for sentences
 * 
 * @author Joshua Lipstone
 */
public class TextRank {
	static final Logger logger = LoggerFactory.getLogger("TextRank");
	private static final Integer DEFAULT_ITERATIONS = 100;
	private static final Double DEFAULT_THRESHOLD = 0.0001, DEFAULT_DAMPING_FACTOR = 0.8;
	
	/**
	 * Command line interface for this TextRank algorithm. This is designed to be used as part of a subprocess system. As
	 * such, article IDs are passed in via stdin.
	 * 
	 * @param args
	 *            command line arguments
	 * @throws IOException
	 *             if an I/O error occurs
	 * @throws SQLException
	 *             if an SQL error occurs
	 */
	public static void main(String[] args) throws IOException, SQLException {
		int setting = 0;
		Path configurationFile = Paths.get("./configuration.json");
		JSONObject config = (JSONObject) JSONSystem.loadJSON(configurationFile);
		boolean switched = false;
		InputType inputType = InputType.ID;
		OutputType outputType = OutputType.JSON;
		int iterations = 100;
		double threshold = 0.0001, dampingFactor = 0.8;
		boolean pos = true, sorting = true;
		for (String arg : args) {
			switch (arg) {
				case "-c":
				case "--config":
				case "--configuration":
					setting = 0;
					switched = true;
					break;
				case "-i":
				case "--input":
					setting = 1;
					switched = true;
					break;
				case "-o":
				case "--output":
					setting = 2;
					switched = true;
					break;
				case "--iterations":
					setting = 3;
					switched = true;
					break;
				case "-t":
				case "--threshold":
					setting = 4;
					switched = true;
					break;
				case "-d":
				case "--damping":
				case "--damping-factor":
					setting = 5;
					switched = true;
					break;
				case "--enable-pos":
					pos = true;
					break;
				case "--disable-pos":
					pos = false;
					break;
				case "--pos":
					setting = 6;
					switched = true;
					break;
				case "--enable-sorting":
					sorting = true;
					break;
				case "--disable-sorting":
					sorting = false;
					break;
				case "--sorting":
					setting = 7;
					switched = true;
					break;
				default:
					if (setting == 0) {
						Path temp = Paths.get(arg);
						if (!Files.exists(temp))
							logger.warn(arg + " does not exist.  Using " + configurationFile.toString() + " instead.");
						try {
							config = (JSONObject) JSONSystem.loadJSON(temp);
							configurationFile = temp;
						}
						catch (JSONException | IOException e) {
							logger.warn(arg + " is not a valid JSON file.  Using " + configurationFile.toString() + " instead.");
						}
					}
					else if (setting == 1) {
						try {
							inputType = InputType.valueOf(arg.toUpperCase());
						}
						catch (IllegalArgumentException e) {
							logger.warn(arg + " is not a valid input type.  Using " + inputType.name() + " instead.");
						}
					}
					else if (setting == 2) {
						try {
							outputType = OutputType.valueOf(arg.toUpperCase());
						}
						catch (IllegalArgumentException e) {
							logger.warn(arg + " is not a valid output type.  Using " + outputType.name() + " instead.");
						}
					}
					else if (setting == 3) {
						try {
							iterations = Integer.parseInt(arg);
						}
						catch (NumberFormatException e) {
							logger.warn(arg + " is not a valid integer.  Using " + iterations + " instead.");
						}
					}
					else if (setting == 4) {
						try {
							threshold = Double.parseDouble(arg);
						}
						catch (NumberFormatException e) {
							logger.warn(arg + " is not a valid decimal number.  Using " + threshold + " instead.");
						}
					}
					else if (setting == 5) {
						try {
							dampingFactor = Double.parseDouble(arg);
						}
						catch (NumberFormatException e) {
							logger.warn(arg + " is not a valid decimal number.  Using " + dampingFactor + " instead.");
						}
					}
					else if (setting == 6) {
						try {
							pos = Boolean.parseBoolean(arg);
						}
						catch (NumberFormatException e) {
							logger.warn(arg + " is not a valid boolean value.  Using " + pos + " instead.");
						}
					}
					else if (setting == 7) {
						try {
							sorting = Boolean.parseBoolean(arg);
						}
						catch (NumberFormatException e) {
							logger.warn(arg + " is not a valid boolean value.  Using " + sorting + " instead.");
						}
					}
					if (!switched)
						setting++;
			}
		}
		DBConnection.configureConnection((JSONObject) config.get("database"));
		ArticleManager am = new ArticleManager(DBConnection.getConnection(), ((JSONObject) config.get("tables")).get("articles").value().toString(), (JSONObject) config.get("paths"),
				(JSONObject) config.get("articles"));
				
		Collection<Article> articles = inputType.getArticles(System.in, am);
		Map<Article, List<Pair<CoreMap, Double>>> ranked = new LinkedHashMap<>();
		final int iters = iterations;
		final double thresh = threshold, damping = dampingFactor;
		Function<List<CoreMap>, List<Pair<CoreMap, Double>>> ranker =
				sorting ? sentences -> TextRank.getSortedRankedSentences(sentences, iters, thresh, damping) : sentences -> TextRank.getRankedSentences(sentences, iters, thresh, damping);
		for (Article article : articles) {
			List<CoreMap> sentences = new ArrayList<>();
			for (Annotation paragraph : article.getAnnotatedText())
				sentences.addAll(paragraph.get(SentencesAnnotation.class));
			ranked.put(article, ranker.apply(sentences));
		}
		outputType.printOutput(new BufferedWriter(new OutputStreamWriter(System.out)), ranked, pos);
	}
	
	private static TextRankGraph<CoreMap> generateGraph(Annotation... document) {
		return generateGraph(DEFAULT_ITERATIONS, DEFAULT_THRESHOLD, DEFAULT_DAMPING_FACTOR, document);
	}
	
	private static TextRankGraph<CoreMap> generateGraph(int iterations, double threshold, double dampingFactor, Annotation... document) {
		List<CoreMap> sentences = new ArrayList<>();
		for (Annotation doc : document) {
			sentences.addAll(doc.get(SentencesAnnotation.class));
		}
		return generateGraph(iterations, threshold, dampingFactor, sentences);
	}
	
	private static TextRankGraph<CoreMap> generateGraph(List<CoreMap> sentences) {
		return generateGraph(DEFAULT_ITERATIONS, DEFAULT_THRESHOLD, DEFAULT_DAMPING_FACTOR, sentences);
	}
	
	private static TextRankGraph<CoreMap> generateGraph(int iterations, double threshold, double dampingFactor, List<CoreMap> sentences) {
		TextRankGraph<CoreMap> g = new TextRankGraph<>(sentences.size(), iterations, threshold, dampingFactor);
		for (CoreMap sentence : sentences)
			g.addNode(new TextRankNode<>(1.0, sentence));
		String[][] words = new String[sentences.size()][0];
		double sim = 0;
		for (int i = 0; i < sentences.size(); i++) {
			if (words[i].length == 0)
				words[i] = getWords(sentences.get(i));
			for (int j = i + 1; j < sentences.size(); j++) {
				if (words[j].length == 0)
					words[j] = getWords(sentences.get(j));
				sim = similarity(words[i], words[j]);
				g.addEdge(i, sim, j);
				g.addEdge(j, sim, i);
			}
		}
		return g;
	}
	
	private static String[] getWords(CoreMap sentence) {
		Set<String> out = new LinkedHashSet<>();
		for (String word : POSTagger.reconstructSentence(sentence).split("([\\Q.,\";:?!\\E]\\s*|\\s+)"))
			out.add(word);
		return out.toArray(new String[out.size()]);
	}
	
	private static double similarity(String[] s1, String[] s2) {
		double overlap = 0;
		for (int i = 0; i < s1.length; i++)
			for (int j = 0; j < s2.length; j++)
				if (s1[i].equals(s2[j])) {
					overlap++;
					break;
				}
		return overlap / (Math.log(s1.length) + Math.log(s2.length) + 1);
	}
	
	/**
	 * This method runs the TextRank algorithm before returning
	 * 
	 * @param document
	 *            a container holding the text to be ranked
	 * @return a {@link Stream} containing {@link Pair Pairs} of objects and their ranks
	 */
	public static Stream<Pair<CoreMap, Double>> getRankedSentencesStream(Annotation... document) {
		return generateGraph(document).getRankedObjectsStream();
	}
	
	/**
	 * This method runs the TextRank algorithm before returning
	 * 
	 * @param document
	 *            a container holding the text to be ranked
	 * @return a {@link Stream} containing {@link Pair Pairs} of objects and their ranks sorted in <i>descending</i> order
	 */
	public static Stream<Pair<CoreMap, Double>> getSortedRankedSentencesStream(Annotation... document) {
		return generateGraph(document).getSortedRankedObjectsStream();
	}
	
	/**
	 * This method runs the TextRank algorithm before returning
	 * 
	 * @param document
	 *            a container holding the text to be ranked
	 * @return a {@link List} of {@link Pair Pairs} of values and their ranks from the graph
	 */
	public static List<Pair<CoreMap, Double>> getRankedSentences(Annotation... document) {
		return getRankedSentencesStream(document).collect(Collectors.toList());
	}
	
	/**
	 * This method runs the TextRank algorithm before returning
	 * 
	 * @param document
	 *            a container holding the text to be ranked
	 * @return a {@link List} of ranked objects sorted in <i>descending</i> order
	 */
	public static List<Pair<CoreMap, Double>> getSortedRankedSentences(Annotation... document) {
		return getSortedRankedSentencesStream(document).collect(Collectors.toList());
	}
	
	/**
	 * This method runs the TextRank algorithm before returning
	 * 
	 * @param sentences
	 *            a {@link List} holding the {@link CoreMap CoreMaps} representing the sentences to be ranked
	 * @return a {@link Stream} containing {@link Pair Pairs} of objects and their ranks
	 */
	public static Stream<Pair<CoreMap, Double>> getRankedSentencesStream(List<CoreMap> sentences) {
		return generateGraph(sentences).getRankedObjectsStream();
	}
	
	/**
	 * This method runs the TextRank algorithm before returning
	 * 
	 * @param sentences
	 *            a {@link List} holding the {@link CoreMap CoreMaps} representing the sentences to be ranked
	 * @return a {@link Stream} containing {@link Pair Pairs} of objects and their ranks sorted in <i>descending</i> order
	 */
	public static Stream<Pair<CoreMap, Double>> getSortedRankedSentencesStream(List<CoreMap> sentences) {
		return generateGraph(sentences).getSortedRankedObjectsStream();
	}
	
	/**
	 * This method runs the TextRank algorithm before returning
	 * 
	 * @param sentences
	 *            a {@link List} holding the {@link CoreMap CoreMaps} representing the sentences to be ranked
	 * @return a {@link List} of {@link Pair Pairs} of values and their ranks from the graph
	 */
	public static List<Pair<CoreMap, Double>> getRankedSentences(List<CoreMap> sentences) {
		return getRankedSentencesStream(sentences).collect(Collectors.toList());
	}
	
	/**
	 * This method runs the TextRank algorithm before returning
	 * 
	 * @param sentences
	 *            a {@link List} holding the {@link CoreMap CoreMaps} representing the sentences to be ranked
	 * @return a {@link List} of ranked objects sorted in <i>descending</i> order
	 */
	public static List<Pair<CoreMap, Double>> getSortedRankedSentences(List<CoreMap> sentences) {
		return getSortedRankedSentencesStream(sentences).collect(Collectors.toList());
	}
	
	/**
	 * This method runs the TextRank algorithm before returning
	 * 
	 * @param document
	 *            a container holding the text to be ranked
	 * @param iterations
	 *            the number of iterations for which the algorithm should run
	 * @param threshold
	 *            the stop threshold for the algorithm
	 * @param dampingFactor
	 *            the damping factor for the algorithm
	 * @return a {@link Stream} containing {@link Pair Pairs} of objects and their ranks
	 */
	public static Stream<Pair<CoreMap, Double>> getRankedSentencesStream(Annotation document, int iterations, double threshold, double dampingFactor) {
		return generateGraph(document).getRankedObjectsStream();
	}
	
	/**
	 * This method runs the TextRank algorithm before returning
	 * 
	 * @param document
	 *            a container holding the text to be ranked
	 * @param iterations
	 *            the number of iterations for which the algorithm should run
	 * @param threshold
	 *            the stop threshold for the algorithm
	 * @param dampingFactor
	 *            the damping factor for the algorithm
	 * @return a {@link Stream} containing {@link Pair Pairs} of objects and their ranks sorted in <i>descending</i> order
	 */
	public static Stream<Pair<CoreMap, Double>> getSortedRankedSentencesStream(Annotation document, int iterations, double threshold, double dampingFactor) {
		return generateGraph(document).getSortedRankedObjectsStream();
	}
	
	/**
	 * This method runs the TextRank algorithm before returning
	 * 
	 * @param document
	 *            a container holding the text to be ranked
	 * @param iterations
	 *            the number of iterations for which the algorithm should run
	 * @param threshold
	 *            the stop threshold for the algorithm
	 * @param dampingFactor
	 *            the damping factor for the algorithm
	 * @return a {@link List} of {@link Pair Pairs} of values and their ranks from the graph
	 */
	public static List<Pair<CoreMap, Double>> getRankedSentences(Annotation document, int iterations, double threshold, double dampingFactor) {
		return getRankedSentencesStream(document).collect(Collectors.toList());
	}
	
	/**
	 * This method runs the TextRank algorithm before returning
	 * 
	 * @param document
	 *            a container holding the text to be ranked
	 * @param iterations
	 *            the number of iterations for which the algorithm should run
	 * @param threshold
	 *            the stop threshold for the algorithm
	 * @param dampingFactor
	 *            the damping factor for the algorithm
	 * @return a {@link List} of ranked objects sorted in <i>descending</i> order
	 */
	public static List<Pair<CoreMap, Double>> getSortedRankedSentences(Annotation document, int iterations, double threshold, double dampingFactor) {
		return getSortedRankedSentencesStream(document).collect(Collectors.toList());
	}
	
	/**
	 * This method runs the TextRank algorithm before returning
	 * 
	 * @param sentences
	 *            a {@link List} holding the {@link CoreMap CoreMaps} representing the sentences to be ranked
	 * @param iterations
	 *            the number of iterations for which the algorithm should run
	 * @param threshold
	 *            the stop threshold for the algorithm
	 * @param dampingFactor
	 *            the damping factor for the algorithm
	 * @return a {@link Stream} containing {@link Pair Pairs} of objects and their ranks
	 */
	public static Stream<Pair<CoreMap, Double>> getRankedSentencesStream(List<CoreMap> sentences, int iterations, double threshold, double dampingFactor) {
		return generateGraph(sentences).getRankedObjectsStream();
	}
	
	/**
	 * This method runs the TextRank algorithm before returning
	 * 
	 * @param sentences
	 *            a {@link List} holding the {@link CoreMap CoreMaps} representing the sentences to be ranked
	 * @param iterations
	 *            the number of iterations for which the algorithm should run
	 * @param threshold
	 *            the stop threshold for the algorithm
	 * @param dampingFactor
	 *            the damping factor for the algorithm
	 * @return a {@link Stream} containing {@link Pair Pairs} of objects and their ranks sorted in <i>descending</i> order
	 */
	public static Stream<Pair<CoreMap, Double>> getSortedRankedSentencesStream(List<CoreMap> sentences, int iterations, double threshold, double dampingFactor) {
		return generateGraph(sentences).getSortedRankedObjectsStream();
	}
	
	/**
	 * This method runs the TextRank algorithm before returning
	 * 
	 * @param sentences
	 *            a {@link List} holding the {@link CoreMap CoreMaps} representing the sentences to be ranked
	 * @param iterations
	 *            the number of iterations for which the algorithm should run
	 * @param threshold
	 *            the stop threshold for the algorithm
	 * @param dampingFactor
	 *            the damping factor for the algorithm
	 * @return a {@link List} of {@link Pair Pairs} of values and their ranks from the graph
	 */
	public static List<Pair<CoreMap, Double>> getRankedSentences(List<CoreMap> sentences, int iterations, double threshold, double dampingFactor) {
		return getRankedSentencesStream(sentences).collect(Collectors.toList());
	}
	
	/**
	 * This method runs the TextRank algorithm before returning
	 * 
	 * @param sentences
	 *            a {@link List} holding the {@link CoreMap CoreMaps} representing the sentences to be ranked
	 * @param iterations
	 *            the number of iterations for which the algorithm should run
	 * @param threshold
	 *            the stop threshold for the algorithm
	 * @param dampingFactor
	 *            the damping factor for the algorithm
	 * @return a {@link List} of ranked objects sorted in <i>descending</i> order
	 */
	public static List<Pair<CoreMap, Double>> getSortedRankedSentences(List<CoreMap> sentences, int iterations, double threshold, double dampingFactor) {
		return getSortedRankedSentencesStream(sentences).collect(Collectors.toList());
	}
}

enum OutputType {
	JSON {
		@Override
		public void printOutput(Appendable writer, Map<Article, List<Pair<CoreMap, Double>>> ranked, boolean pos) throws IOException {
			JSONObject output = new JSONObject();
			Function<CoreMap, String> converter = pos ? POSTagger::tag : POSTagger::reconstructSentence;
			for (Entry<Article, List<Pair<CoreMap, Double>>> e : ranked.entrySet()) {
				JSONArray array = new JSONArray();
				for (Pair<CoreMap, Double> sentence : e.getValue()) {
					JSONArray sen = new JSONArray(2);
					sen.add(new JSONNumber<>(sentence.getY()));
					sen.add(new JSONString(converter.apply(sentence.getX())));
					array.add(sen);
				}
				output.put(e.getKey().getID().toString(), array);
			}
			JSONSystem.writeJSON(output, writer);
		}
		
		@Override
		public void printOutput(Appendable writer, List<Pair<CoreMap, Double>> ranked, boolean pos) throws IOException {
			Function<CoreMap, String> converter = pos ? POSTagger::tag : POSTagger::reconstructSentence;
			JSONArray array = new JSONArray();
			for (Pair<CoreMap, Double> sentence : ranked) {
				JSONArray sen = new JSONArray(2);
				sen.add(new JSONNumber<>(sentence.getY()));
				sen.add(new JSONString(converter.apply(sentence.getX())));
				array.add(sen);
			}
			JSONSystem.writeJSON(array, writer);
		}
	},
	LIST {
		@Override
		public void printOutput(Appendable writer, Map<Article, List<Pair<CoreMap, Double>>> ranked, boolean pos) throws IOException {
			Function<CoreMap, String> converter = pos ? POSTagger::tag : POSTagger::reconstructSentence;
			for (Entry<Article, List<Pair<CoreMap, Double>>> e : ranked.entrySet()) {
				writer.append(border).append(e.getKey().getID().toString()).append(border).append(System.lineSeparator());
				for (Pair<CoreMap, Double> s : e.getValue())
					writer.append(s.getY().toString()).append(" :: ").append(converter.apply(s.getX())).append(System.lineSeparator());
				if (writer instanceof Flushable)
					((Flushable) writer).flush();
			}
		}
		
		@Override
		public void printOutput(Appendable writer, List<Pair<CoreMap, Double>> ranked, boolean pos) throws IOException {
			Function<CoreMap, String> converter = pos ? POSTagger::tag : POSTagger::reconstructSentence;
			for (Pair<CoreMap, Double> s : ranked)
				writer.append(s.getY().toString()).append(" :: ").append(converter.apply(s.getX())).append(System.lineSeparator());
			if (writer instanceof Flushable)
				((Flushable) writer).flush();
		}
	};
	
	private static final String border = "-------------------------";
	
	public abstract void printOutput(Appendable writer, Map<Article, List<Pair<CoreMap, Double>>> ranked, boolean pos) throws IOException;
	
	public abstract void printOutput(Appendable writer, List<Pair<CoreMap, Double>> ranked, boolean pos) throws IOException;
}

enum InputType {
	ID {
		@Override
		public Collection<Article> getArticles(InputStream input, ArticleManager am) {
			String inp = "";
			try (Scanner scanner = new Scanner(input)) {
				inp = scanner.nextLine();
			}
			Collection<Article> out = new LinkedHashSet<>();
			for (String id : inp.split("(,\\s*|\\s+)")) {
				try {
					out.add(am.load(Integer.parseInt(id)));
				}
				catch (NumberFormatException | ClassNotFoundException | SQLException | IOException e) {
					TextRank.logger.error(id + " is not a valid article id.", e);
				}
			}
			return out;
		}
	},
	TEXT {
		@Override
		public Collection<Article> getArticles(InputStream input, ArticleManager am) {
			Collection<Article> out = new LinkedHashSet<>();
			Pattern articleSplit = Pattern.compile("[\\-]{5,}(\\d+)?.*");
			String title = null;
			StringBuilder text = new StringBuilder();
			Integer id = null;
			String inp = "";
			try (Scanner scanner = new Scanner(input); Scanner sc = scanner.useDelimiter("\\A")) {
				inp = sc.next();
			}
			for (String line : inp.split(System.lineSeparator())) {
				Matcher m = articleSplit.matcher(line);
				if (m.matches()) {
					if (text.length() > 0)
						out.add(new Article(title, text.toString().trim(), (URL) null, (Source) null, id));
					text.delete(0, text.length());
					title = null;
					id = m.group(1) == null ? null : Integer.parseInt(m.group(1));
				}
				else if (title == null) {
					title = line.trim();
				}
				else {
					text.append(line).append(System.lineSeparator());
				}
			}
			if (text.length() > 0)
				out.add(new Article(title, text.toString().trim(), (URL) null, (Source) null, id));
			return out;
		}
	};
	
	public abstract Collection<Article> getArticles(InputStream input, ArticleManager am);
}
