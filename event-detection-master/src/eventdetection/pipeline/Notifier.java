package eventdetection.pipeline;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.nio.file.Paths;
import java.sql.SQLException;
import java.util.Collection;
import java.util.Map;

import toberumono.json.JSONArray;
import toberumono.json.JSONNumber;
import toberumono.json.JSONObject;
import toberumono.json.JSONSystem;

import eventdetection.common.Article;
import eventdetection.common.Query;
import eventdetection.common.SubprocessHelpers;
import eventdetection.validator.ValidationResult;

/**
 * A simple wrapper for the Notifier that Josie wrote.
 * 
 * @author Joshua Lipstone
 */
public class Notifier implements PipelineComponent {
	
	@Override
	public void execute(Map<Integer, Query> queries, Map<Integer, Article> articles, Collection<ValidationResult> results) throws IOException, SQLException {
		JSONObject res = new JSONObject();
		String query;
		for (ValidationResult r : results) { //Builds the results into a JSONObject that maps query -> list of articles that validated it
			if (!r.doesValidate())
				continue;
			if (!res.containsKey(query = r.getQueryID().toString()))
				res.put(query, new JSONArray());
			((JSONArray) res.get(query)).add(new JSONNumber<>(r.getArticleID()));
		}
		Process p = SubprocessHelpers.executePythonProcess(Paths.get("./Utils/Notifier.py"));
		try (BufferedWriter bw = new BufferedWriter(new OutputStreamWriter(p.getOutputStream()))) { //This closes the stream so that the process can continue
			JSONSystem.writeJSON(res, bw);
		}
		try {
			p.waitFor();
		}
		catch (InterruptedException e) {}
	}
}
