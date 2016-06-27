package eventdetection.validator;

import eventdetection.common.IDAble;
import eventdetection.common.Query;

/**
 * Simple public interface for validation algorithms
 * 
 * @author Joshua Lipstone
 */
public interface ValidationAlgorithm extends IDAble<Integer> {
	
	/**
	 * Determines whether the {@link ValidationResult} is sufficient to validate the {@link Query} if it was produced by the
	 * {@link ValidationAlgorithm}
	 * 
	 * @param result
	 *            the {@link ValidationResult} to test
	 * @return {@code true} iff the {@link ValidationResult ValidationResult's} {@link ValidationResult#getValidates()} call
	 *         returns a value above the {@link ValidationAlgorithm ValidationAlgorithm's} threshold
	 */
	public boolean doesValidate(ValidationResult result);
}
