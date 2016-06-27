package eventdetection.common;

import java.util.List;
import java.util.Properties;
import java.util.regex.Pattern;

import edu.stanford.nlp.ling.CoreAnnotations.PartOfSpeechAnnotation;
import edu.stanford.nlp.ling.CoreAnnotations.SentencesAnnotation;
import edu.stanford.nlp.ling.CoreAnnotations.TokensAnnotation;
import edu.stanford.nlp.ling.CoreLabel;
import edu.stanford.nlp.pipeline.Annotation;
import edu.stanford.nlp.pipeline.StanfordCoreNLP;
import edu.stanford.nlp.util.CoreMap;

/**
 * A wrapper for the CoreNLP API.
 * 
 * @author Joshua Lipstone
 */
public class POSTagger {
	private static final String delimiter = "_";
	private static StanfordCoreNLP pipeline = null;
	private static final Pattern newline = Pattern.compile("\n", Pattern.LITERAL);
	private static final Pattern untagger = Pattern.compile("([^_\\s]+)_([^_\\s]+)");
	
	/**
	 * Initializes the pipline if it is {@code null}
	 * 
	 * @return the {@link StanfordCoreNLP} pipeline to use
	 */
	public static synchronized StanfordCoreNLP getPipeline() {
		if (pipeline == null) {
			// creates a StanfordCoreNLP object, with POS tagging, lemmatization,
			// NER, parsing, and coreference resolution
			Properties props = new Properties();
			props.setProperty("annotators", "tokenize, ssplit, pos, lemma, ner, parse, dcoref, depparse");
			pipeline = new StanfordCoreNLP(props);
		}
		return pipeline;
	}
	
	/**
	 * Runs the given {@link Annotation} through the {@link POSTagger POSTagger's} {@link StanfordCoreNLP pipeline}
	 * 
	 * @param document
	 *            the {@link Annotation} to run through the {@link StanfordCoreNLP pipeline}
	 */
	public static void annotate(Annotation document) {
		getPipeline().annotate(document);
	}
	
	/**
	 * Generates an {@link Annotation} for the given {@code text}, runs it through the {@link POSTagger POSTagger's}
	 * {@link StanfordCoreNLP pipeline} and returns it.
	 * 
	 * @param text
	 *            the text for which to generate the {@link Annotation}
	 * @return the generated {@link Annotation}
	 */
	public static Annotation annotate(String text) {
		Annotation document = new Annotation(text);
		annotate(document);
		return document;
	}
	
	/**
	 * Generates an {@link Annotation} for each paragraph in the given {@code text}. All of the generated {@link Annotation
	 * Annotations} a generated through a call to {@link #annotate(String)}.
	 * 
	 * @param text
	 *            the text for which to generate the {@link Annotation Annotations}
	 * @return the generated {@link Annotation Annotations}
	 * @see #annotate(String)
	 */
	public static Annotation[] annotateParagraphs(String text) {
		String[] paragraphs = newline.split(text);
		Annotation[] out = new Annotation[paragraphs.length];
		for (int i = 0; i < paragraphs.length; i++)
			out[i] = annotate(paragraphs[i]);
		return out;
	}
	
	/**
	 * Generates PoS tagged text from the given {@link Annotation Annotations} and stitches it together into a single
	 * {@link String} using newlines ({@code '\n'}) to separate the paragraphs.
	 * 
	 * @param paragraphs
	 *            an array of {@link Annotation Annotations}, one for each paragraph
	 * @return the PoS tagged text
	 */
	public static String tagParagraphs(Annotation[] paragraphs) {
		StringBuilder sb = new StringBuilder();
		for (Annotation paragraph : paragraphs) { //This allows the annotated text to retain paragraph breaks.
			tag(paragraph, sb).append("\n");
		}
		return sb.toString().trim();
	}
	
	/**
	 * Tags the given text. This keeps paragraphs.
	 * 
	 * @param text
	 *            the text to tag.
	 * @return the tagged text
	 */
	public static String tag(String text) {
		StringBuilder sb = new StringBuilder((int) (text.length() * 1.5));
		for (String paragraph : newline.split(text)) { //This allows the annotated text to retain paragraph breaks.
			Annotation document = annotate(paragraph);
			tag(document, sb).append("\n");
		}
		return sb.toString().trim();
	}
	
	/**
	 * Generates PoS tagged text from the given {@link Annotation}.
	 * 
	 * @param document
	 *            the {@link Annotation} to use to generate the tagged text. It <i>must</i> have already been run through
	 *            {@link #annotate(Annotation)} before being passed to this function
	 * @return the PoS tagged text
	 */
	public static String tag(Annotation document) {
		return tag(document, new StringBuilder()).toString().trim();
	}
	
