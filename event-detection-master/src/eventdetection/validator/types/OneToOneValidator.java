package eventdetection.validator.types;

import eventdetection.common.Article;
import eventdetection.common.Query;
import eventdetection.validator.ValidationResult;

/**
 * Base class for implementations of validation algorithms that take one {@link Query} and one {@link Article} that are
 * callable by this library.
 * 
 * @author Joshua Lipstone
 */
public abstract class OneToOneValidator {
	
	/**
	 * Executes the algorithm that the {@link Validator} implements
	 * 
	 * @param query
	 *            the {@link Query} to validate
	 * @param article
	 *            the {@link Article} with which to validate it
	 * @return an array of {@link ValidationResult ValidationResults} with the appropriate information
	 * @throws Exception
	 *             if something goes wrong
	 */
	public abstract ValidationResult[] call(Query query, Article article) throws Exception;
}
