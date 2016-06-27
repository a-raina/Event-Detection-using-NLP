package eventdetection.pipeline;

import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.Map;

import eventdetection.common.Article;
import eventdetection.common.Query;
import eventdetection.validator.ValidationResult;

/**
 * This describes the methods that must be implemented by components that can be added to the {@link Pipeline}.
 * 
 * @author Joshua Lipstone
 */
@FunctionalInterface
public interface PipelineComponent {
	
	/**
	 * Executes the {@link Pipeline} component's step with an empty query, article pair
	 * 
	 * @throws IOException
	 *             if an I/O error occurs
	 * @throws SQLException
	 *             if an SQL error occurs
	 */
	public default void execute() throws IOException, SQLException {
		execute(new LinkedHashMap<>(), new LinkedHashMap<>(), new ArrayList<>());
	}
	
	/**
	 * Executes the {@link Pipeline} component's step with the given query, article pair
	 * 
	 * @param queries
	 *            the {@link Query Queries} with which the step is to be executed
	 * @param articles
	 *            the {@link Article Articles} with which the step is to be executed
	 * @param results
	 *            the {@link Collection} into which the step should place {@link ValidationResult ValidationResults}
	 * @throws IOException
	 *             if an I/O error occurs
	 * @throws SQLException
	 *             if an SQL error occurs
	 */
	public void execute(Map<Integer, Query> queries, Map<Integer, Article> articles, Collection<ValidationResult> results) throws IOException, SQLException;
}
