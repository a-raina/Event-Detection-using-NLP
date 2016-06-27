package eventdetection.validator.types;

import eventdetection.common.Article;
import eventdetection.common.Query;

/**
 * Enumerates the types of {@link Validator} implementations.
 * 
 * @author Joshua Lipstone
 */
public enum ValidatorType {
	/**
	 * A {@link Validator} that takes one {@link Query} and one {@link Article}
	 */
	OneToOne,
	/**
	 * A {@link Validator} that takes one {@link Query} and multiple {@link Article Articles}
	 */
	OneToMany,
	/**
	 * A {@link Validator} that takes multiple {@link Query Queries} and one {@link Article}
	 */
	ManyToOne,
	/**
	 * A {@link Validator} that takes multiple {@link Query Queries} and multiple {@link Article Articles}
	 */
	ManyToMany,
	/**
	 * A {@link Validator} that takes one {@link Query}
	 */
	QueryOnly,
	/**
	 * A {@link Validator} that takes one {@link Article}
	 */
	ArticleOnly;
}
