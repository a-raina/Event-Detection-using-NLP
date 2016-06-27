package eventdetection.validator.implementations;

import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map.Entry;

import toberumono.json.JSONArray;
import toberumono.json.JSONData;
import toberumono.json.JSONNumber;
import toberumono.json.JSONObject;
import toberumono.json.JSONSystem;

import eventdetection.common.Article;
import eventdetection.common.Query;
import eventdetection.common.SubprocessHelpers;
import eventdetection.validator.ValidationResult;
import eventdetection.validator.types.ManyToManyValidator;

/**
 * A wrapper that forwards to the Python ClusteringValidator written by Josie, Julia, and Laura
 * 
 * @author Joshua Lipstone
 */
public class ClusteringValidator extends ManyToManyValidator {
	
	/**
	 * Constructs a new ClusteringValidator instance
	 */
	public ClusteringValidator() {}
	
	@Override
	public ValidationResult[] call(Collection<Query> queries, Collection<Article> articles) throws Exception {
		List<ValidationResult> results = new ArrayList<>();
		Process p = SubprocessHelpers.executePythonProcess(Paths.get("./PythonValidators/ClusterValidator.py"), queries.stream().map(q -> q.getID().toString()).toArray(l -> new String[l]));
		p.waitFor();
		JSONObject res = (JSONObject) JSONSystem.readJSON(p.getInputStream());
		for (Entry<String, JSONData<?>> e : res.entrySet()) {
			JSONObject val = (JSONObject) e.getValue();
			int queryID = Integer.parseInt(e.getKey());
			double match = ((JSONNumber<?>) val.get("match_value")).value().doubleValue();
			JSONArray arts = (JSONArray) val.get("articles");
			for (JSONData<?> a : arts)
				results.add(new ValidationResult(queryID, ((JSONNumber<?>) a).value().intValue(), match));
		}
		return results.toArray(new ValidationResult[results.size()]);
	}
}
