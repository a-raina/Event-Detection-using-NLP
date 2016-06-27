package eventdetection.textrank;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import toberumono.structures.tuples.Pair;

/**
 * The graph used for the various TextRank algorithms.
 * 
 * @author Joshua Lipstone
 * @param <T>
 *            the type being ranked
 */
public class TextRankGraph<T> {
	private TextRankNode<T>[] nodes;
	private int position;
	private final int maxIterations;
	private final double threshold, dampingFactor;
	private boolean changed;
	
	/**
	 * Creates a new {@link TextRankGraph}
	 * 
	 * @param initArraySize
	 *            the initial array size
	 * @param maxIterations
	 *            the maximum number of iterations to run the ranking algorithm for
	 * @param threshold
	 *            the convergence threshold for the ranking algorithm
	 * @param dampingFactor
	 *            the damping factor for the ranking algorithm
	 */
	public TextRankGraph(int initArraySize, int maxIterations, double threshold, double dampingFactor) {
		this.position = 0;
		@SuppressWarnings("unchecked")
		final TextRankNode<T>[] nodes = (TextRankNode<T>[]) new TextRankNode<?>[initArraySize < 3 ? 3 : initArraySize];
		this.nodes = nodes;
		this.maxIterations = maxIterations;
		this.threshold = threshold;
		this.dampingFactor = dampingFactor;
		changed = false;
	}
	
	/**
	 * Adds a {@link TextRankNode} to the {@link TextRankGraph}
	 * 
	 * @param node
	 *            the {@link TextRankNode} to add
	 * @return the {@link TextRankNode}'s ID
	 */
	public int addNode(TextRankNode<T> node) {
		if (position >= nodes.length)
			nodes = Arrays.copyOf(nodes, (int) (nodes.length * 1.5)); //This results in more array expansions but can reduce memory footprint
		nodes[position] = node;
		changed = true;
		return position++;
	}
	
	/**
	 * Adds a directed {@link TextRankEdge} to the {@link TextRankGraph}
	 * 
	 * @param n1
	 *            the source {@link TextRankNode}
	 * @param weight
	 *            the weight of the {@link TextRankEdge}
	 * @param n2
	 *            the target {@link TextRankNode}
	 */
	public void addEdge(int n1, double weight, int n2) {
		nodes[n1].addOut(new TextRankEdge<>(weight, nodes[n2]));
		nodes[n2].addIn(new TextRankEdge<>(weight, nodes[n1]));
		changed = true;
	}
	
	/**
	 * Runs the ranking algorithm on the graph
	 */
	public void rankNodes() {
		if (!changed)
			return;
		changed = false;
		for (int i = 0; i < position; i++)
			nodes[i].setRank(1.0);
		double[] rankings = new double[position];
		double negDampingFactor = 1 - dampingFactor, largestDifference = Double.MAX_VALUE, diff, sum = 0.0;
		TextRankEdge<T>[] ins = null, outs = null;
		int insSize, outsSize;
		for (int iter = 0; iter < maxIterations && largestDifference > threshold; iter++) {
			largestDifference = 0.0;
			for (int i = 0; i < rankings.length; i++) {
				rankings[i] = 0.0;
				ins = nodes[i].getIns();
				insSize = nodes[i].insSize();
				for (int j = 0; j < insSize; j++) {
					sum = 0.0;
					outs = ins[j].getTarget().getOuts();
					outsSize = ins[j].getTarget().outsSize();
					for (int k = 0; k < outsSize; k++)
						sum += outs[k].getWeight();
					if (sum != 0) //Accounts for the possibility of wholly unrelated sentences
						rankings[i] += (ins[j].getWeight() / sum * ins[j].getTarget().getRank());
				}
				rankings[i] = negDampingFactor + dampingFactor * rankings[i];
			}
			for (int i = 0; i < rankings.length; i++) {
				diff = Math.abs(nodes[i].getRank() - rankings[i]);
				if (diff > largestDifference)
					largestDifference = diff;
				nodes[i].setRank(rankings[i]);
			}
		}
	}
	
	/**
	 * This method runs the ranking algorithm ({@link #rankNodes()}) on the graph before returning.
	 * 
	 * @return a {@link Stream} containing {@link Pair Pairs} of objects and their ranks
	 */
	public Stream<Pair<T, Double>> getRankedObjectsStream() {
		rankNodes();
		return Arrays.stream(nodes, 0, position).map(a -> new Pair<>(a.getValue(), a.getRank()));
	}
	
	/**
	 * This method runs the ranking algorithm ({@link #rankNodes()}) on the graph before returning.
	 * 
	 * @return a {@link Stream} containing {@link Pair Pairs} of objects and their ranks sorted in <i>descending</i> order
	 */
	public Stream<Pair<T, Double>> getSortedRankedObjectsStream() {
		return getRankedObjectsStream().sorted((a, b) -> b.getY().compareTo(a.getY()));
	}
	
	/**
	 * This method runs the ranking algorithm ({@link #rankNodes()}) on the graph before returning.
	 * 
	 * @return a {@link List} of {@link Pair Pairs} of values and their ranks from the graph
	 */
	public List<Pair<T, Double>> getRankedObjects() {
		return getRankedObjectsStream().collect(Collectors.toList());
	}
	
	/**
	 * This method runs the ranking algorithm ({@link #rankNodes()}) on the graph before returning.
	 * 
	 * @return a {@link List} of ranked objects sorted in <i>descending</i> order
	 */
	public List<Pair<T, Double>> getSortedRankedObjects() {
		return getSortedRankedObjectsStream().collect(Collectors.toList());
	}
}
