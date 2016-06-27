package eventdetection.downloader;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.URL;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;

import toberumono.json.JSONArray;
import toberumono.json.JSONObject;
import toberumono.json.JSONString;
import toberumono.json.JSONSystem;

import eventdetection.common.SubprocessHelpers;

/**
 * An extension of {@link Scraper} that is designed for invoking Python 3 scripts.
 * 
 * @author Joshua Lipstone
 */
public class PythonScraper extends Scraper {
	
	protected final Path json;
	protected final JSONObject scripts, parameters;
	
	/**
	 * Creates a {@link PythonScraper} using the given configuration data.
	 * 
	 * @param json
	 *            the {@link Path} to the JSON file that describes the {@link PythonScraper}
	 * @param config
	 *            a {@link JSONObject} containing the configuration data for the {@link PythonScraper}
	 */
	public PythonScraper(Path json, JSONObject config) {
		super(json, config);
		this.json = json;
		//Insert the assumed maps into the JSON file
		JSONSystem.transferField("python", new JSONObject(), config);
		JSONObject python = (JSONObject) config.get("python");
		JSONSystem.transferField("scripts", new JSONObject(), python);
		JSONSystem.transferField("parameters", new JSONObject(), python);
		this.scripts = (JSONObject) python.get("scripts");
		this.parameters = (JSONObject) python.get("parameters");
	}

	@Override
	public String scrape(URL url) throws IOException {
		String link = url.toString();
		JSONObject variableParameters = new JSONObject();
		variableParameters.put("url", new JSONString(link));
		String sectioned = callScript("sectioning", variableParameters);
		return sectioned.trim();
	}
	
	/**
	 * This method calls a Python 3 script based on data in the "python" object {@link PythonScraper Scraper's} JSON file.
	 * 
	 * @param scriptName
	 *            the name of the script to call as it appears in the "python.scripts" section of the {@link PythonScraper
	 *            Scraper's} JSON file
	 * @param variableParameters
	 *            any parameters that should be passed to the script that aren't enumerated in the {@link PythonScraper
	 *            Scraper's} JSON file
	 * @return a {@link String} containing the contents of the scripts {@code stdout} stream
	 * @throws IOException
	 *             if an error occurs while invoking the script
	 */
	public String callScript(String scriptName, JSONObject variableParameters) throws IOException {
		String[] comm = ((JSONArray) scripts.get(scriptName)).stream().collect(ArrayList::new, (a, b) -> a.add((String) b.value()), ArrayList::addAll).toArray(new String[0]);
		Path scriptPath = json.getParent().resolve(comm[0]); //Script paths can be relative to the directory in which their defining file is located
		JSONObject parameters = new JSONObject(); //These are split up to provide a wider range of collections of parameter
		JSONObject scriptParameters = (JSONObject) parameters.get(scriptName);
		JSONObject globalParameters = (JSONObject) parameters.get("global");
		if (globalParameters != null)
			parameters.putAll(globalParameters);
		if (scriptParameters != null)
			parameters.putAll(scriptParameters);
		if (variableParameters != null)
			parameters.putAll(variableParameters);
		Process p = SubprocessHelpers.executePythonProcess(scriptPath, Arrays.copyOfRange(comm, 1, comm.length)); //scriptPath is derived from the first value in the command array
		try (BufferedWriter bw = new BufferedWriter(new OutputStreamWriter(p.getOutputStream()))) { //This closes the stream so that the process can continue
			JSONSystem.writeJSON(parameters, bw);
		}
		try {
			p.waitFor(); //Wait for the process to be done before attempting to read its output
			try (BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()))) {
				StringBuilder sb = new StringBuilder();
				br.lines().forEach(l -> sb.append(l).append("\n"));
				return sb.toString().trim();
			}
		}
		catch (InterruptedException e) {
			e.printStackTrace();
			return "";
		}
	}
}
