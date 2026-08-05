---
title: Shell
---

Execute external programs, change directories, and manage environment variables.

## Quick Reference

* **shell.exec(path, args, options)** - Run external program and wait for completion
* **shell.cd(path)** - Change current working directory
* **shell.cd(path, function)** - Temporarily change directory for a function
* **shell.which(toolName)** - Find executable in PATH (Unix/macOS)
* **shell.where(toolName)** - Find executable in PATH (Windows)

## shell.cd(path)

Changes the script's current working directory. Affects relative paths used in [File](File.md) and [Folder](Folder.md) operations, and the default `workdir` for `shell.exec()`.

```javascript
shell.cd("/path/to/project");
// Now relative paths are relative to /path/to/project
```

To return to the original directory:
```javascript
shell.cd(env["scriptpath"]);  // Back to script's directory
```

## shell.cd(path, function)

Temporarily changes directory, runs the function, then returns to the original directory:

```javascript
shell.cd("/path/to/project", function() {
  // Do work in /path/to/project
  shell.exec("make", "all");
});
// Automatically back to original directory
```

## shell.exec(path, args, options)

Runs an external program and waits for it to complete.

**Parameters:**
- `path` - Path to the executable (see PATH Resolution below)
- `args` - Command-line arguments as a string
- `options` - Optional configuration object

