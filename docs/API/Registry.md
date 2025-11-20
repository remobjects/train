---
title: Registry
---

Read and write Windows registry values. **Windows-only** - these functions do nothing on macOS/Linux.

## Quick Reference

* **reg.getValue(key, valueName, default)** - Read registry value
* **reg.setValue(key, valueName, value, valueType)** - Write registry value

## Reading Registry Values

### reg.getValue(key, valueName, [default])

Reads a value from the Windows registry. Returns the default value if the key or value doesn't exist (or `null` if no default provided).

**Parameters:**
- `key` - Full registry key path with hive (e.g., `"HKEY_LOCAL_MACHINE\\SOFTWARE\\..."`
- `valueName` - Name of the value to read
- `default` - Optional default if key/value doesn't exist

```javascript
// Read registry value
var installPath = reg.getValue("HKEY_LOCAL_MACHINE\\SOFTWARE\\MyCompany\\MyApp\\", "InstallDir");

// Read with default
var timeout = reg.getValue(
  "HKEY_CURRENT_USER\\Software\\MyApp\\",
  "Timeout",
  "30"  // Default if not found
);

// Check if value exists
var apiKey = reg.getValue("HKEY_LOCAL_MACHINE\\SOFTWARE\\MyApp\\", "ApiKey");
if (apiKey == null) {
  error("API key not configured in registry");
}

log("API Key: " + apiKey);
```

## Writing Registry Values

### reg.setValue(key, valueName, newValue)

Sets a value in the Windows registry. Creates the key if it doesn't exist.

**Parameters:**
- `key` - Full registry key path with hive
- `valueName` - Name of the value to set
- `newValue` - Value to write (string)

```javascript
// Set registry value
reg.setValue(
  "HKEY_CURRENT_USER\\Software\\MyApp\\",
  "LastRun",
  new Date().toISOString()
);

// Set configuration value
reg.setValue(
  "HKEY_LOCAL_MACHINE\\SOFTWARE\\MyApp\\",
  "InstallPath",
  "C:\\Program Files\\MyApp"
);
```

## Registry Hives

Common registry hive names:

- **HKEY_LOCAL_MACHINE** (`HKLM`) - Machine-wide settings, requires admin to write
- **HKEY_CURRENT_USER** (`HKCU`) - Current user settings, no admin required
- **HKEY_CLASSES_ROOT** (`HKCR`) - File associations and COM registration
- **HKEY_USERS** - All user profiles
- **HKEY_CURRENT_CONFIG** - Hardware configuration

Use full hive names in paths (not abbreviations like `HKLM`).

## Path Syntax

Registry paths use backslashes `\\` and must include the hive:

```javascript
// ✅ Correct
var value = reg.getValue("HKEY_LOCAL_MACHINE\\SOFTWARE\\Company\\App\\", "Setting");

// ❌ Wrong - missing hive
var value = reg.getValue("SOFTWARE\\Company\\App\\", "Setting");

// ❌ Wrong - forward slashes
var value = reg.getValue("HKEY_LOCAL_MACHINE/SOFTWARE/Company/App/", "Setting");
```

## Examples

### Find Tool Installation Path

```javascript
// Find tool path from registry with fallback
var cmakePath = reg.getValue(
  "HKEY_LOCAL_MACHINE\\SOFTWARE\\Kitware\\CMake\\",
  "InstallDir"
);

if (cmakePath == null) {
  // Fallback to environment variable
  cmakePath = env["CMAKE_PATH"];
}

if (cmakePath == null) {
  // Fallback to default location
  cmakePath = "C:\\Program Files\\CMake\\bin\\cmake.exe";
}

if (!file.exists(cmakePath)) {
  error("CMake not found");
}

log("Using CMake at: " + cmakePath);
```

### Store Build Configuration

```javascript
// Store build settings in registry
function saveBuildConfig(configuration, platform, outputDir) {
  var keyPath = "HKEY_CURRENT_USER\\Software\\MyCompany\\BuildTool\\";

  reg.setValue(keyPath, "LastConfiguration", configuration);
  reg.setValue(keyPath, "LastPlatform", platform);
  reg.setValue(keyPath, "OutputDirectory", outputDir);
  reg.setValue(keyPath, "LastBuildTime", new Date().toISOString());

  log("Build configuration saved to registry");
}

// Use it
saveBuildConfig("Release", "x64", "C:\\Build\\Output");
```

### Cross-Platform Registry Access

Handle registry gracefully on non-Windows platforms:

```javascript
function getToolPath(registryKey, registryValue, envVar, defaultPath) {
  // Try registry first (Windows only)
  var path = null;
  if (env["OS"] && env["OS"].indexOf("Windows") >= 0) {
    path = reg.getValue(registryKey, registryValue);
  }

  // Fallback to environment variable
  if (path == null) {
    path = env[envVar];
  }

  // Fallback to default
  if (path == null) {
    path = defaultPath;
  }

  return path;
}

// Usage - works on all platforms
var cmakePath = getToolPath(
  "HKEY_LOCAL_MACHINE\\SOFTWARE\\Kitware\\CMake\\",
  "InstallDir",
  "CMAKE_PATH",
  "/usr/local/bin/cmake"  // Unix default
);

log("Using CMake at: " + cmakePath);
```

### Read Delphi Installation Path

```javascript
// Find Delphi installation from registry
function getDelphiPath(version) {
  // Delphi stores path in registry
  var keyPath = "HKEY_CURRENT_USER\\Software\\Embarcadero\\BDS\\" + version + ".0\\";
  var rootDir = reg.getValue(keyPath, "RootDir");

  if (rootDir == null) {
    // Try HKEY_LOCAL_MACHINE
    keyPath = "HKEY_LOCAL_MACHINE\\Software\\Embarcadero\\BDS\\" + version + ".0\\";
    rootDir = reg.getValue(keyPath, "RootDir");
  }

  return rootDir;
}

// Get Delphi 12 path (version 23)
var delphi12Path = getDelphiPath("23");
if (delphi12Path != null) {
  log("Delphi 12 installed at: " + delphi12Path);
  var compiler = delphi12Path + "bin\\dcc64.exe";
} else {
  error("Delphi 12 not found in registry");
}
```

### Read Multiple Tool Paths

```javascript
// Read multiple tool paths from registry
function getToolPaths() {
  var toolsKeyPath = "HKEY_LOCAL_MACHINE\\SOFTWARE\\MyCompany\\BuildTools\\";

  return {
    cmake: reg.getValue(toolsKeyPath, "CMakePath"),
    ninja: reg.getValue(toolsKeyPath, "NinjaPath"),
    python: reg.getValue(toolsKeyPath, "PythonPath"),
    git: reg.getValue(toolsKeyPath, "GitPath")
  };
}

var tools = getToolPaths();

if (tools.cmake == null) {
  error("CMake path not configured in registry");
}

log("Using tools from registry:");
log("  CMake: " + tools.cmake);
log("  Ninja: " + tools.ninja);
```

## Platform Notes

- **Windows**: Full registry access with `reg.getValue()` and `reg.setValue()`
- **macOS/Linux**: Registry functions do nothing and return `null`. Use [file.read()](File.md) for configuration files instead.
- **Cross-platform**: Always provide fallbacks (environment variables, config files, default paths)

For cross-platform configuration, consider using:
- Environment variables ([env](Globals.md#env))
- INI files ([ini object](INI.md))
- JSON configuration files ([JSON.parse()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/parse))

## Related Documentation

- [Globals](Globals.md) - Environment variables
- [INI](INI.md) - INI configuration files
- [File](File.md) - File operations
- [Shell](Shell.md) - Running external tools
