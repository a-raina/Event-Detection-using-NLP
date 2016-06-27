package eventdetection.common;

import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Represents a query for the validator.
 * 
 * @author Joshua Lipstone
 */
public class Query implements IDAble<Integer> {
	private final int id;
	private final String subject, verb, directObject, indirectObject, location;
	private final boolean processed;
	
	/**
	 * Initializes a {@link Query} using the values in a {@link ResultSet}
	 * 
	 * @param rs
	 *            the {@link ResultSet} to use
	 * @throws SQLException
	 *             if there is an error reading the {@link ResultSet}
	 */
	public Query(ResultSet rs) throws SQLException {
		id = rs.getInt("id");
		subject = rs.getString("subject");
		verb = rs.getString("verb");
		directObject = rs.getString("direct_obj");
		indirectObject = rs.getString("indirect_obj");
		location = rs.getString("loc");
		processed = rs.getBoolean("processed");
	}
	
	/**
	 * Initializes a {@link Query} with the specific field values
	 * 
	 * @param id
	 *            the ID as it is in the database
	 * @param subject
	 *            the subject
	 * @param verb
	 *            the verb
	 * @param directObject
	 *            the direct object
	 * @param indirectObject
	 *            the indirect object
	 * @param location
	 *            the location
	 * @param processed
	 *            whether the {@link Query} has been preprocessed
	 */
	public Query(int id, String subject, String verb, String directObject, String indirectObject, String location, Boolean processed) {
		this.id = id;
		this.subject = subject;
		this.verb = verb;
		this.directObject = directObject;
		this.indirectObject = indirectObject;
		this.location = location;
		this.processed = processed;
	}
	
	/**
	 * @return the id
	 */
	@Override
	public Integer getID() {
		return id;
	}
	
	/**
	 * @return the subject
	 */
	public String getSubject() {
		return subject;
	}
	
	/**
	 * @return the verb
	 */
	public String getVerb() {
		return verb;
	}
	
	/**
	 * @return the direct object
	 */
	public String getDirectObject() {
		return directObject;
	}
	
	/**
	 * @return the indirect object
	 */
	public String getIndirectObject() {
		return indirectObject;
	}
	
	/**
	 * @return the location
	 */
	public String getLocation() {
		return location;
	}
	
	/**
	 * @return whether the {@link Query} has been processed
	 */
	public boolean isProcessed() {
		return processed;
	}
}
