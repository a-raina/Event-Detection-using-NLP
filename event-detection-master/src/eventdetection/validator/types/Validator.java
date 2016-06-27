package eventdetection.validator.types;

import java.util.concurrent.Callable;

import eventdetection.validator.ValidationResult;

/**
 * Base interface for implementations of validation algorithms that are callable by this library.
 * 
 * @author Joshua Lipstone
 */
public interface Validator extends Callable<ValidationResult[]> {
	
	/**
	 * Executes the algorithm that the {@link Validator} implements
	 * 
	 * @return a {@link ValidationResult} with the appropriate information
	 */
	@Override
	public ValidationResult[] call() throws Exception;
}
