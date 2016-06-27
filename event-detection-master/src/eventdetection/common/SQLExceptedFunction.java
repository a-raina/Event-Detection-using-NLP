package eventdetection.common;

import java.io.IOException;
import java.sql.SQLException;

import toberumono.utils.functions.ExceptedFunction;

/**
 * A sub-interface of {@link ExceptedFunction} specifically for {@link SQLException SQLExceptions}.
 * 
 * @author Joshua Lipstone
 * @param <T>
 *            the type of the first argument
 * @param <R>
 *            the type of the returned value
 */
public interface SQLExceptedFunction<T, R> extends ExceptedFunction<T, R> {
	
	/**
	 * Applies this function to the given arguments.
	 *
	 * @param t
	 *            the first argument
	 * @return the function result
	 * @throws SQLException
	 *             if something goes wrong
	 * @throws IOException
	 *             if something goes wrong
	 */
	@Override
	public R apply(T t) throws SQLException, IOException;
}
