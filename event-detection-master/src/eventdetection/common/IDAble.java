package eventdetection.common;

/**
 * Just flags objects as having an ID.
 * 
 * @author Joshua Lipstone
 * @param <T>
 *            the type of the ID
 */
public interface IDAble<T> {
	
	/**
	 * @return the ID of the object
	 */
	public T getID();
}