	/**
	 * Generates tagged text from the given {@link List} of {@link CoreMap CoreMaps}.
	 * 
	 * @param sentences
	 *            a {@link List} of {@link CoreMap CoreMaps} representing the text
	 * @return the tagged text as a {@link String}
	 */
	public static String tag(List<CoreMap> sentences) {
		return tag(sentences, new StringBuilder()).toString().trim();
	}
	
	/**
	 * Generates tagged text from the given {@link CoreMap}.
	 * 
	 * @param sentence
	 *            a {@link CoreMap} representing the text
	 * @return the tagged text as a {@link String}
	 */
	public static String tag(CoreMap sentence) {
		return tag(sentence, new StringBuilder()).toString().trim();
	}
	
	/**
	 * Generates tagged text from the given {@link Annotation} and places it in the given {@link StringBuilder}.
	 * 
	 * @param document
	 *            the {@link Annotation} to use to generate the tagged text. It <i>must</i> have already been run through
	 *            {@link #annotate(Annotation)} before being passed to this function
	 * @param sb
	 *            the {@link StringBuilder} in which the tagged text should be placed
	 * @return the {@link StringBuilder} used (for chaining purposes)
	 */
	public static StringBuilder tag(Annotation document, StringBuilder sb) {
		return tag(document.get(SentencesAnnotation.class), sb);
	}
	
	/**
	 * Generates tagged text from the given {@link List} of {@link CoreMap CoreMaps} and places it in the given
	 * {@link StringBuilder}.
	 * 
	 * @param sentences
	 *            a {@link List} of {@link CoreMap CoreMaps} representing the text
	 * @param sb
	 *            the {@link StringBuilder} in which the tagged text should be placed
	 * @return the {@link StringBuilder} used (for chaining purposes)
	 */
	public static StringBuilder tag(List<CoreMap> sentences, StringBuilder sb) {
		for (CoreMap sentence : sentences) {
			// traversing the words in the current sentence
			// a CoreLabel is a CoreMap with additional token-specific methods
			List<CoreLabel> tokens = sentence.get(TokensAnnotation.class);
			for (CoreLabel token : tokens)
				sb.append(token.word()).append(delimiter).append(token.get(PartOfSpeechAnnotation.class)).append(" ");
		}
		return sb;
	}
	
	/**
	 * Generates tagged text from the given {@link CoreMap} and places it in the given {@link StringBuilder}.
	 * 
	 * @param sentence
	 *            a {@link CoreMap} representing the text
	 * @param sb
	 *            the {@link StringBuilder} in which the tagged text should be placed
	 * @return the {@link StringBuilder} used (for chaining purposes)
	 */
	public static StringBuilder tag(CoreMap sentence, StringBuilder sb) {
		for (CoreLabel token : sentence.get(TokensAnnotation.class))
			sb.append(token.word()).append(delimiter).append(token.get(PartOfSpeechAnnotation.class)).append(" ");
		return sb;
	}
	
	/**
	 * Untags the given text. This process is comprised of using regex to remove the _tag suffixes from each word.
	 * 
	 * @param text
	 *            the text to untag
	 * @return the untagged text
	 */
	public static String untag(String text) {
		return untagger.matcher(text).replaceAll("$1");
	}

	/**
	 * Reconstructs a paragraph (without PoS tags) from a {@link Annotation} from the CoreNLP library.
	 * 
	 * @param paragraph
	 *            the {@link Annotation} representing the paragraph to reconstruct
	 * @return the reconstructed sentence
	 */
	public static String reconstructParagraph(Annotation paragraph) {
		StringBuilder sb = new StringBuilder();
		for (CoreMap sentence : paragraph.get(SentencesAnnotation.class))
			reconstructSentence(sentence, sb).append(" ");
		return sb.toString().replaceAll("\\s+([!,.;:'\"?%])", "$1").trim(); //Fixes extra spaces around punctuation
	}
	
	/**
	 * Reconstructs a sentence (without PoS tags) from a {@link CoreMap} from the CoreNLP library.
	 * 
	 * @param sentence
	 *            the {@link CoreMap} representing the sentence to reconstruct
	 * @return the reconstructed sentence
	 */
	public static String reconstructSentence(CoreMap sentence) {
		return reconstructSentence(sentence, new StringBuilder()).toString().replaceAll("\\s+([!,\\.;:'\"?%])", "$1").trim();
	}
	
	/**
	 * Reconstructs a sentence (without PoS tags) from a {@link CoreMap} from the CoreNLP library in the given
	 * {@link StringBuilder}.
	 * 
	 * @param sentence
	 *            the {@link CoreMap} representing the sentence to reconstruct
	 * @param sb
	 *            the {@link StringBuilder} into which the sentence should be reconstructed
	 * @return the {@link StringBuilder}
	 */
	public static StringBuilder reconstructSentence(CoreMap sentence, StringBuilder sb) {
		return sb.append(sentence.toString());
	}
}
