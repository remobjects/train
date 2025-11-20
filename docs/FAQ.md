---
title: FAQ and Troubleshooting
---

Common issues and solutions when working with Train.

## Common Issues

### "Command not found" or "executable not found"

**Problem**: `shell.exec("cmake", ...)` fails with "command not found" even though cmake is installed.

**Cause**: Train doesn't search your system PATH. It looks for executables relative to the script directory.

**Solution**: Use `which` (Unix) or `where` (Windows) to find tools in PATH:

```javascript
// Cross-platform tool finder
function findTool(toolName) {
  var isWindows = env["OS"] && env["OS"].indexOf("Windows") >= 0;

  if (isWindows) {
    // Windows: use 'where' command
    var result = shell.exec("where", toolName, { capture: true, ignoreErrors: true });
    if (result) {
      var lines = result.split("\n");
      return lines[0].trim();  // Return first match
    }
  } else {
    // Unix: use 'which' command
    var result = shell.exec("/usr/bin/which", toolName, { capture: true, ignoreErrors: true });
    if (result) {
      return result.trim();
    }
  }
  return null;
}

// Use it
var CMAKE = findTool("cmake");
if (CMAKE == null) {
  error("CMake not found in PATH. Install with: brew install cmake (macOS) or apt install cmake (Linux)");
}
shell.exec(CMAKE, "-GNinja .");
```

Alternatively, check specific install locations:

```javascript
var NINJA = "/usr/local/bin/ninja";
if (!file.exists(NINJA)) NINJA = "/opt/homebrew/bin/ninja";
if (!file.exists(NINJA)) NINJA = "/usr/bin/ninja";
if (!file.exists(NINJA)) NINJA = "C:/Program Files/Ninja/ninja.exe";
if (!file.exists(NINJA)) error("Ninja not found");
```

