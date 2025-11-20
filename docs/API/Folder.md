---
title: Folder
---

Create, remove, and manage folders. Train automatically handles path separators - use forward slashes (`/`) everywhere and they'll be converted to backslashes (`\`) on Windows.

## Quick Reference

* **folder.create(foldername, recursive)** - Create a folder (recursively if needed)
* **folder.exists(filename)** - Check if a folder exists
* **folder.remove(foldername, recurse)** - Remove a folder
* **folder.move(sourcePath, destPath)** - Move or rename a folder
* **folder.list(pathandmask, recurse)** - List folders matching a pattern
* **folder.setAttributes(folderName, recurse, fileFlagsOptions)** - Set attributes on files in folder (Windows)

## Creating Directories

### folder.create(path, [recursive])

Creates a directory. If the directory already exists, does nothing (no error).

```javascript
// Create single directory
folder.create("build");

// Create nested directories (recursive is default behavior)
folder.create("build/Release/bin");

// Use variables
export("outputDir", "./dist");
folder.create("$(outputDir)/docs");
```

Parent directories are created automatically, so you don't need to create each level separately.

## Checking Existence

### folder.exists(path)

Returns true if the directory exists, false otherwise.

```javascript
if (!folder.exists("build")) {
  folder.create("build");
}

// Check before operations
if (folder.exists("old-build")) {
  folder.remove("old-build", true);
}
```

## Removing Directories

### folder.remove(path, [recurse])

Removes a directory.

**Parameters:**
- `path` - Directory to remove
- `recurse` - If true, remove directory and all contents. If false, directory must be empty (default: false)

```javascript
// Remove empty directory
folder.remove("temp");

// Remove directory and all contents
folder.remove("build", true);

// Remove multiple build directories
export("buildDir", "./build");
folder.remove("$(buildDir)", true);
```

Be careful with `recurse: true` - it deletes everything inside the directory without confirmation.

## Moving Directories

### folder.move(source, destination)

Moves or renames a directory.

```javascript
// Rename directory
folder.move("build-temp", "build");

// Move to different location
folder.move("temp/output", "final/output");

// Use variables
export("stagingDir", "./staging");
folder.move("build", "$(stagingDir)/build-v1.0");
```

## Listing Directories

### folder.list(pattern, [recurse])

Returns an array of directory paths matching the pattern.

**Parameters:**
- `pattern` - Directory pattern with optional wildcards
- `recurse` - If true, search subdirectories recursively (default: false)

```javascript
// List directories in current folder
var dirs = folder.list("*");

// List recursively
var allDirs = folder.list("*", true);

// List specific path
var buildDirs = folder.list("build/*");

// Iterate over results
var folders = folder.list("src/*");
for (var i = 0; i < folders.length; i++) {
  log("Found directory: " + folders[i]);
}
```

To list files instead of directories, use [file.list()](File.md#filelisting-files).

## Folder Attributes

### folder.setAttributes(path, recurse, attributes)

Sets attributes on files within a folder (Windows-specific).

**Parameters:**
- `path` - Directory path
- `recurse` - If true, apply to all files in subdirectories
- `attributes` - Object with boolean properties: `ReadOnly`, `Hidden`, `Archive`

```javascript
// Make all files in folder read-only
folder.setAttributes("dist", false, { ReadOnly: true });

// Hide all files recursively
folder.setAttributes("cache", true, { Hidden: true });
```

On non-Windows platforms, this may have no effect.

## Examples

### Clean and Rebuild Output Directory

```javascript
export("outputDir", "./dist");

// Remove old output if it exists
if (folder.exists("$(outputDir)")) {
  log("Cleaning old output");
  folder.remove("$(outputDir)", true);
}

// Create fresh output directory
folder.create("$(outputDir)");
folder.create("$(outputDir)/bin");
folder.create("$(outputDir)/docs");

log("Output directory ready");
```

### Create Build Structure

```javascript
var architectures = ["x86", "x64", "arm64"];

for (var i = 0; i < architectures.length; i++) {
  var arch = architectures[i];
  var buildDir = "build_" + arch;

  folder.create(buildDir);
  folder.create(buildDir + "/obj");
  folder.create(buildDir + "/bin");

  log("Created structure for " + arch);
}
```

### Archive Old Builds

```javascript
export("buildDir", "./build");
export("archiveDir", "./archive");

// Create archive directory if needed
if (!folder.exists("$(archiveDir)")) {
  folder.create("$(archiveDir)");
}

// Move current build to archive with timestamp
var timestamp = new Date().toISOString().substring(0, 10);  // YYYY-MM-DD
folder.move("$(buildDir)", "$(archiveDir)/build-" + timestamp);

log("Archived build to archive/build-" + timestamp);
```

### Current Directory

To get the current working directory, use the `wd` global variable:

```javascript
log("Working directory: " + wd);
```

To change the working directory, use [shell.cd()](Shell.md#shellcdpath):

```javascript
shell.cd("build");
log("Now in: " + wd);  // build directory
```

See also [File](File.md) for file operations and [Shell](Shell.md) for changing directories.