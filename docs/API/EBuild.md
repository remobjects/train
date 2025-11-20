---
title: EBuild
---

Build RemObjects Elements projects using EBuild. Elements is a multi-platform compiler that targets .NET, Java, Cocoa, Island (native), and WebAssembly.

## Quick Reference

* **ebuild.build(project, args)** - Build a project
* **ebuild.rebuild(project, args)** - Clean rebuild
* **ebuild.clean(project, args)** - Clean build outputs
* **ebuild.exec(args)** - Run EBuild with custom arguments

## ⚠️ Critical: Always Use the ebuild Object

**NEVER use `shell.exec("ebuild", ...)` - it will fail on macOS/Linux.**

On macOS and Linux, `/usr/local/bin/ebuild` is a shell script wrapper without a shebang:
```bash
mono "/Library/Application Support/RemObjects Software/EBuild/EBuild.exe" "$@"
```

If you try to execute this with `shell.exec("ebuild", ...)`, the OS can't run it directly because there's no shebang line.

The `ebuild` object solves this automatically:
1. On macOS/Linux: Reads the wrapper script, extracts the real `EBuild.exe` path, and runs it with `mono`
2. On Windows: Finds `EBuild.exe` via registry keys and runs it directly

Always use the `ebuild` object methods instead.

## High-Level Methods (Recommended)

These methods automatically add the correct flags for common operations.

### ebuild.build(project, [args])

Builds a project (adds `--build` flag automatically).

```javascript
// Simple build
ebuild.build("MyApp.elements", "--configuration:Release");

// Build solution
ebuild.build("Solution.sln", "--configuration:Debug");

// Island project with architecture
ebuild.build("IslandApp.elements",
  "--configuration:Release --setting:Architecture=arm64");

// Build with custom output directory
ebuild.build("Library.elements",
  "--configuration:Release --out:./Bin/arm64");
```

### ebuild.rebuild(project, [args])

Rebuilds a project from scratch (adds `--rebuild --no-cache` flags automatically).

```javascript
// Clean rebuild for release
ebuild.rebuild("Project.elements", "--configuration:Release");

// Rebuild with custom settings
ebuild.rebuild("LibraryImport.elements",
  "--configuration:Release --setting:ImportSearchPaths=/custom/path");
```

Use `rebuild()` for CI builds and release builds to ensure everything is built fresh. Use `build()` for faster incremental development builds.

### ebuild.clean(project, [args])

Cleans build outputs (adds `--clean` flag automatically).

```javascript
// Clean project
ebuild.clean("Project.elements", "");

// Clean specific configuration
ebuild.clean("Project.elements", "--configuration:Release");
```

## Low-Level Methods (Advanced)

For advanced scenarios where you need full control over flags.

### ebuild.runEBuild(project, args)

Runs EBuild using the auto-detected `EBuild.exe` path. You must provide all flags yourself.

```javascript
// Full control over flags
ebuild.runEBuild("Project.elements", "--rebuild --configuration:Release");
```

### ebuild.runCustomEBuild(ebuildPath, project, args)

Runs a specific EBuild executable. Useful for testing beta versions or custom builds.

```javascript
// Use custom EBuild version
ebuild.runCustomEBuild(
  "/path/to/EBuild.exe",
  "Project.sln",
  '--rebuild --configuration:Release --out:./Bin --setting:IslandSDKFolder="C:/SDKs"'
);
```

## Common Settings

EBuild settings are passed with `--setting:Name=Value` syntax. Common settings include:

**Architecture** - Target CPU architecture
- Values: `x86`, `x64`, `arm64`, `x86_64`
- Island projects only

**ImportSearchPaths** - Paths to search for imported libraries
- Semicolon-separated list of directories
- Used by Library Import projects (.fx references)

**IslandSDKFolder** - Custom Island SDK location
- Override default SDK path

**ToffeeSDK** - macOS/iOS SDK version
- E.g., `--setting:ToffeeSDK=14.0`

**DefineConstants** - Conditional compilation symbols
- Semicolon-separated list

```javascript
// Multiple settings
var settings = [
  "--configuration:Release",
  "--setting:Architecture=arm64",
  '--setting:ImportSearchPaths="./install/lib;/usr/local/lib"',
  "--setting:DefineConstants=RELEASE;OPTIMIZED",
  "--out:./Bin"
].join(" ");

ebuild.rebuild("IslandApp.elements", settings);
```

## Examples

### Build Multiple Architectures

```javascript
var architectures = ["x86", "x64", "arm64"];

for (var i = 0; i < architectures.length; i++) {
  var arch = architectures[i];
  log("Building " + arch + "...");

  ebuild.rebuild("NativeLib.elements",
    "--configuration:Release --setting:Architecture=" + arch +
    " --out:./Bin/" + arch);
}

log("All architectures built successfully");
```

### Library Import Project

Library Import projects create Pascal wrappers for native C libraries by reading header files and .a/.lib files.

```javascript
// Build macOS import library
function buildMacOSImport(arch) {
  var project = "sleef-macos-" + arch + ".elements";
  log("Building " + project + "...");

  // Path to the native .a file
  var libPath = "./install_macos_" + arch + "/lib";

  ebuild.build(project,
    "--configuration:Release --setting:ImportSearchPaths=" + libPath);

  log("Generated Pascal wrapper in Bin/Release/macOS/" + arch + "/");
}

buildMacOSImport("arm64");
buildMacOSImport("x86_64");
```

The import project generates `.fx` and `.pas` files that can be referenced by other Elements projects.

### CI Build with Version

```javascript
// Get version from environment
var version = env["CI_VERSION"] || "1.0.0.0";
var configuration = env["CI_CONFIGURATION"] || "Release";

log("Building version " + version + " (" + configuration + ")");

// Clean and rebuild
ebuild.clean("Application.sln", "");
ebuild.rebuild("Application.sln",
  "--configuration:" + configuration +
  " --setting:Version=" + version);
```

### Cross-Platform Island Build

```javascript
// Build for multiple platforms and architectures
var platforms = [
  { os: "Windows", arch: "x64" },
  { os: "Windows", arch: "arm64" },
  { os: "Linux", arch: "x64" },
  { os: "macOS", arch: "arm64" }
];

for (var i = 0; i < platforms.length; i++) {
  var p = platforms[i];
  log("Building " + p.os + " " + p.arch);

  var outDir = "./Bin/" + p.os + "/" + p.arch;

  ebuild.build("IslandApp.elements",
    "--configuration:Release" +
    " --setting:OS=" + p.os +
    " --setting:Architecture=" + p.arch +
    " --out:" + outDir);
}
```

## Why NOT to Use shell.exec

```javascript
// ❌ WRONG - Will fail on macOS/Linux
shell.exec("ebuild", "Project.elements --configuration:Release");
// Error: /usr/local/bin/ebuild is not executable (no shebang)

shell.exec("/usr/local/bin/ebuild", "Project.elements --configuration:Release");
// Error: Same problem - can't execute shell script without shebang

// ✅ CORRECT - ebuild object handles everything
ebuild.build("Project.elements", "--configuration:Release");
// Works everywhere! Finds EBuild.exe and runs it properly
```

## Related Documentation

- [MSBuild](MSBuild.md) - Building .NET projects with MSBuild
- [Xcode](Xcode.md) - Building macOS/iOS projects with Xcode
- [Shell](Shell.md) - Running external build tools
- [Concepts](../Concepts.md) - Understanding Train build scripts

See the [Elements documentation](https://docs.elementscompiler.com) for more on Elements compiler and project types.
