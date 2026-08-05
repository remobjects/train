---
title: Concepts
---

# Thinking in Train

Train is a JavaScript-based build system. If you're coming from other build systems (CMake, MSBuild, Gradle) or just know JavaScript, this guide will help you understand how Train works and how to approach writing Train scripts.

Train is high level. You can invoke other low-level build systems, like MSBuild, EBuild, CMake, etc. Train lets you do this, while also handling any other logic that is hard to express in those systems. For example, you can write Train scripts to handle uploading files to a download server, or to wrap multiple different builds with different environment variables for each. Anything that is a 'missing piece' in your build system can be done with Train.

## What Train Is

Train is designed for building apps. It provides APIs for:
- Running external programs ([shell.exec](API/Shell.md))
- File and directory operations ([File](API/File.md), [Folder](API/Folder.md))
- Build system integrations ([MSBuild](API/MSBuild.md), [Xcode](API/Xcode.md)), and we have [examples for using CMake](API/Shell.md)
- Working with zip archives, FTP, HTTP, email, SSH, XML files, .Net's GAC, ISO images, InnoSetup, and more.

Think of it as a dedicated build tool with a richer API and cross-platform support than the ones you might be using today.

## Coming from Other Build Systems

### From Make

**Make thinking:**
```makefile
build: clean compile link

clean:
    rm -rf build

compile:
    gcc -c src/*.c -o build/
```

**Train thinking:**
```javascript
function clean() {
  if (folder.exists("build")) {
    folder.remove("build", true);
  }
}

function compile() {
  folder.create("build");
  shell.exec("/usr/bin/gcc", "-c src/main.c -o build/main.o");
}

function build() {
  clean();
  compile();
}

build();
```

Key differences:
- Train uses **functions** instead of targets
- You explicitly **call functions in order** instead of relying on dependency graphs
  - You can use other build systems, like MSBuild or CMake: Train is high-level
- Cross-platform without platform-specific syntax

### From MSBuild/Gradle

**Build system thinking:** Declare tasks and dependencies, let the system figure out execution order.

**Train thinking:** Write procedural JavaScript where you want specific steps to occur. Things that can be delegated to another build system (such as file depenedencies) still are. You are writing the high-level series of steps.

```javascript
// Just write the steps in order
cleanDirectories();
configureCMake();
runBuild();
runTests();
packageArtifacts();
```

This is simpler for many build scenarios. You don't need to learn a DSL or declarative syntax - just write JavaScript.

### From Shell Scripts

Train is similar to shell scripts but with:
- **Cross-platform APIs** that work the same on Windows, macOS, and Linux
- **Structured error handling** (Train stops on errors by default)
- **Richer APIs** for common tasks (file operations, XML, archives, etc.)

And it is richer than shell scripts or Python because it has dedicated APIs for specific build-related systems.

**Shell script:**
```bash
#!/bin/bash
rm -rf build
mkdir -p build
cd build
cmake ..
make -j8
```

**Train:**
```javascript
if (folder.exists("build")) folder.remove("build", true);
folder.create("build");

shell.exec(CMAKE, "..", { workdir: "build" });
shell.exec(MAKE, "-j8", { workdir: "build" });
```

## Key Concepts

### Scripts Are Just JavaScript

Train scripts are JavaScript files. Write normal JavaScript. The only addition is Train's global APIs (shell, file, folder, etc.).

### Fail-Fast by Default

Train stops on the first error. If `shell.exec()` runs a command that exits with a non-zero code, your script stops immediately.

This is usually what you want for build scripts.

```javascript
shell.exec(CMAKE, "..", { workdir: "build" });  // If this fails, script stops
shell.exec(NINJA, "", { workdir: "build" });    // This never runs
```

If you need to handle errors, check return codes.

### No Implicit Dependencies

Unlike Make, Train doesn't track what's changed or what needs rebuilding. You write explicit logic.
Train is intended as a higher-level wrapper around a low-level build tool like msbuild or CMake.


