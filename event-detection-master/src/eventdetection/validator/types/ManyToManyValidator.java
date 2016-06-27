package eventdetection.validator.types;

import java.util.Collection;

import eventdetection.common.Article;
import eventdetection.common.Query;
import eventdetection.validator.ValidationResult;

/**
 * Base class for implementations of validation algorithms that take multiple {@link Query Queries} and multiple
 * {@link Article Articles} that are callable by this library.
 * 
 * @author Joshua Lipstone
 */
public abstract class ManyToManyValidator {
	
	/**
	 * Executes the algorithm that the {@link Validator} implements
	 * 
	 * @param queries
	 *            the {@link Query Queries} to validate
	 * @param articles
	 *            the {@link Article Articles} with which to validate them
	 * @return an array of {@link ValidationResult ValidationResults} with the appropriate information
	 * @throws Exception
	 *             if something goes wrong
	 */
	public abstract ValidationResult[] call(Collection<Query> queries, Collection<Article> articles) throws Exception;
}