**Options:**
- `workdir` - Working directory for this command only. This sets the current directory for the launched process, not for your script. If not specified, the process inherits the script's current directory (set via `shell.cd()` or the directory where Train started).
- `timeout` - Timeout in seconds. Negative means start the process but don't wait for it
- `capture` - Set to `true` to return output as a string, or pass a function to receive output line-by-line as it's produced
- `environment` - Dictionary of environment variables to merge with the current environment. Structure is `{ "VAR_NAME": "value", "PATH": "new/path" }`. These merge with (not replace) existing variables, so you can override specific settings while keeping everything else. See [Environment Merging](#environment-merging) below.

**Important: Working Directory vs Current Directory**

The `workdir` option sets the working directory for the launched process only. It doesn't change your script's current directory. Think of it like running `cd /some/dir && command` - the command runs there, but your shell stays where it was.

```javascript
// Script starts in /Users/work/myproject
log(folder.current);  // /Users/work/myproject

// Run cmake in build directory
shell.exec("/usr/local/bin/cmake", "..", { workdir: "build" });

// Script is still in /Users/work/myproject
log(folder.current);  // /Users/work/myproject

// To change the script's cwd, use shell.cd() instead
shell.cd("build");
log(folder.current);  // /Users/work/myproject/build
```

**PATH Resolution**

Train doesn't search the system PATH when you pass a bare executable name. If you run `shell.exec("cmake", ...)`, Train looks for `cmake` relative to your script directory, not in your system PATH. This causes "file not found" errors even when the tool is installed and in PATH.

To fix this, check common install locations and use absolute paths:

```javascript
// Find CMake in common locations
var CMAKE = "/usr/local/bin/cmake";
if (!file.exists(CMAKE)) CMAKE = "/opt/homebrew/bin/cmake";
if (!file.exists(CMAKE)) CMAKE = "/usr/bin/cmake";
if (!file.exists(CMAKE)) error("CMake not found");

// Now use it
shell.exec(CMAKE, "-GNinja .", { workdir: buildDir });
```

On Windows, you can use the COMSPEC environment variable to get cmd.exe's absolute path, then use it to search:

```javascript
var cmdExe = env["COMSPEC"] || "C:/Windows/System32/cmd.exe";
var whereOutput = shell.exec(cmdExe, '/c where cmake', { capture: true });
var cmakePath = whereOutput.trim().split("\n")[0];  // First result
```

**Examples**

```javascript
// Run CMake to configure a build
shell.exec("/usr/local/bin/cmake", "-GNinja -DCMAKE_BUILD_TYPE=Release .",
  { workdir: "/path/to/build" });

// Run Ninja to build
shell.exec("/usr/local/bin/ninja", "", { workdir: "/path/to/build" });

// Capture git output
var branch = shell.exec("/usr/bin/git", "rev-parse --abbrev-ref HEAD",
  { capture: true }).trim();
log("Current branch: " + branch);

// Run Windows dir command
var cmdExe = env["COMSPEC"] || "C:/Windows/System32/cmd.exe";
var listing = shell.exec(cmdExe, '/c dir /b C:\\Projects', { capture: true });
log("Files: " + listing);

// Stream compiler output line-by-line
shell.exec("/usr/bin/clang", "main.c -o main", {
  capture: function(line) {
    log("clang: " + line);
  }
});
```

**Environment Merging**

The `environment` option merges variables with the current environment instead of replacing it. If you pass `{ "PATH": "/new/path", "CC": "clang" }`, Train sets those two variables but keeps everything else (HOME, USER, etc.) from the current environment.

This is useful when you need environment setup from external scripts that configure compiler toolchains. The examples below use this helper to capture environment from batch files or shell scripts:

```javascript
// Helper: Capture environment after running a command
function captureEnvironment(shellCmd, setupCmd) {
  var envOutput = shell.exec(shellCmd, setupCmd, { capture: true });

  var envDict = {};
  var lines = envOutput.split("\n");
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim();
    if (line == "") continue;
    var eqPos = line.indexOf("=");
    if (eqPos > 0) {
      envDict[line.substring(0, eqPos)] = line.substring(eqPos + 1);
    }
  }
  return envDict;
}
```

Now you can capture any environment setup:

```javascript
// macOS/Linux: Source a shell script and capture its environment
var customEnv = captureEnvironment("/bin/bash", '-c "source /opt/setup.sh && env"');

// Windows: Run batch file and capture environment
var cmdExe = env["COMSPEC"] || "C:/Windows/System32/cmd.exe";
var msvcEnv = captureEnvironment(cmdExe, '/c "C:/path/to/setup.bat >nul && set"');

// Use captured environment for all build commands
shell.exec("/usr/local/bin/cmake", "-GNinja .", { environment: customEnv });
shell.exec("/usr/local/bin/ninja", "", { environment: customEnv });
```

**Recipes**

**Recipe: MSVC Command Tools Environment**

Run commands with the MSVC compiler toolchain environment (cl.exe, link.exe, lib.exe, etc.) without needing a Visual Studio Developer Command Prompt. Uses the `captureEnvironment()` helper shown above.

```javascript
var cmdExe = env["COMSPEC"] || "C:/Windows/System32/cmd.exe";
var vcvarsall = "C:/Program Files/Microsoft Visual Studio/2022/Professional/VC/Auxiliary/Build/vcvarsall.bat";
var arch = "arm64";  // or "x64" or "x86"

var msvcEnv = captureEnvironment(cmdExe,
  '/c ""' + vcvarsall + '" ' + arch + ' >nul && set"');

// All commands now run with MSVC environment
shell.exec("cmake", "-GNinja .", { environment: msvcEnv });
shell.exec("ninja", "", { environment: msvcEnv });
shell.exec("cl.exe", "test.c", { environment: msvcEnv });
```

**Recipe: RAD Studio Environment**

Run commands with the RAD Studio (Delphi/C++Builder) toolchain environment. Uses the `captureEnvironment()` helper shown above.

```javascript
var cmdExe = env["COMSPEC"] || "C:/Windows/System32/cmd.exe";
var rsvars = "C:/Program Files (x86)/Embarcadero/Studio/23.0/bin/rsvars.bat";

var radEnv = captureEnvironment(cmdExe, '/c ""' + rsvars + '" >nul && set"');

shell.exec("msbuild", "MyProject.dproj /t:Build", { environment: radEnv });
```

See also [MSBuild](MSBuild.md) for more RAD Studio and Visual Studio build examples.

**Recipe: CMake Configure and Build**

```javascript
var CMAKE = "/usr/local/bin/cmake";  // or your install location
var NINJA = "/usr/local/bin/ninja";  // or your install location

if (!file.exists(CMAKE)) error("CMake not found at " + CMAKE);
if (!file.exists(NINJA)) error("Ninja not found at " + NINJA);

var buildDir = "build";
var sourceDir = ".";

// Create build directory
if (!folder.exists(buildDir)) {
  folder.create(buildDir);
}

// Configure (workdir sets where cmake runs, not script cwd)
shell.exec(CMAKE,
  "-GNinja " +
  "-DCMAKE_BUILD_TYPE=Release " +
  "-DCMAKE_INSTALL_PREFIX=/usr/local " +
  sourceDir,
  { workdir: buildDir });

// Build (workdir is the build directory)
shell.exec(NINJA, "", { workdir: buildDir });

// Install
shell.exec(NINJA, "install", { workdir: buildDir });
```

See also [Folder](Folder.md) for directory operations.

## shell.execAsync(path, args, options)

Same as `shell.exec()` but returns immediately with a task object. Does not support the `capture` option.

```javascript
var task = shell.execAsync("/usr/local/bin/ninja", "", { workdir: "build" });
// Do other work while ninja runs
shell.kill(task);  // Stop it if needed
```

## shell.system(command, workDir)

Executes a command through the system shell (cmd.exe on Windows, /bin/sh on Unix). Returns output as a string.

```javascript
// Run shell commands with pipes, redirection, etc.
var result = shell.system("ls -la | grep .js", "/path/to/search");
```

## shell.kill(task)

Terminates a process started with `shell.execAsync()`.

```javascript
var task = shell.execAsync("/usr/bin/longrunning", "");
// Later...
shell.kill(task);
```