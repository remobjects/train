---
title: File
---

Read, write, copy, and manage files. Train automatically handles path separators - use forward slashes (`/`) everywhere. Many functions support wildcards (`*`) for pattern matching.

## Quick Reference

* **file.read(filename, binary)** - Read a file and return content as string (or byte array if binary is true)
* **file.write(filename, data)** - Write content to a file
* **file.append(filename, data)** - Append content to a file
* **file.copy(sourceFileMask, destFileOrFolder, recurse, overwrite)** - Copy files or directories
* **file.move(sourceFileMask, destFileOrFolder)** - Move or rename files
* **file.remove(filename)** - Remove a file or files matching a pattern
* **file.exists(filename)** - Check if a file exists
* **file.list(pathandmask, recurse)** - List files matching a pattern
* **file.setAttributes(fileName, fileFlagsOptions)** - Set file attributes (Windows)

## Reading Files

### file.read(filename, [binary])

Reads a file and returns its contents as a string (or byte array if `binary` is true).

```javascript
// Read text file
var config = file.read("config.txt");
var lines = config.split("\n");

// Read JSON config
var jsonText = file.read("package.json");
var package = JSON.parse(jsonText);

// Read binary file (returns byte array)
var imageBytes = file.read("logo.png", true);
```

Variables like `$(buildDir)` are expanded automatically in paths.

## Writing Files

### file.write(filename, content)

Writes content to a file, creating it if it doesn't exist. Creates parent directories if needed.

```javascript
// Write text
file.write("output.txt", "Build complete\n");

// Write version header
var version = "1.0.0";
file.write("version.h", "#define VERSION \"" + version + "\"\n");

// Use variables in paths
export("buildDir", "./build");
file.write("$(buildDir)/output.log", "Log data");
```

### file.append(filename, content)

Appends content to the end of a file.

```javascript
// Add to log
file.append("build.log", "Step 1 complete\n");
file.append("build.log", "Step 2 complete\n");
```

## Copying and Moving

### file.copy(source, destination, [recurse], [overwrite])

Copies files or directories. Supports wildcards for copying multiple files.

**Parameters:**
- `source` - Source file path or pattern (supports `*` wildcards)
- `destination` - Destination file or folder
- `recurse` - If true, recurse into subdirectories (default: false)
- `overwrite` - If false, fail if destination exists (default: true)

```javascript
// Copy single file
file.copy("app.exe", "dist/app.exe");

// Copy with wildcards
file.copy("bin/*.dll", "output/");

// Copy all matching files recursively
file.copy("src/**/*.h", "include/", true);

// Don't overwrite existing files
file.copy("config.default.json", "config.json", false, false);

// Use variables
export("buildDir", "./build");
file.copy("$(buildDir)/*.exe", "dist/");
```

### file.move(source, destination, [delete])

Moves or renames files. Works like `file.copy()` but removes the source after copying.

```javascript
// Rename file
file.move("temp.dll", "final.dll");

// Move multiple files
file.move("temp/*.log", "logs/");

// Move with pattern
file.move("build/**/*.pdb", "symbols/", true);
```

## Deleting Files

### file.remove(filename)

Removes a file or files matching a pattern.

```javascript
// Remove single file
file.remove("temp.txt");

// Remove with wildcard
file.remove("build/*.obj");

// Remove all files in directory
file.remove("temp/*");

// Use variables
export("tempDir", "./temp");
file.remove("$(tempDir)/*");
```

To remove directories, use [folder.remove()](Folder.md#folderremove).

## Checking Existence

### file.exists(filename)

Returns true if the file exists, false otherwise.

```javascript
if (file.exists("config.json")) {
  var config = file.read("config.json");
} else {
  error("Configuration file not found!");
}

// Check before deleting
if (file.exists("old-build.log")) {
  file.remove("old-build.log");
}
```

## Listing Files

### file.list(pattern, [recurse])

Returns an array of file paths matching the pattern.

**Parameters:**
- `pattern` - File pattern with optional wildcards (`*` for any characters, `**` for recursive)
- `recurse` - If true, search subdirectories recursively (default: false)

```javascript
// List files in current directory
var csFiles = file.list("*.cs");

// Recursive search (method 1: ** wildcard)
var allCsFiles = file.list("**/*.cs");

// Recursive search (method 2: recurse parameter)
var allCsFiles = file.list("*.cs", true);

// List from absolute path
var files = file.list("/path/to/project/**/*.txt");

// Iterate over results
var sources = file.list("src/**/*.pas", true);
for (var i = 0; i < sources.length; i++) {
  log("Found: " + sources[i]);
}
```

Returns an array of strings (file paths). The array is empty if no files match.

## File Attributes

### file.setAttributes(filename, attributes)

Sets file attributes (Windows-specific).

**Parameters:**
- `filename` - Path to the file
- `attributes` - Object with boolean properties: `ReadOnly`, `Hidden`, `Archive`

```javascript
// Make file read-only
file.setAttributes("important.txt", { ReadOnly: true });

// Hide file
file.setAttributes("cache.dat", { Hidden: true });

// Set multiple attributes
file.setAttributes("backup.zip", {
  ReadOnly: true,
  Hidden: false,
  Archive: true
});
```

On non-Windows platforms, this function may have no effect or limited functionality.

## Examples

### Build Script: Copy Binaries

```javascript
export("buildDir", "./build/Release");
export("distDir", "./dist");

// Create distribution folder
folder.create("$(distDir)");

// Copy executables
file.copy("$(buildDir)/*.exe", "$(distDir)/");

// Copy libraries
file.copy("$(buildDir)/*.dll", "$(distDir)/");

// Copy config (don't overwrite if exists)
file.copy("config.default.json", "$(distDir)/config.json", false, false);

log("Distribution ready in $(distDir)");
```

### Generate Version File

```javascript
var version = env["VERSION"] || "1.0.0.0";
var commit = env["GIT_COMMIT"] || "unknown";

var versionFile = "#ifndef VERSION_H\n" +
                  "#define VERSION_H\n\n" +
                  "#define VERSION \"" + version + "\"\n" +
                  "#define COMMIT \"" + commit + "\"\n\n" +
                  "#endif\n";

file.write("src/version.h", versionFile);
log("Generated version.h");
```

### Clean Build Artifacts

```javascript
export("buildDir", "./build");

// Remove all object files
file.remove("$(buildDir)/**/*.obj");

// Remove all PDB files
file.remove("$(buildDir)/**/*.pdb");

// Remove all temporary files
file.remove("$(buildDir)/**/*.tmp");

log("Build artifacts cleaned");
```

See also [Folder](Folder.md) for directory operations.