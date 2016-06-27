package eventdetection.common;

import java.io.Serializable;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Arrays;

import edu.stanford.nlp.pipeline.Annotation;

/**
 * Represents an {@link Article} that has been processed. All {@link Annotation} processing and PoS tagging is done lazily. A
 * call to {@link #process()} will immediately perform all processing tasks.
 * 
 * @author Joshua Lipstone
 */
public class Article implements IDAble<Integer>, Serializable {
	private static final long serialVersionUID = 1L;
	
	private final String[] titles, texts;
	private Annotation title;
	private Annotation[] text;
	private final URL url;
	private final Source source;
	private final Integer id;
	private Integer hashCode;
	
	/**
	 * Initializes an {@link Article}
	 * 
	 * @param title
	 *            the title of the article as untagged text
	 * @param text
	 *            the text of the article as untagged text
	 * @param url
	 *            the URL of the full article as a {@link String}
	 * @param source
	 *            the {@link Source} that the article is from
	 * @throws MalformedURLException
	 *             if the given {@code url} is incorrectly formatted
	 */
	public Article(String title, String text, String url, Source source) throws MalformedURLException {
		this(title, text, new URL(url), source);
	}
	
	/**
	 * Initializes an {@link Article}
	 * 
	 * @param title
	 *            the title of the article as untagged text
	 * @param text
	 *            the text of the article as untagged text
	 * @param url
	 *            the {@link URL} of the full article
	 * @param source
	 *            the {@link Source} that the article is from
	 */
	public Article(String title, String text, URL url, Source source) {
		this(new String[]{title, null}, new String[]{text, null}, null, null, url, source, null);
	}
	
	/**
	 * Initializes an {@link Article}
	 * 
	 * @param title
	 *            the title of the article as untagged text
	 * @param text
	 *            the text of the article as untagged text
	 * @param url
	 *            the URL of the full article as a {@link String}
	 * @param source
	 *            the {@link Source} that the article is from
	 * @param id
	 *            the {@code ID} of the {@link Article} as an {@link Integer}
	 * @throws MalformedURLException
	 *             if the given {@code url} is incorrectly formatted
	 */
	public Article(String title, String text, String url, Source source, Integer id) throws MalformedURLException {
		this(title, text, new URL(url), source, id);
	}
	
	/**
	 * Initializes an {@link Article}
	 * 
	 * @param title
	 *            the title of the article as untagged text
	 * @param text
	 *            the text of the article as untagged text
	 * @param url
	 *            the {@link URL} of the full article
	 * @param source
	 *            the {@link Source} that the article is from
	 * @param id
	 *            the {@code ID} of the {@link Article} as an {@link Integer}
	 */
	public Article(String title, String text, URL url, Source source, Integer id) {
		this(new String[]{title, null}, new String[]{text, null}, null, null, url, source, id);
	}
	
	private Article(String[] titles, String[] texts, Annotation title, Annotation[] text, URL url, Source source, Integer id) { //Copy constructor
		this.titles = titles;
		this.texts = texts;
		this.title = title;
		this.text = text;
		this.url = url;
		this.source = source;
		this.id = id;
		hashCode = this.id == null ? null : id.hashCode(); //IDs are unique
	}
	
	/**
	 * Generates a shallow clone of the {@link Article} with the given {@code id}.
	 * 
	 * @param id
	 *            the new ID of the {@link Article}
	 * @return a shallow clone of the {@link Article} with the given {@code id}
	 */
	public Article copyWithID(int id) {
		return new Article(titles, texts, title, text, url, source, id);
	}
	
	/**
	 * Immediately performs all of the lazily evaluations that remain for the {@link Article Article's} fields. Call this
	 * prior to serialization.
	 */
	public final void process() {
		getAnnotatedTitle();
		getAnnotatedText();
		getTaggedTitle();
		getTaggedText();
	}
	
	/**
	 * @return the untagged title of the {@link Article}
	 */
	public final String getUntaggedTitle() {
		return titles[0];
	}
	
	/**
	 * @return the untagged text of the {@link Article}
	 */
	public final String getUntaggedText() {
		return texts[0];
	}
	
	/**
	 * @return the PoS tagged title of the {@link Article}
	 */
	public final String getTaggedTitle() {
		if (titles[1] == null)
			titles[1] = POSTagger.tag(getAnnotatedTitle());
		return titles[1];
	}
	
	/**
	 * @return the PoS tagged text of the {@link Article}
	 */
	public final String getTaggedText() {
		if (texts[1] == null)
			texts[1] = POSTagger.tagParagraphs(getAnnotatedText());
		return texts[1];
	}
	
	/**
	 * @return the {@link Annotation Annotated} title of the {@link Article}
	 */
	public final Annotation getAnnotatedTitle() {
		if (title == null)
			title = POSTagger.annotate(getUntaggedTitle());
		return title;
	}
	
	/**
	 * @return the {@link Annotation Annotated} text of the {@link Article}
	 */
	public final Annotation[] getAnnotatedText() {
		if (text == null)
			text = POSTagger.annotateParagraphs(getUntaggedText());
		return text;
	}
	
	/**
	 * @return the {@link URL} of the full article
	 */
	public final URL getURL() {
		return url;
	}
	
	/**
	 * @return the {@link Source} of the {@link Article}
	 */
	public final Source getSource() {
		return source;
	}
	
	/**
	 * @return the ID of the {@link Article}
	 */
	@Override
	public Integer getID() {
		return id;
	}
	
	@Override
	public String toString() {
		String out = "Title: " + getUntaggedTitle();
		out += "\nURL: " + getURL();
		out += "\n" + getUntaggedText();
		return out;
	}
	
	@Override
	public boolean equals(Object o) {
		if (!(o instanceof Article))
			return false;
		Article other = (Article) o;
		return !(id != other.id || !source.equals(other.source) || (url == null ? other.url != null : !url.equals(other.url)) ||
				(titles[0] == null ? other.titles[0] != null : !titles[0].equals(other.titles[0])) || !texts[0].equals(other.texts[0]) ||
				(titles[1] == null ? other.titles[1] != null : !titles[1].equals(other.titles[1])) ||
				(texts[1] == null ? other.texts[1] != null : !texts[1].equals(other.texts[1])) ||
				(title == null ? other.title != null : !title.equals(other.title)) ||
				(text == null ? other.text != null : !Arrays.equals(text, other.text)));
	}
	
	@Override
	public int hashCode() {
		if (hashCode == null) {
			if (id == null) {
				hashCode = 17;
				if (titles[0] != null)
					hashCode = hashCode * 31 + titles[0].hashCode();
				if (texts[0] != null)
					hashCode = hashCode * 31 + texts[0].hashCode();
				if (url != null)
					hashCode = hashCode * 31 + url.hashCode();
				if (source != null)
					hashCode = hashCode * 31 + source.hashCode();
			}
			else
				hashCode = id.hashCode();
		}
		return hashCode;
	}
}