See [Shell: PATH Resolution](API/Shell.md#path-resolution) for more details.

### EBuild fails on macOS/Linux but works on Windows

**Problem**: `shell.exec("ebuild", "Project.elements ...")` fails on macOS/Linux with "permission denied" or "exec format error".

**Cause**: On macOS/Linux, `/usr/local/bin/ebuild` is a shell script wrapper without a shebang line.

**Solution**: Always use the `ebuild` object instead of `shell.exec()`:

```javascript
// Wrong - fails on macOS/Linux
shell.exec("ebuild", "Project.elements --configuration:Release");

// Correct - works on all platforms
ebuild.build("Project.elements", "--configuration:Release");
```

The `ebuild` object automatically finds `EBuild.exe` and runs it.

See [EBuild Documentation](API/EBuild.md) for details.

### MSVC compiler not found on Windows

**Problem**: `shell.exec("cl.exe", ...)` fails even though Visual Studio is installed.

**Cause**: MSVC tools aren't in the PATH by default. You need to run vcvarsall.bat first to set up the environment.

**Solution**: Capture the MSVC environment from vcvarsall.bat and use it:

```javascript
function captureEnvironment(shellCmd, setupCmd) {
  var envOutput = shell.exec(shellCmd, setupCmd, { capture: true });
  var envDict = {};
  var lines = envOutput.split("\n");
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim();
    var eqPos = line.indexOf("=");
    if (eqPos > 0) {
      envDict[line.substring(0, eqPos)] = line.substring(eqPos + 1);
    }
  }
  return envDict;
}

var cmdExe = env["COMSPEC"] || "C:/Windows/System32/cmd.exe";
var vcvarsall = "C:/Program Files/Microsoft Visual Studio/2022/Professional/VC/Auxiliary/Build/vcvarsall.bat";

// Capture environment for ARM64
var msvcEnv = captureEnvironment(cmdExe, '/c ""' + vcvarsall + '" arm64 >nul && set"');

// Now use MSVC tools with this environment
shell.exec("cl.exe", "main.c", { environment: msvcEnv });
shell.exec("link.exe", "main.obj", { environment: msvcEnv });
```

See [Shell: MSVC Recipe](API/Shell.md#recipe-msvc-command-tools-environment).

### Delphi or C++Builder not found on Windows

This is the same as MSVC above: use Train's environment handling to automatically capture the environment that the RAD Studio Command Prompt
sets up, and then invoke tools using that environment.

See [Shell: RAD Studio Recipe](API/Shell.md#recipe-rad-studio-environment).


### Want to see full command output

**Problem**: Want to see or process the output from commands.

**Solution**: Use `capture: true` to get output as a string, or pass a function to process it line-by-line:

By default, Train truncates normal (non-error) output to keep console clean. Error output is always emitted whole.

To see full output in console during script execution, run with `--debug`:

```sh
$ train --debug my_build.train
```

#### Log command output

You can of course capture command output too:

```javascript
// Capture output as string
var output = shell.exec(CMAKE, "--version", { capture: true });
log("CMake version: " + output.trim());

// Process output line-by-line
shell.exec(NINJA, "", {
  capture: function(line) {
    log("Build output: " + line);
  }
});
```

### File not found but path looks correct

**Problem**: `file.exists("path/to/file")` returns false even though the file exists.

**Cause**:
1. Path is relative to script's current directory, not where the script file is located
2. Case sensitivity on macOS/Linux (Windows is case-insensitive)

**Solution**: Verify working directory:

```javascript
// Change to correct directory first
shell.cd("relative/path");
if (file.exists("file.txt")) {
  // ...
}

// Or use absolute path
log("Current directory: " + wd);
var absolutePath = path.combine(wd, "relative/path/to/file.txt");
if (file.exists(absolutePath)) {
  // ...
}

```

**Note**: Train normalizes path separators automatically - you can use forward slashes (`/`) everywhere and they'll be converted to backslashes on Windows.

## Best Practices

### Start with clean build directories

Remove build directories before building to avoid stale artifacts:

```javascript
var buildDir = "./build";
if (folder.exists(buildDir)) {
  folder.remove(buildDir, true);
}
folder.create(buildDir, true);
```

This prevents issues where old files cause confusing build errors. If you're using a low-level build tool like CMake or MSBuild, 
that tool may handle stale files and incremental builds for you. In general for CI we recommend entire, from-scratch builds though.
It's one of those things that seems unnecessary -- until there's that one bug where, had this occurred, it would have been solved
in a tenth of the time. We recommend all builds for CI are clean.

Local builds for incremental work make a lot more sense to not clean first.

### Use functions to organize build steps

Break scripts into clear functions for each major step:

```javascript
function findTools() {
  // Locate cmake, ninja, etc.
}

function configureBuild() {
  // Run cmake
}

function runBuild() {
  // Run ninja/make
}

function packageArtifacts() {
  // Create ZIP/installer
}

function main() {
  findTools();
  configureBuild();
  runBuild();
  packageArtifacts();
}

main();
```

This makes scripts easier to read, debug, and modify.

### Log progress clearly

Add log statements to show what's happening:

```javascript
log("Building for " + arch);
log("Configuring CMake");
shell.exec(CMAKE, "-GNinja .", { workdir: buildDir });

log("Running build");
shell.exec(NINJA, "", { workdir: buildDir });

log(arch + " build complete");
```

This helps diagnose issues and shows users progress during long builds.

### Debug via `--debug`

Train prints error messages in full. However, non-error messages are truncated in console output.
Using `--debug` prints everything, including normal / success output, in full. This can make your
output very long, so is off by default but can be useful when writing a script.

### Start simple

Don't try to replicate your entire build system in one script. Start with one task (like building one configuration) and expand.

### Read the API docs

Train has APIs for common tasks. Don't reinvent the wheel:
- [File operations](API/File.md) - read, write, copy, delete
- [Folder operations](API/Folder.md) - create, remove, list
- [Shell](API/Shell.md) - run programs, capture output
- [Zip](API/Zip.md) - create/extract archives
- [XML](API/XML.md) - parse and modify XML
- [HTTP](API/HTTP.md) - download files
- [MSBuild](API/MSBuild.md), [Xcode](API/Xcode.md) - IDE integrations

