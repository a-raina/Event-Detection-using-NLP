package eventdetection.downloader;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import eventdetection.common.Article;

/**
 * Implements a {@link Downloader} that queries a list of other {@link Downloader Downloaders} and returns the
 * {@link Article Articles} that they find.
 * 
 * @author Joshua Lipstone
 */
public class DownloaderCollection extends Downloader {
	private final Collection<Downloader> downloaders;
	private boolean closed;
	
	/**
	 * Creates an empty {@link DownloaderCollection}
	 */
	public DownloaderCollection() {
		downloaders = new ArrayList<>();
		closed = false;
	}
	
	/**
	 * Creates a {@link DownloaderCollection} that contains the {@link Downloader Downloaders} within the given
	 * {@link Collection}
	 * 
	 * @param downloaders
	 *            the {@link Collection} of {@link Downloader Downloaders}
	 */
	public DownloaderCollection(Collection<Downloader> downloaders) {
		this();
		getDownloaders().addAll(downloaders);
	}
	
	/**
	 * Adds the given {@link Downloader} to this {@link DownloaderCollection}
	 * 
	 * @param downloader
	 *            the {@link Downloader} to add
	 */
	public void addDownloader(Downloader downloader) {
		if (downloader == this)
			return;
		getDownloaders().add(downloader);
	}
	
	@Override
	public List<Article> get() {
		List<Article> out = new ArrayList<>();
		for (Downloader downloader : getDownloaders())
			out.addAll(downloader.get());
		return out;
	}
	
	/**
	 * @return the {@link Downloader Downloaders} to which this {@link DownloaderCollection} forwards
	 */
	public Collection<Downloader> getDownloaders() {
		return downloaders;
	}
	
	/**
	 * @return {@code true} if the {@link DownloaderCollection DownloaderCollection's} backing {@link Collection} is equal to
	 *         the backing {@link Collection} of the other {@link DownloaderCollection}, otherwise {@code false}
	 */
	@Override
	public boolean equals(Object o) {
		if (o == null || !(o instanceof DownloaderCollection))
			return false;
		DownloaderCollection dc = (DownloaderCollection) o;
		return getDownloaders().equals(dc.getDownloaders());
	}
	
	/**
	 * @return the hash code of the {@link DownloaderCollection DownloaderCollection's} backing {@link Collection}
	 */
	@Override
	public int hashCode() {
		return getDownloaders().hashCode();
	}
	
	@Override
	public void close() throws IOException {
		if (closed)
			return;
		closed = true;
		for (Downloader d : getDownloaders()) //Close all downloaders
			d.close();
	}
}
