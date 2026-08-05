---
title: ZIP Files
---

Compress and extract ZIP archive files.

## Quick Reference

* **zip.compress(zipPath, sourceDir, fileMask, recurse)** - Create ZIP archive from files
* **zip.extract(zipPath, destDir)** - Extract ZIP archive to directory

## Compressing Files

### zip.compress(zipPath, sourceDir, [fileMask], [recurse])

Creates a ZIP archive from files in a directory.

**Parameters:**
- `zipPath` - Path to the output .zip file
- `sourceDir` - Directory containing files to compress
- `fileMask` - File pattern to match (default: all files). Can be a semicolon-separated list
- `recurse` - If true, include subdirectories recursively (default: false)

```javascript
// Compress entire directory
zip.compress("output.zip", "./source");

// Compress with file pattern
zip.compress("release.zip", "./bin", "*.dll", false);

// Compress recursively
zip.compress("backup.zip", "./project", "*.*", true);

// Multiple file patterns (semicolon-separated)
zip.compress("assets.zip", "./resources", "*.png;*.jpg;*.gif", true);

// Use variables
export("releaseDir", "./Bin/Release");
zip.compress("MyApp-1.0.zip", expand("$(releaseDir)"), "*.*", true);
```

The file structure inside the ZIP preserves the relative paths from `sourceDir`.

## Extracting Files

### `zip.extractFiles(zipPath, destinationDir, [entriesArray], [flatten])`

Extracts files from a ZIP archive.

**Parameters:**
- `zipPath` - Path to the .zip file
- `destinationDir` - Directory where files will be extracted
- `entriesArray` - Array of file names to extract, or `null` to extract all (default: all)
- `flatten` - If true, ignore directory structure and extract all to destination root (default: false)

```javascript
// Extract all files (preserves directory structure)
zip.extractFiles("archive.zip", "./destination");

// Extract all files (flatten - no subdirectories)
zip.extractFiles("archive.zip", "./libs", null, true);

// Extract specific files only
var filesToExtract = ["readme.txt", "bin/app.exe", "lib/library.dll"];
zip.extractFiles("package.zip", "./output", filesToExtract, false);
```

### `zip.extractFile(zipPath, localTarget, fileInZip)`

Extracts a single file from a ZIP archive.

**Parameters:**
- `zipPath` - Path to the .zip file
- `localTarget` - Destination path. If ends with path separator, treated as folder (filename from ZIP). Otherwise, full file path.
- `fileInZip` - Path of file inside the ZIP

```javascript
// Extract to specific file path
zip.extractFile("archive.zip", "./output/readme.txt", "docs/readme.txt");

// Extract to folder (filename from ZIP)
zip.extractFile("archive.zip", "./output/", "docs/readme.txt");
// Creates: ./output/readme.txt

// Extract from nested path
zip.extractFile("sdk.zip", "./libs/", "bin/x64/library.dll");
// Creates: ./libs/library.dll
```

## Listing Archive Contents

### `zip.list(zipPath)`

Returns an array of objects describing files in the ZIP archive.

```javascript
var entries = zip.list("archive.zip");

for (var i = 0; i < entries.length; i++) {
  var entry = entries[i];
  log("File: " + entry.name);
  log("  Size: " + entry.size + " bytes");
  log("  Compressed: " + entry.compressedSize + " bytes");
}
```

Each entry object has:
- **name** - File path inside the ZIP
- **size** - Uncompressed size in bytes
- **compressedSize** - Compressed size in bytes

## Examples

### Create Distribution ZIP

```javascript
export("version", "1.0.0");
export("distDir", "./Distro");

// Clean and create distribution folder
if (folder.exists("$(distDir)")) {
  folder.remove("$(distDir)", true);
}
folder.create("$(distDir)/App");

// Copy binaries
file.copy("./Bin/Release/*.dll", "$(distDir)/App/");
file.copy("./Bin/Release/*.exe", "$(distDir)/App/");
file.copy("README.md", "$(distDir)/");
file.copy("LICENSE.txt", "$(distDir)/");

// Create ZIP
var zipName = "MyApp-v$(version).zip";
zip.compress(zipName, "$(distDir)", "*.*", true);

// Clean up temp folder
folder.remove("$(distDir)", true);

log("Created " + zipName);
```

### Download and Extract

```javascript
// Download ZIP from S3
var packageFile = "libraries-v2.5.zip";
s3.downloadFile("packages/" + packageFile, "./temp/");

// Extract to libs folder
folder.create("./libs");
zip.extractFiles("./temp/" + packageFile, "./libs/");

// Clean up
file.remove("./temp/" + packageFile);

log("Libraries extracted to ./libs/");
```

### Backup Build Artifacts

```javascript
var timestamp = new Date().toISOString().substring(0, 10);  // YYYY-MM-DD
var backupName = "build-backup-" + timestamp + ".zip";

log("Creating backup: " + backupName);

// Compress build output
zip.compress(backupName, "./Bin/Release", "*.*", true);

// Upload to archive location
if (folder.exists("//server/archives")) {
  file.copy(backupName, "//server/archives/");
  log("Backup uploaded to server");
}
```

### Selective Extraction

```javascript
// List contents first
var entries = zip.list("full-sdk.zip");

// Extract only DLLs
var dllsToExtract = [];
for (var i = 0; i < entries.length; i++) {
  if (entries[i].name.indexOf(".dll") > -1) {
    dllsToExtract.push(entries[i].name);
  }
}

log("Extracting " + dllsToExtract.length + " DLL files");
zip.extractFiles("full-sdk.zip", "./libs/", dllsToExtract, true);  // Flatten
```

### Multi-Architecture Release

```javascript
var architectures = ["x86", "x64", "arm64"];
var version = "2.0.0";

for (var i = 0; i < architectures.length; i++) {
  var arch = architectures[i];
  log("Packaging " + arch);

  var buildDir = "./Bin/Release/" + arch;
  var zipName = "MyApp-v" + version + "-" + arch + ".zip";

  // Create ZIP for this architecture
  zip.compress(zipName, buildDir, "*.*", true);

  log("Created " + zipName);
}

log("All architectures packaged");
```

### Extract Specific Platform

```javascript
// SDK has multiple platforms in subdirectories
var platform = "Windows";
var arch = "x64";

// List and filter
var entries = zip.list("cross-platform-sdk.zip");
var targetPath = platform + "/" + arch + "/";
var filesToExtract = [];

for (var i = 0; i < entries.length; i++) {
  if (entries[i].name.indexOf(targetPath) === 0) {
    filesToExtract.push(entries[i].name);
  }
}

log("Extracting " + filesToExtract.length + " files for " + platform + "/" + arch);
zip.extractFiles("cross-platform-sdk.zip", "./sdk/", filesToExtract, false);
```

## Related Documentation

- [File](File.md) - File operations (copy, move, remove)
- [Folder](Folder.md) - Directory operations
- [S3](S3.md) - Upload/download from Amazon S3
- [HTTP](HTTP.md) - Download files from web
