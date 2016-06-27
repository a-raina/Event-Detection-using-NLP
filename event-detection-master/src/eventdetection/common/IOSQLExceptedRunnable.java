package eventdetection.common;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Provides a Functional Interface that represents a function that takes no arguments and returns no value.
 * 
 * @author Joshua Lipstone
 */
public interface IOSQLExceptedRunnable {
	
	/**
	 * Runs the function
	 * 
	 * @throws IOException
	 *             if an I/O error occurs
	 * @throws SQLException
	 *             if an SQL error occurs
	 */
	public void run() throws IOException, SQLException;
}
