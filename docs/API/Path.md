---
title: Path
---

Manipulate file paths in a cross-platform way. Train automatically handles path separators - use forward slashes (`/`) and they'll be converted to backslashes on Windows.

## Quick Reference

* **path.combine(part1, part2, ...)** - Combine path components with correct separator
* **path.getFileName(path)** - Get filename from full path
* **path.getFileNameWithoutExtension(path)** - Get filename without extension
* **path.getFileNameExtension(path)** - Get file extension (includes dot)
* **path.getFolderName(path)** - Get directory portion of path
* **path.resolve(relativePath, basePath)** - Resolve relative path against base
* **path.directorySeparator** - Get platform's directory separator (`/` or `\`)

## Combining Paths

### path.combine(part1, part2, ...)

Joins path components using the correct directory separator for the platform.

```javascript
// Combine two paths
var fullPath = path.combine("C:/Projects", "Build");
// Returns: C:/Projects/Build

// Combine multiple components
var sourcePath = path.combine("/usr", "local", "bin", "cmake");
// Returns: /usr/local/bin/cmake

// Use with variables
export("baseDir", "./output");
var distPath = path.combine(expand("$(baseDir)"), "release", "v1.0");
// Returns: ./output/release/v1.0

// Works with both slashes
var mixed = path.combine("C:/Projects", "src\\main.pas");
// Returns: C:/Projects/src/main.pas (normalized)
```

Platform-agnostic - use this instead of manually concatenating paths with `/` or `\`.

## Extracting Path Components

### path.getFileName(filePath)

Returns just the filename from a full path (the last component).

```javascript
var filename = path.getFileName("/usr/local/bin/cmake");
// Returns: cmake

var file = path.getFileName("C:/Projects/MyApp/app.exe");
// Returns: app.exe

// Works with just a filename
var name = path.getFileName("config.json");
// Returns: config.json
```

### path.getFileNameWithoutExtension(filePath)

Returns the filename without its directory or extension.

```javascript
var name = path.getFileNameWithoutExtension("C:/Code/MyApp/main.pas");
// Returns: main

var basename = path.getFileNameWithoutExtension("/usr/bin/cmake");
// Returns: cmake

// Multiple extensions - removes last one only
var name = path.getFileNameWithoutExtension("archive.tar.gz");
// Returns: archive.tar
```

### path.getFileNameExtension(filePath)

Returns the file extension including the dot.

```javascript
var ext = path.getFileNameExtension("app.exe");
// Returns: .exe

var ext = path.getFileNameExtension("/path/to/config.json");
// Returns: .json

// No extension returns empty string
var none = path.getFileNameExtension("README");
// Returns: ""

// Multiple dots - returns last extension
var ext = path.getFileNameExtension("archive.tar.gz");
// Returns: .gz
```

### path.getFolderName(filePath)

Returns the directory portion of a path (everything except the filename).

```javascript
var dir = path.getFolderName("/usr/local/bin/tool");
// Returns: /usr/local/bin

var folder = path.getFolderName("C:/Projects/App/main.exe");
// Returns: C:/Projects/App

// Just a filename returns empty string
var empty = path.getFolderName("file.txt");
// Returns: ""
```

## Path Resolution

### path.resolve(relativePath, [basePath])

Resolves a relative path against a base path (or current directory if not specified).

```javascript
// Resolve against current directory
var absolute = path.resolve("./build");

// Resolve against specific base
var fullPath = path.resolve("../lib", "/usr/local/bin");
// Returns: /usr/local/lib

// Use with variables
export("projectRoot", "/path/to/project");
var buildPath = path.resolve("build/Release", expand("$(projectRoot)"));
```

## Platform Information

### path.directorySeparator

Returns the platform's directory separator character.

```javascript
var sep = path.directorySeparator;
// Returns: "/" on macOS/Linux
// Returns: "\" on Windows

// Use for manual path construction (though path.combine() is better)
var manualPath = "usr" + path.directorySeparator + "local";
```

In most cases, use [path.combine()](#pathcombinepart1-part2-) instead - it's clearer and cross-platform.

## Examples

### Parse File Path

```javascript
var filePath = "/Users/work/Projects/MyApp/src/main.pas";

var directory = path.getFolderName(filePath);
// "/Users/work/Projects/MyApp/src"

var filename = path.getFileName(filePath);
// "main.pas"

var basename = path.getFileNameWithoutExtension(filePath);
// "main"

var extension = path.getFileNameExtension(filePath);
// ".pas"

log("File: " + basename + extension + " in " + directory);
```

### Build Output Paths

```javascript
export("buildDir", "./build");
export("configuration", "Release");
export("platform", "x64");

// Combine to create output path
var outputPath = path.combine(
  expand("$(buildDir)"),
  expand("$(configuration)"),
  expand("$(platform)")
);
// Returns: ./build/Release/x64

// Create bin directory within output
var binPath = path.combine(outputPath, "bin");

// Construct output file path
var exePath = path.combine(binPath, "MyApp.exe");
```

### Process All Files of Type

```javascript
var sources = file.list("src/**/*.pas", true);

for (var i = 0; i < sources.length; i++) {
  var sourcePath = sources[i];
  var filename = path.getFileName(sourcePath);
  var basename = path.getFileNameWithoutExtension(sourcePath);

  // Construct output object file path
  var objectFile = path.combine("obj", basename + ".o");

  log("Compiling " + filename + " -> " + objectFile);
  shell.exec("/usr/bin/fpc", sourcePath + " -o" + objectFile);
}
```

### Copy with Directory Structure

```javascript
export("sourceDir", "./src");
export("outputDir", "./dist");

var files = file.list("$(sourceDir)/**/*.dll", true);

for (var i = 0; i < files.length; i++) {
  var sourceFile = files[i];
  var filename = path.getFileName(sourceFile);

  // Preserve directory structure
  var relativeDir = path.getFolderName(sourceFile).replace(expand("$(sourceDir)"), "");
  var destDir = path.combine(expand("$(outputDir)"), relativeDir);

  folder.create(destDir);
  file.copy(sourceFile, path.combine(destDir, filename));
}
```

See also [File](File.md) for file operations and [Folder](Folder.md) for directory operations.