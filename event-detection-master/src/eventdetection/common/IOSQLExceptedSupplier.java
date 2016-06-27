package eventdetection.common;

import java.io.IOException;
import java.sql.SQLException;

import toberumono.utils.functions.ExceptedSupplier;

/**
 * Narrows the exceptions thrown by the {@link ExceptedSupplier} Functional Interface to those that are needed.
 * 
 * @author Joshua Lipstone
 * @param <T>
 *            the type of result being supplied
 */
public interface IOSQLExceptedSupplier<T> extends ExceptedSupplier<T> {
	
	@Override
	public T get() throws IOException, SQLException;
}
