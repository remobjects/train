---
title: INI Files
---

Read and write INI configuration files. INI files are text-based with sections and key-value pairs.

## Quick Reference

* **ini.fromFile(filename)** - Load INI file from disk
* **ini.fromString(content)** - Parse INI content from string
* **new ini()** - Create empty INI object
* **ini.getValue(section, key)** - Get value from INI file
* **ini.setValue(section, key, value)** - Set value in INI file
* **ini.toFile(filename)** - Save INI object to file
* **ini.toString()** - Convert INI object to string

## INI File Format

INI files use a simple structure with sections in brackets and key=value pairs:

```ini
[Options]
VERSION=2.0.1.5000
DEBUG=false

[Build]
COMPILER=clang
ARCH=arm64

[Database]
ConnectionString=Server=localhost;Database=mydb
```

## Loading INI Files

### ini.fromFile(filename)

Loads an INI file from disk.

```javascript
// Load existing INI file
var config = ini.fromFile("config.ini");

// Read values
var version = config.getValue("Options", "VERSION");
var compiler = config.getValue("Build", "COMPILER");

log("Version: " + version);
log("Compiler: " + compiler);
```

### ini.fromString(content)

Parses an INI file from a string.

```javascript
var iniContent = "[Section]\nKey=Value\n";
var config = ini.fromString(iniContent);
var value = config.getValue("Section", "Key");  // "Value"
```

### new ini()

Creates a new empty INI file object.

```javascript
// Create new INI file from scratch
var config = new ini();
config.setValue("Options", "MODE", "Release");
config.setValue("Build", "ARCH", "x64");
config.toFile("newconfig.ini");
```

## Reading Values

### ini.getValue(section, key, [default])

Reads a value from the INI file. Returns the default value if the key doesn't exist (or `null` if no default provided).

```javascript
var config = ini.fromFile("settings.ini");

// Read with automatic default
var version = config.getValue("App", "Version", "1.0.0");

// Read without default (returns null if not found)
var apiKey = config.getValue("API", "Key");
if (apiKey == null) {
  error("API key not configured");
}

// Multiple reads
var host = config.getValue("Database", "Host");
var port = config.getValue("Database", "Port");
var db = config.getValue("Database", "Name");
```

## Writing Values

### ini.setValue(section, key, value)

Sets a value in the INI file. Creates the section if it doesn't exist.

```javascript
var config = new ini();

// Set values (creates sections automatically)
config.setValue("Options", "VERSION", "2.0.1.5000");
config.setValue("Options", "DEBUG", "false");
config.setValue("Build", "COMPILER", "clang");

// Overwrite existing values
config.setValue("Options", "DEBUG", "true");
```

## Saving INI Files

### ini.toFile(filename)

Writes the INI file to disk. Overwrites if the file exists.

```javascript
var config = new ini();
config.setValue("Section", "Key", "Value");
config.toFile("output.ini");

// Modify and save
var existing = ini.fromFile("settings.ini");
existing.setValue("Database", "ConnectionString", "Server=localhost");
existing.toFile("settings.ini");  // Overwrites original
```

### ini.toString()

Returns the INI file content as a string.

```javascript
var config = new ini();
config.setValue("Options", "Mode", "Release");

var iniContent = config.toString();
log(iniContent);
// Output:
// [Options]
// Mode=Release
```

## Sections and Keys

### ini.sections()

Returns an array of all section names.

```javascript
var config = ini.fromFile("config.ini");
var sections = config.sections();

for (var i = 0; i < sections.length; i++) {
  log("Section: " + sections[i]);
}
```

### ini.keysInSection(section)

Returns an array of all keys in a specific section.

```javascript
var config = ini.fromFile("config.ini");
var keys = config.keysInSection("Options");

for (var i = 0; i < keys.length; i++) {
  var key = keys[i];
  var value = config.getValue("Options", key);
  log(key + " = " + value);
}
```

### ini.deleteSection(section)

Removes an entire section and all its keys.

```javascript
var config = ini.fromFile("config.ini");
config.deleteSection("OldSettings");
config.toFile("config.ini");
```

