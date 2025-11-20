---
title: Globals
---

Train provides these global variables and functions in every script.

## Quick Reference

* **env** - Dictionary of environment variables
* **wd** - Current working directory
* **export(key, value)** - Define a variable for `$(varName)` expansion
* **expand(value)** - Manually expand `$(varName)` syntax in a string
* **include(scriptPath)** - Include another script (makes its content available)
* **run(scriptPath)** - Run another script as separate execution
* **runAsync(scriptPath)** - Run another script asynchronously
* **log(message)** - Print a message to console
* **error(message)** - Print error and terminate script
* **sleep(milliseconds)** - Pause script execution
* **ignoreErrors(function)** - Run function and catch any errors
* **retry(count, function)** - Retry function up to count times
* **async(function)** - Run function in background thread
* **waitFor(tasksArray, timeout)** - Wait for async tasks to complete

## Environment Variables

### env

Dictionary of environment variables from the parent process.

```javascript
// Read environment variables
var path = env["PATH"];
var user = env["USER"];  // Unix
var username = env["USERNAME"];  // Windows

// Check if variable exists
if (env["CI"]) {
  log("Running in CI environment");
}

// Common CI environment variables
var branch = env["CIBranch"];
var commit = env["CICommitHash"];
```

Environment variables are read-only through `env`. To set variables for child processes, use the `environment` option in [shell.exec()](Shell.md#environment-merging).

### wd

The current working directory as a string. This is the directory Train started in or was changed to via [shell.cd()](Shell.md#shellcdpath).

```javascript
log("Working directory: " + wd);
```

To change the working directory, use [shell.cd()](Shell.md).

## Variable Expansion

### export(key, value)

Defines a variable that can be referenced using `$(varName)` syntax throughout your script. These variables are expanded in paths, strings, and many Train functions.

```javascript
// Define variables
export("buildDir", "./build");
export("version", "1.0.0");
export("outputPath", "$(buildDir)/release");  // Can reference other variables

// Variables are expanded automatically in many contexts
file.copy("$(buildDir)/app.exe", "dist/");
folder.create("$(outputPath)");

// Nested expansion works
var fullPath = "$(outputPath)/v$(version)";  // Expands to "./build/release/v1.0.0"
```

Variables defined with `export()` persist across included scripts and are available to child scripts run with `run()`.

### expand(value)

Manually expands `$(varName)` or `$varName` syntax in a string. Use this when you need explicit control over expansion or when working with plain JavaScript strings.

```javascript
export("baseFolder", "/Users/work");
export("projectPath", "$(baseFolder)/Code/MyProject");

// Explicit expansion
var path = expand("$(projectPath)/bin");
log(path);  // "/Users/work/Code/MyProject/bin"

// Multiple variables
var fullPath = expand("$(projectPath)/v$(version)/output.dll");

// Escape $ with $$
var literal = expand("Price is $$5");  // "Price is $5"
```

Some Train functions auto-expand `$(var)` syntax, while others don't. When in doubt, use `expand()` explicitly.

**Built-in variables:**
- `$(scriptpath)` - Directory containing the current script

See [Concepts](../Concepts.md) for more on variable expansion.

## Script Inclusion

### include(scriptPath)

Includes another Train script, making its functions and variables available in the current script. Similar to `#include` in C or `source` in bash.

```javascript
// Include relative to current script
include("./shared-functions.train");

// Include using variables
export("libPath", "/path/to/scripts");
include("$(libPath)/utilities.train");

// Include from parent directory
include("../common/build-helpers.train");
```

Included scripts are processed at parse time, so all their content becomes part of your script. Variables defined with `export()` in included scripts are available immediately.

See also [Concepts: Script Modularity](../Concepts.md).

### run(scriptPath)

Runs another Train script as a separate execution (like calling a subprocess). Variables and functions from the run script are not available to the calling script.

```javascript
// Run a build script
run("./compile-native.train");

// Run with variables passed via export
export("TARGET_ARCH", "arm64");
run("./build-arch.train");  // Can access TARGET_ARCH via env["TARGET_ARCH"]
```

Use `run()` when you want to isolate script execution. Use `include()` when you want to share code.

### runAsync(scriptPath)

Same as `run()` but returns immediately with a task object. The script runs in parallel.

```javascript
var task1 = runAsync("./build-windows.train");
var task2 = runAsync("./build-macos.train");

// Wait for both to complete
waitFor([task1, task2]);
```

See [waitFor()](#waitfortasksarray-timeout) below.

## Logging

### log(message)

Prints a message to the console. Variables in the message are expanded automatically.

```javascript
log("Build started");
log("Version: " + version);

export("buildDir", "./build");
log("Output directory: $(buildDir)");  // Auto-expands to "./build"
```

### error(message)

Prints an error message and terminates the script immediately with a non-zero exit code.

```javascript
if (!file.exists("config.json")) {
  error("Configuration file not found!");
}

// Script stops here if error is called
log("This won't print if error was called");
```

Use `error()` when you encounter an unrecoverable problem. Train's fail-fast approach means builds stop at the first error.

## Utility Functions

### sleep(milliseconds)

Pauses script execution for the specified number of milliseconds.

```javascript
log("Waiting for service to start...");
sleep(5000);  // Wait 5 seconds
log("Continuing");
```

### ignoreErrors(function)

Runs the provided function and catches any errors, allowing the script to continue.

```javascript
// Delete a file that might not exist
ignoreErrors(function() {
  file.remove("temp.txt");
});

// Continue even if removal failed
log("Continuing build");
```

Use sparingly - Train's default fail-fast behavior is usually better for build scripts.

### retry(count, function)

Runs the provided function up to `count` times until it succeeds. Useful for flaky operations like network requests.

```javascript
// Retry download up to 3 times
retry(3, function() {
  http.download("https://example.com/large-file.zip", "downloads/");
});
```

If the function fails on all attempts, the error propagates and stops the script.

## Async Operations

### async(function)

Runs the provided function in a background thread and returns a task object immediately. The main script continues while the function executes.

```javascript
var task = async(function() {
  // This runs in background
  shell.exec("/usr/bin/make", "all");
});

// Do other work while make runs
log("Build started in background");

// Wait for completion
waitFor([task]);
```

### waitFor(tasksArray, [timeout])

Waits for all tasks in the array to complete. Throws any exceptions that occurred in the async tasks.

```javascript
var task1 = runAsync("./build-component-a.train");
var task2 = runAsync("./build-component-b.train");

// Wait for both (infinite timeout)
waitFor([task1, task2]);

// Wait with 60 second timeout
waitFor([task1, task2], 60000);
```

If any task throws an exception, `waitFor()` re-throws it, stopping your script.

See [Concepts: Multi-Architecture Builds](../Concepts.md) for examples of parallel builds with async.