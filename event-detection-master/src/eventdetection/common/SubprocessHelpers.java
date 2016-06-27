package eventdetection.common;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.ProcessBuilder.Redirect;
import java.net.URISyntaxException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;

/**
 * Provides useful methods for working with subprocesses.
 * 
 * @author Joshua Lipstone
 */
public class SubprocessHelpers {
	/**
	 * The path required to run the system's bash executable.
	 */
	public static final String bashPath = getBashPath();
	/**
	 * The path required to run the system's Python 3 executable.
	 */
	public static final String pythonPath = getPythonPath();
	/**
	 * The default execution directory used when calling {@link #executePythonProcess(Path, String...)}
	 */
	public static final Path DEFAULT_PATH;
	
	static {
		Path temp = null;
		try {
			temp = Paths.get(SubprocessHelpers.class.getProtectionDomain().getCodeSource().getLocation().toURI()).getParent();
		}
		catch (URISyntaxException e) {
			e.printStackTrace();
		}
		DEFAULT_PATH = temp;
	}
	
	private SubprocessHelpers() {/* This is a static class */}
	
	private static final String getBashPath() { //This defaults to running from .sh
		ProcessBuilder pb = new ProcessBuilder();
		pb.command("which", "bash");
		try {
			Process p = pb.start();
			try (BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()))) {
				p.waitFor();
				return reader.readLine().trim();
			}
		}
		catch (IOException | InterruptedException e) {
			e.printStackTrace();
		}
		return "/bin/bash";
	}
	
	private static final String getPythonPath() {
		ProcessBuilder pb = new ProcessBuilder();
		//python 2 outputs its version information to stderr.  Not kidding.
		pb.command(bashPath, "-l", "-c", "[ \"$(python --version 2>&1 | grep 'Python 3')\" != \"\" ] && echo \"$(which python)\" || echo \"$(which python3)\"");
		try {
			Process p = pb.start();
			try (BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()))) {
				p.waitFor();
				return reader.readLine().trim();
			}
		}
		catch (IOException | InterruptedException e) {
			e.printStackTrace();
		}
		return "python3";
	}
	
	/**
	 * Executes a python script with the given arguments
	 * 
	 * @param scriptPath
	 *            the {@link Path} to the script.
	 * @param args
	 *            the arguments to the script. Arguments that include spaces must be quoted
	 * @return a started {@link Process}
	 * @throws IOException
	 *             if an error occurs while starting the process
	 */
	public static Process executePythonProcess(Path scriptPath, String... args) throws IOException {
		return executePythonProcess(scriptPath, DEFAULT_PATH, args);
	}
	
	/**
	 * Executes a python script with the given arguments
	 * 
	 * @param scriptPath
	 *            the {@link Path} to the script.
	 * @param directory
	 *            a {@link Path} to the directory from which to run the script
	 * @param args
	 *            the arguments to the script. Arguments that include spaces must be quoted
	 * @return a started {@link Process}
	 * @throws IOException
	 *             if an error occurs while starting the process
	 */
	public static Process executePythonProcess(Path scriptPath, Path directory, String... args) throws IOException {
		Path relPath;
		try {
			relPath = directory.relativize(scriptPath);
		}
		catch (IllegalArgumentException e) {
			relPath = scriptPath;
		}
		String[] command = {bashPath, "-c", pythonPath.toString() + " \"$@\"", "-", relPath.normalize().toString()};
		command = Arrays.copyOf(command, command.length + args.length);
		for (int i = 0; i < args.length; i++) //The command has 5 components that come before the arguments
			command[i + 5] = args[i];
		
		ProcessBuilder pb = new ProcessBuilder(command);
		pb.redirectError(Redirect.INHERIT); //So that errors can be seen
		pb.directory(directory.toFile());
		return pb.start();
	}
}
