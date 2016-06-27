package eventdetection.validator.types;

import java.util.Collection;

import eventdetection.common.Article;
import eventdetection.common.Query;
import eventdetection.validator.ValidationResult;

/**
 * Base class for implementations of validation algorithms that take one {@link Query} and multiple {@link Article Articles}
 * that are callable by this library.
 * 
 * @author Joshua Lipstone
 */
public interface OneToManyValidator {
	
	/**
	 * Executes the algorithm that the {@link Validator} implements
	 * 
	 * @param query
	 *            the {@link Query} to validate
	 * @param articles
	 *            the {@link Article Articles} with which to validate it
	 * @return an array of {@link ValidationResult ValidationResults} with the appropriate information
	 * @throws Exception
	 *             if something goes wrong
	 */
	public abstract ValidationResult[] call(Query query, Collection<Article> articles) throws Exception;
}