### Working Directory

The `workdir` option in `shell.exec()` sets where that process runs (that process's current working directory).
It doesn't change your script's current directory.

```javascript
// Script is in /Users/work/project
shell.exec(CMAKE, "..", { workdir: "build" });  // CMake runs in ./build, ie /Users/work/project/build
// Script is still in /Users/work/project

// To change the script's directory, use shell.cd()
shell.cd("build");  // Now the script is 'in' /Users/work/project/build
```

See [Shell.md workdir](API/Shell.md#important-working-directory-vs-current-directory) for details.

### Environment Variables Merge

When you pass `environment` to `shell.exec()`, those variables **merge** with the current environment, not replace it.
This is extremely useful for adding environment variables because you don't need to track everything,
simply what you want to add / modify. The remainder are what the Train script itself ran with.

```javascript
var msvcEnv = { "PATH": "C:/MSVC/bin", "INCLUDE": "C:/MSVC/include" };
shell.exec("cl.exe", "test.c", { environment: msvcEnv });
// cl.exe sees the new PATH and INCLUDE, plus all existing env vars
```

This lets you capture environment setup from batch files (like vcvarsall.bat) and use it:

```javascript
// Run vcvarsall.bat, capture its environment
// for `captureEnvironment()` see 'Capturing Compiler Environments' below
var msvcEnv = captureEnvironment(cmdExe, '/c "vcvarsall.bat arm64 && set"');

// Now all commands run with MSVC environment
shell.exec("cmake", "-GNinja .", { environment: msvcEnv });
```

See [Shell Environment Merging](API/Shell.md#environment-merging) for examples.

## Common Patterns

### Capturing Tool Output

Use `capture: true` to get output as a string:

```javascript
var branch = shell.exec("/usr/bin/git", "rev-parse --abbrev-ref HEAD",
  { capture: true }).trim();
log("Building branch: " + branch);
```

For line-by-line processing, pass a function to `capture`:

```javascript
shell.exec("/usr/bin/clang", "main.c -o main", {
  capture: function(line) {
    log("clang: " + line);
  }
});
```

**Note**: When using `capture`, both stdout and stderr are combined in the returned output. Train handles them on separate streams internally. You'll see stderr prefixed with `(stderr)` in logs.

### Platform-Specific Logic

Check the platform with `env`:

```javascript
var isWindows = env["OS"] && env["OS"].indexOf("Windows") >= 0;
var isMac = !isWindows && file.exists("/usr/bin/sw_vers");

if (isWindows) {
  // Windows build steps
  shell.exec("msbuild", "Project.sln /p:Configuration=Release");
} else if (isMac) {
  // macOS build steps
  shell.exec("xcodebuild", "-configuration Release");
} else {
  // Linux build steps
  shell.exec("make", "all");
}
```

### Multi-Architecture Builds

Loop over architectures and build each one:

```javascript
var ARCHITECTURES = ["arm64", "x64", "x86"];

for (var i = 0; i < ARCHITECTURES.length; i++) {
  var arch = ARCHITECTURES[i];
  log("Building " + arch);

  var buildDir = "build_" + arch;
  folder.create(buildDir);

  var msvcEnv = captureVCVarsEnvironment(vcvarsall, arch);
  shell.exec(CMAKE, "..", { workdir: buildDir, environment: msvcEnv });
  shell.exec(NINJA, "", { workdir: buildDir, environment: msvcEnv });
}
```

### Building with MSBuild

Train has a dedicated API for building with MSBuild:

```javascript
// Simple rebuild
msbuild.rebuild("MyApp.sln", { configuration: "Release" });

// Build specific platform
msbuild.rebuild("CrossPlatform.sln", {
  configuration: "Release",
  platform: "x64"
});

// Update version before building
msbuild.updateAssemblyVersion("Source/Properties/AssemblyInfo.pas", "2.5.0.1000");
msbuild.rebuild("MyApp.sln", { configuration: "Release" });
```

See [MSBuild API](API/MSBuild.md) for all options.

### Building with EBuild

EBuild is our build system, which we strongly recommend for Elements. Train has a dedicated API for it.

```javascript
// Build Elements project
ebuild.build("MyApp.elements", "--configuration:Release");

// Rebuild from scratch
ebuild.rebuild("Library.elements", "--configuration:Release");

// Build with custom settings
ebuild.build("IslandApp.elements",
  "--configuration:Release --setting:Architecture=arm64");
```

See [EBuild API](API/EBuild.md) for all options.

### Building with Xcode

Train has a dedicated API for building macOS, iOS, tvOS, and watchOS projects with Xcode:

```javascript
// Build Xcode project
xcode.build("MyApp.xcodeproj", {
  target: "MyApp",
  configuration: "Release"
});

// Build for specific SDK
xcode.build("iOSApp.xcodeproj", {
  target: "iOSApp",
  configuration: "Release",
  sdk: "iphoneos"
});
```

See [Xcode API](API/Xcode.md) for all options.

### Building with CMake/Ninja

For projects using CMake, use `shell.exec()` to run the build tools:

```javascript
var buildDir = "build";
if (!folder.exists(buildDir)) folder.create(buildDir);

shell.exec(CMAKE, "-GNinja -DCMAKE_BUILD_TYPE=Release .", { workdir: buildDir });
shell.exec(NINJA, "", { workdir: buildDir });
```

See [Shell CMake Recipe](API/Shell.md#recipe-cmake-configure-and-build) for a complete example.

### Capturing Compiler Environments

Many toolchains (MSVC, RAD Studio) need environment setup from batch files, and you might be used
to running a special command prompt for your builds. With train there is no need; capture the environment
from one of those and use it for commands:

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

// Capture MSVC environment for ARM64
var cmdExe = env["COMSPEC"] || "C:/Windows/System32/cmd.exe";
var msvcEnv = captureEnvironment(cmdExe, '/c "vcvarsall.bat arm64 && set"');

// Use for all commands
shell.exec("cl.exe", "main.c", { environment: msvcEnv });
```

This means you can have one script that loops over multiple environments (say, the ARM64, x64, and crosscompile x32 command lines),
or different versions of Visual Studio. You do not need to try to run a build from inside multiple environments; instead
run one build script that runs commands with the appropriate environment.

See [Shell MSVC Recipe](API/Shell.md#recipe-msvc-command-tools-environment) and [Shell RAD Studio Recipe](API/Shell.md#recipe-rad-studio-environment).

### Finding Tools

Train doesn't search your system PATH when executing a command, so you need to provide paths to executables. See the [FAQ](FAQ.md#command-not-found-or-executable-not-found) for a `findTool()` implementation:

```javascript
var CMAKE = findTool("cmake");
if (CMAKE == null) error("CMake not found in PATH");
```

## Examples

### Simple C Project Build

```javascript
var CC = "/usr/bin/clang";
var sources = ["main.c", "utils.c"];
var output = "myapp";

// Compile each source file
for (var i = 0; i < sources.length; i++) {
  var src = sources[i];
  var obj = src.replace(".c", ".o");
  log("Compiling " + src);
  shell.exec(CC, "-c " + src + " -o " + obj);
}

// Link
log("Linking " + output);
var objs = sources.map(function(s) { return s.replace(".c", ".o"); }).join(" ");
shell.exec(CC, objs + " -o " + output);

log("Build complete: " + output);
```

### Cross-Platform CMake Build

Using our sample [findTool()](FAQ.md#command-not-found-or-executable-not-found) function:

```javascript
// Find tools using which/where (see findTool() function above)
var CMAKE = findTool("cmake");
if (CMAKE == null) error("CMake not found in PATH");

var NINJA = findTool("ninja");
if (NINJA == null) error("Ninja not found in PATH");

// Build
var buildDir = "build";
if (!folder.exists(buildDir)) folder.create(buildDir);

shell.exec(CMAKE, "-GNinja -DCMAKE_BUILD_TYPE=Release .", { workdir: buildDir });
shell.exec(NINJA, "", { workdir: buildDir });

log("Build complete - binaries in " + buildDir);
```

### Multi-Configuration Build (Windows, CMake)

This builds one C++ project for ARM64, x64, and x86, using the correct set of MSVC environment variables for each build.

```javascript
var cmdExe = env["COMSPEC"] || "C:/Windows/System32/cmd.exe";
var vcvarsall = "C:/Program Files/Microsoft Visual Studio/2022/Professional/VC/Auxiliary/Build/vcvarsall.bat";
var architectures = ["arm64", "x64", "x86"];

function captureVCVarsEnvironment(arch) {
  var envOutput = shell.exec(cmdExe,
    '/c ""' + vcvarsall + '" ' + arch + ' >nul && set"',
    { capture: true });

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

// Build each architecture
for (var i = 0; i < architectures.length; i++) {
  var arch = architectures[i];
  log("Building " + arch);

  var buildDir = "build_" + arch;
  folder.create(buildDir);

  var msvcEnv = captureVCVarsEnvironment(arch);
  shell.exec("cmake", "-GNinja ..", { workdir: buildDir, environment: msvcEnv });
  shell.exec("ninja", "", { workdir: buildDir, environment: msvcEnv });

  log(arch + " complete");
}

log("All builds complete");
```


## Common Patterns

### Clean Build Pattern

You can clean build directories to avoid stale artifacts:

```javascript
var buildDir = "./build";
var installDir = "./install";

if (folder.exists(buildDir)) {
  folder.remove(buildDir, true);
}
if (folder.exists(installDir)) {
  folder.remove(installDir, true);
}

folder.create(buildDir, true);
folder.create(installDir, true);
```

### Version Number Management

```javascript
// Read version from INI file
var iniFile = ini.fromFile("Versions.ini");
var version = iniFile.getValue("master", "Elements");    // "2.0.1.5000"

// Parse version components
var parts = version.split(".");
var major = parts[0];
var minor = parts[1];
var release = parts[2];
var build = parts[3];

// Update version in source files
var versionHeader = "#define VERSION \"" + version + "\"\n";
file.write("version.h", versionHeader);
```

### Template File Processing

```javascript
// Read template
var template = file.read("BuildInfo.inc.template");

// Replace placeholders
template = template.replace("%%VERSION%%", version);
template = template.replace("%%DATE%%", buildDate);
template = template.replace("%%COPYRIGHT%%", copyright);

// Write processed file
file.write("BuildInfo.inc", template);
```

### Building and Packaging

```javascript
// Build
msbuild.rebuild("MyApp.sln", { configuration: "Release" });

// Create distribution folder
folder.remove("./Distro", true);
folder.create("./Distro/MyApp", true);

// Copy files
file.copy("./Bin/Release/*.dll", "./Distro/MyApp/");
file.copy("./Bin/Release/*.exe", "./Distro/MyApp/");

// Create ZIP
var zipName = "MyApp-" + version + ".zip";
zip.compress(zipName, "./Distro", "*.*", true);

// Cleanup
folder.remove("./Distro", true);
```

### Multi-File Operations

```javascript
// Delete multiple files
function deleteFiles(pattern) {
  var items = file.list(pattern, true);
  for (var i = 0; i < items.length; i++) {
    file.remove(items[i]);
  }
}

// Usage
deleteFiles("*.dcu");
deleteFiles("**/*.pdb");
deleteFiles("./temp/**/*.obj");
```

### Conditional Execution (CI vs Local)

```javascript
var isLocal = env["CI"] ? false : true;

if (isLocal) {
  log("Running locally");
} else {
  log("Running in CI environment");
  // CI-specific operations
  uploadToWebsite();
}
```

## Next Steps

- Please read the [API documentation](API/index.md) for detailed references
- Start with a simple task and expand from there
- Join [the community](https://talk.remobjects.com/) for help and examples!