### ini.deleteValue(section, key)

Removes a specific key from a section.

```javascript
var config = ini.fromFile("config.ini");
config.deleteValue("Options", "DEBUG");
config.toFile("config.ini");
```

## Examples

### Read Configuration

```javascript
// Load and read settings
if (!file.exists("config.ini")) {
  error("Configuration file not found");
}

var config = ini.fromFile("config.ini");

var dbHost = config.getValue("Database", "Host", "localhost");
var dbPort = config.getValue("Database", "Port", "5432");
var dbName = config.getValue("Database", "Name");

log("Connecting to " + dbHost + ":" + dbPort + "/" + dbName);
```

### Modify Existing INI

```javascript
// Update version in existing config
var config = ini.fromFile("settings.ini");
config.setValue("App", "Version", "2.5.0");
config.setValue("App", "BuildDate", new Date().toISOString());
config.toFile("settings.ini");

log("Updated version in settings.ini");
```

### Create or Update Pattern

A common pattern is to create the INI file if it doesn't exist, or update it if it does:

```javascript
function addValueToIni(filename, section, key, value) {
  var config = file.exists(filename)
    ? ini.fromFile(filename)
    : new ini();

  config.setValue(section, key, value);
  config.toFile(filename);
}

// Usage
addValueToIni("Versions.ini", "Info", "BUILD_VERSION", "1.0.0.123");
addValueToIni("Versions.ini", "Info", "BUILD_DATE", "2025-01-15");
```

### Store Build Information

```javascript
// Create build info file
var buildInfo = new ini();

// Version information
var version = env["CI_VERSION"] || "1.0.0.0";
buildInfo.setValue("Version", "Number", version);
buildInfo.setValue("Version", "Branch",
  shell.exec("/usr/bin/git", "rev-parse --abbrev-ref HEAD",
    { capture: true }).trim());
buildInfo.setValue("Version", "Commit",
  shell.exec("/usr/bin/git", "rev-parse --short HEAD",
    { capture: true }).trim());

// Build information
buildInfo.setValue("Build", "Date", new Date().toISOString());
buildInfo.setValue("Build", "Machine", env["COMPUTERNAME"] || env["HOSTNAME"]);
buildInfo.setValue("Build", "User", env["USER"] || env["USERNAME"]);

// Save
buildInfo.toFile("BuildInfo.ini");
log("Created BuildInfo.ini");
```

### Configuration Template

```javascript
// Generate default configuration file
function createDefaultConfig(filename) {
  if (file.exists(filename)) {
    log(filename + " already exists, skipping");
    return;
  }

  var config = new ini();

  // Application settings
  config.setValue("Application", "Name", "MyApp");
  config.setValue("Application", "Version", "1.0.0");
  config.setValue("Application", "LogLevel", "Info");

  // Database settings
  config.setValue("Database", "Host", "localhost");
  config.setValue("Database", "Port", "5432");
  config.setValue("Database", "Name", "myapp_db");
  config.setValue("Database", "User", "");
  config.setValue("Database", "Password", "");

  // Build settings
  config.setValue("Build", "Configuration", "Release");
  config.setValue("Build", "Platform", "x64");

  config.toFile(filename);
  log("Created default configuration: " + filename);
}

createDefaultConfig("config.ini");
```

### Multi-Architecture Configuration

```javascript
var architectures = ["x86", "x64", "arm64"];

for (var i = 0; i < architectures.length; i++) {
  var arch = architectures[i];
  var configFile = "config_" + arch + ".ini";

  var config = new ini();
  config.setValue("Build", "Architecture", arch);
  config.setValue("Build", "OutputDir", "./Bin/" + arch);
  config.setValue("Build", "IntermediateDir", "./Obj/" + arch);

  config.toFile(configFile);
  log("Created " + configFile);
}
```

## Related Documentation

- [File](File.md) - File operations (checking existence, reading/writing)
- [XML](XML.md) - Working with XML configuration files
- [Globals](Globals.md) - Environment variables and global functions
