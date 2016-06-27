package eventdetection.validator.types;

import eventdetection.common.Article;
import eventdetection.common.Query;
import eventdetection.validator.ValidationResult;

/**
 * Base class for implementations of validation algorithms that take one {@link Article} that are callable by this library.
 * 
 * @author Joshua Lipstone
 */
public abstract class ArticleOnlyValidator {
	
	/**
	 * Executes the algorithm that the {@link Validator} implements
	 * 
	 * @param article
	 *            the {@link Article} with which to validate {@link Query Queries}
	 * @return an array of {@link ValidationResult ValidationResults} with the appropriate information
	 * @throws Exception
	 *             if something goes wrong
	 */
	public abstract ValidationResult[] call(Article article) throws Exception;
}
