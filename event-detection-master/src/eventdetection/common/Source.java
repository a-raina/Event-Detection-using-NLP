package eventdetection.common;

import java.io.IOException;
import java.io.Serializable;
import java.nio.file.Path;
import java.sql.ResultSet;
import java.sql.SQLException;

import toberumono.json.JSONObject;
import toberumono.json.JSONSystem;

import eventdetection.downloader.Scraper;

/**
 * Represents a source of news information.
 * 
 * @author Joshua Lipstone
 */
public class Source implements IDAble<Integer>, Serializable {
	private static final long serialVersionUID = 1L;
	
	private final int id;
	private final String name;
	private final double reliability;
	
	/**
	 * Creates a {@link Source} with the given ID and reliability coefficient
	 * 
	 * @param id
	 *            the ID of the {@link Source}
	 * @param name
	 *            the name of the {@link Source}
	 * @param reliability
	 *            the reliability coefficient of the {@link Source}
	 */
	public Source(int id, String name, double reliability) {
		this.id = id;
		this.name = name;
		this.reliability = reliability;
	}
	
	/**
	 * @return a coefficient used to denote how much weight we give to this {@link Source}
	 */
	public double getReliability() {
		return reliability;
	}
	
	@Override
	public Integer getID() {
		return id;
	}
	
	/**
	 * @return the {@link Source Source's} name
	 */
	public String getName() {
		return name;
	}
	
	@Override
	public int hashCode() {
		return (getName() + getID()).hashCode();
	}
	
	@Override
	public boolean equals(Object o) {
		if (o == null || !(o instanceof Source))
			return false;
		Source s = (Source) o;
		return getID() == s.getID() && getName().equals(s.getName()) && getReliability() == s.getReliability();
	}
	
	/**
	 * Loads a {@link Source} from a JSON file
	 * 
	 * @param file
	 *            a {@link Path} to the JSON file
	 * @return the {@link Scraper} described in the JSON file
	 * @throws IOException
	 *             an I/O error occurs
	 */
	public static Source loadFromJSON(Path file) throws IOException {
		JSONObject json = (JSONObject) JSONSystem.loadJSON(file);
		return new Source(-1, (String) json.get("name").value(), (Double) json.get("reliability").value());
	}
	
	/**
	 * Loads a {@link Source} from SQL data.
	 * 
	 * @param rs
	 *            the {@link ResultSet} thats currently select row should be used to generate the {@link Source}
	 * @return the {@link Source} described in the current row in the SQL table
	 * @throws SQLException
	 *             an SQL error occurs
	 */
	public static Source loadFromSQL(ResultSet rs) throws SQLException {
		return new Source(rs.getInt("id"), rs.getString("source_name"), rs.getDouble("reliability"));
	}
}
