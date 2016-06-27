package eventdetection.textrank;

import java.util.Arrays;

/**
 * A node in the {@link TextRankGraph}
 * 
 * @author Joshua Lipstone
 * @param <T>
 *            the type being ranked
 */
public class TextRankNode<T> {
	private double rank;
	private final T value;
	private TextRankEdge<T>[] outs, ins;
	private int oPos, iPos;
	
	/**
	 * Creates a new {@link TextRankNode} with the given rank and value
	 * 
	 * @param rank
	 *            the node's initial rank
	 * @param value
	 *            the node's value
	 */
	public TextRankNode(double rank, T value) {
		this.rank = rank;
		this.value = value;
		@SuppressWarnings("unchecked")
		final TextRankEdge<T>[] outs = (TextRankEdge<T>[]) new TextRankEdge<?>[3];
		@SuppressWarnings("unchecked")
		final TextRankEdge<T>[] ins = (TextRankEdge<T>[]) new TextRankEdge<?>[3];
		this.outs = outs;
		this.ins = ins;
	}
	
	/**
	 * Adds an outbound {@link TextRankEdge} to this node
	 * 
	 * @param edge
	 *            the outbound {@link TextRankEdge} to add
	 */
	public void addOut(TextRankEdge<T> edge) {
		if (oPos >= outs.length)
			outs = Arrays.copyOf(outs, (int) (outs.length * 1.5));
		outs[oPos++] = edge;
	}
	
	/**
	 * @return the outbound {@link TextRankEdge edges}
	 */
	public TextRankEdge<T>[] getOuts() {
		return outs;
	}
	
	/**
	 * @return the number of {@link TextRankEdge TextRankEdges} in the outs array
	 */
	public int outsSize() {
		return oPos;
	}
	
	/**
	 * Adds an inbound {@link TextRankEdge} to this node
	 * 
	 * @param edge
	 *            the inbound {@link TextRankEdge} to add
	 */
	public void addIn(TextRankEdge<T> edge) {
		if (iPos >= ins.length)
			ins = Arrays.copyOf(ins, (int) (ins.length * 1.5));
		ins[iPos++] = edge;
	}
	
	/**
	 * @return the inbound {@link TextRankEdge edges}
	 */
	public TextRankEdge<T>[] getIns() {
		return ins;
	}
	
	/**
	 * @return the number of {@link TextRankEdge TextRankEdges} in the ins array
	 */
	public int insSize() {
		return iPos;
	}
	
	/**
	 * @return the token
	 */
	public T getValue() {
		return value;
	}
	
	/**
	 * @return the rank
	 */
	public double getRank() {
		return rank;
	}
	
	/**
	 * @param rank
	 *            the rank to set
	 */
	public void setRank(double rank) {
		this.rank = rank;
	}
}
