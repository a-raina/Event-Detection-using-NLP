package eventdetection.validator.implementations;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.file.Path;
import java.nio.file.Paths;

import toberumono.json.JSONObject;

import eventdetection.common.Article;
import eventdetection.common.Query;
import eventdetection.common.SubprocessHelpers;
import eventdetection.validator.ValidationResult;
import eventdetection.validator.types.OneToOneValidator;

/**
 * A simple wrapper that forwards to the Python KeywordValidator that was implemented by Josie, Laura and Julia.
 * 
 * @author Joshua Lipstone
 */
public class KeywordValidator extends OneToOneValidator {
	private final Path scriptPath;
	
	/**
	 * Constructs a new {@link KeywordValidator} with the given parameters.
	 * 
	 * @param parameters
	 *            a {@link JSONObject} containing the instance-specific parameters
	 */
	public KeywordValidator(JSONObject parameters) {
		scriptPath = Paths.get((String) parameters.get("script-path").value());
	}

	@Override
	public ValidationResult[] call(Query query, Article article) throws Exception {
		Process p = SubprocessHelpers.executePythonProcess(scriptPath, query.getID().toString(), article.getID().toString());
		p.waitFor();
		try (BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()))) {
			return new ValidationResult[]{new ValidationResult(query, article, Double.parseDouble(br.readLine()))};
		}
	}
}
