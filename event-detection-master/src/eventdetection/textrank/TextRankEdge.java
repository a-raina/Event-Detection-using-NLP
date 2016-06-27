package eventdetection.textrank;

/**
 * A directed edge in a {@link TextRankGraph}
 * 
 * @author Joshua Lipstone
 * @param <T>
 *            the type being ranked
 */
public class TextRankEdge<T> {
	private final double weight;
	private final TextRankNode<T> target;
	
	/**
	 * Creates a new {@link TextRankEdge} with the given weight and target
	 * 
	 * @param weight
	 *            the edge's weight
	 * @param target
	 *            the edge's target
	 */
	public TextRankEdge(double weight, TextRankNode<T> target) {
		this.weight = weight;
		this.target = target;
	}
	
	/**
	 * @return the weight
	 */
	public final double getWeight() {
		return weight;
	}
	
	/**
	 * @return the target
	 */
	public final TextRankNode<T> getTarget() {
		return target;
	}
}
