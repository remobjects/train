---
title: Delphi
---

Build Delphi projects, packages, and libraries with all modern Delphi versions from Delphi 5 through Delphi 13+ (XE16+).

## Quick Reference

* **delphi.getBasePath(delphiVersion)** - Get the installation path for a Delphi version
* **delphi.build(project, options)** - Build a Delphi project (.dpr) or package (.dpk)

## Finding Delphi

### delphi.getBasePath(delphiVersion)

Returns the installation directory for a specific Delphi version.

```javascript
// Get Delphi 12 (Athens) installation path
var delphi12Path = delphi.getBasePath(29);
log("Delphi 12 installed at: " + delphi12Path);
// Returns: C:/Program Files (x86)/Embarcadero/Studio/23.0
```

Useful for locating Delphi tools manually or building custom tool paths.

## Building Projects

### delphi.build(project, options)

Builds a Delphi project (.dpr) or package (.dpk).

```javascript
// Simple build
delphi.build("MyApp.dpr", {
  delphi: 29,                    // Delphi 12 Athens
  platform: "Win64",
  configuration: "Release"
});

// Build package
delphi.build("MyPackage.dpk", {
  delphi: 29,
  platform: "Win64",
  destinationFolder: "./Output",
  bplOutput: "./Output"          // For runtime packages
});

// Build with custom paths
delphi.build("Application.dpr", {
  delphi: 29,
  platform: "Win64",
  configuration: "Release",
  unitSearchPath: "C:/Libraries/VCL;./Source",
  includeSearchPath: "./Include",
  destinationFolder: "./Bin/Win64",
  dcuDestinationFolder: "./Dcu/Win64"
});
```

## Configuration Options

All options are optional except `delphi` (or `dcc` as override).

### Version and Compiler

**delphi** (required if `dcc` not specified) - Delphi version number
- See [Delphi Version Numbers](#delphi-version-numbers) below

**dcc** - Full path to compiler executable (overrides `delphi` version detection)
- Example: `"C:/Delphi12/bin/dcc64.exe"`
- Use this to override auto-detected compiler path

**platform** - Target platform
- Windows: `"Win32"`, `"Win64"`
- macOS: `"OSX32"`, `"OSX64"`, `"OSXARM64"`
- Linux: `"Linux64"`
- Mobile: `"Android"`, `"Android64"`, `"iOSDevice"`, `"iOSDevice64"`, `"iOSSimulator"`, `"iOSSimARM64"`

**configuration** - Build configuration name
- Common values: `"Debug"`, `"Release"`
- Matches configurations in your project

### Paths

**destinationFolder** - Output directory for compiled executables/DLLs
- Sets the `-E` compiler flag

**dcuDestinationFolder** - Output directory for compiled units (.dcu files)
- Sets the `-N` compiler flag

**bplOutput** - Output directory for runtime packages (.bpl files)
- Only used when building packages (.dpk)
- Sets the `-LE` compiler flag

**unitSearchPath** - Semicolon-separated list of directories to search for units
- Sets the `-U` compiler flag
- Example: `"C:/Libs;./Source;./Vendor"`

**includeSearchPath** - Semicolon-separated list of directories to search for include files
- Sets the `-I` compiler flag

### Compiler Settings

**namespaces** - Unit scope names (Delphi XE2+)
- Semicolon-separated list with trailing semicolon
- Example: `"System;Vcl;Winapi;"`
- Sets the `-NS` compiler flag

**conditionalDefines** - Array of conditional compilation symbols
- Example: `["RELEASE", "PRODUCTION", "LOGGING"]`
- Sets the `-D` compiler flag

**aliases** - Unit aliases (maps old unit names to new)
- Rarely used in modern Delphi
- Sets the `-A` compiler flag

**otherParameters** - Additional raw compiler flags
- Any extra flags not covered by other options

### Version Information

**updateVersionInfo** - Object to update VERSIONINFO resource before compilation
- See [Version Information](#version-information) section below

**updateIcon** - Path to .ico file to embed as application icon

## Version Information

The `updateVersionInfo` option updates the VERSIONINFO resource in your executable. All fields are optional.

```javascript
delphi.build("Application.dpr", {
  delphi: 29,
  platform: "Win64",
  updateVersionInfo: {
    version: "2.5.1.0",                        // File version
    fileVersion: "2.5.1.5000",                 // Optional separate file version
    productName: "My Application",
    company: "Company Name",
    description: "Application description",
    legalCopyright: "Copyright 2025 Company Name",
    legalTrademarks: "Trademarks here",
    title: "My Application",

    // Custom version info fields
    extraFields: {
      BuildDate: "2025-01-15",
      Branch: "main",
      Commit: "a1b2c3d"
    }
  }
});
```

**Version Information Fields:**

- **version** - Version number string (e.g., "1.2.3.4")
- **fileVersion** - Separate file version (defaults to `version` if not specified)
- **productName** - Product name displayed in file properties
- **company** - Company name
- **description** - File description
- **legalCopyright** - Copyright notice
- **legalTrademarks** - Trademark notice
- **title** - Internal name / title
- **codePage** - Code page (default: 1200 for Unicode)
- **resLang** - Resource language ID (default: 1033 for English US)
- **isDll** - Set to true if building a DLL instead of EXE
- **extraFields** - Object with custom string fields to add to version resource

## Delphi Version Numbers

Train uses numeric version numbers to identify Delphi versions:

| Version | Delphi Release |
|---------|----------------|
| 5-7 | Delphi 5-7 |
| 9 | Delphi 2005 |
| 10 | Delphi 2006 |
| 11 | Delphi 2007 |
| 12 | Delphi 2009 |
| 14 | Delphi 2010 |
| 15 | Delphi XE |
| 16 | Delphi XE2 |
| 17 | Delphi XE3 |
| 18 | Delphi XE4 |
| 19 | Delphi XE5 |
| 20 | Delphi XE6 |
| 21 | Delphi XE7 |
| 22 | Delphi XE8 |
| 23 | Delphi 10 Seattle |
| 24 | Delphi 10.1 Berlin |
| 25 | Delphi 10.2 Tokyo |
| 26 | Delphi 10.3 Rio |
| 27 | Delphi 10.4 Sydney |
| 28 | Delphi 11 Alexandria |
| 29 | Delphi 12 Athens |
| 37+ | Delphi 13+ (37 = XE16 = Delphi 13) |

The version number corresponds to the compiler's internal version, not the marketing name.

## Examples

### Release Build with Versioning

```javascript
var version = "3.1.0.0";

delphi.build("Application.dpr", {
  delphi: 29,
  platform: "Win64",
  configuration: "Release",

  destinationFolder: "./Bin/Release/Win64",
  dcuDestinationFolder: "./Dcu/Win64",

  updateVersionInfo: {
    version: version,
    productName: "My Application",
    company: "My Company",
    legalCopyright: "Copyright 2025 My Company"
  }
});

log("Built version " + version);
```

### Multi-Platform Build

```javascript
var platforms = ["Win32", "Win64", "OSX64", "Linux64"];

for (var i = 0; i < platforms.length; i++) {
  var platform = platforms[i];
  log("Building " + platform);

  delphi.build("CrossPlatform.dpr", {
    delphi: 29,
    platform: platform,
    configuration: "Release",
    destinationFolder: "./Bin/" + platform,
    dcuDestinationFolder: "./Dcu/" + platform
  });
}

log("All platforms built");
```

### Package Build

```javascript
// Build design-time package (installed in IDE)
delphi.build("DesignPackage.dpk", {
  delphi: 29,
  platform: "Win64",
  destinationFolder: "./Output",
  dcuDestinationFolder: "./Dcu"
});

// Build runtime package (deployed with app)
delphi.build("RuntimePackage.dpk", {
  delphi: 29,
  platform: "Win64",
  destinationFolder: "./Output",
  bplOutput: "./Output",           // BPL goes here
  dcuDestinationFolder: "./Dcu"
});
```

### CI Build with Git Info

```javascript
// Get Git info
var version = env["CI_VERSION"] || "1.0.0.0";
var commit = shell.exec("/usr/bin/git", "rev-parse --short HEAD",
  { capture: true }).trim();
var branch = shell.exec("/usr/bin/git", "rev-parse --abbrev-ref HEAD",
  { capture: true }).trim();

log("Building " + version + " from " + branch + "@" + commit);

delphi.build("Application.dpr", {
  delphi: 29,
  platform: "Win64",
  configuration: "Release",

  conditionalDefines: ["RELEASE", "CI_BUILD"],

  updateVersionInfo: {
    version: version,
    productName: "My Application",
    company: "My Company",
    extraFields: {
      GitBranch: branch,
      GitCommit: commit
    }
  }
});
```

### Custom Library Paths

```javascript
// Build with external libraries
var libraryPath = "C:/Libraries";

delphi.build("Application.dpr", {
  delphi: 29,
  platform: "Win64",

  unitSearchPath: [
    libraryPath + "/VCL",
    libraryPath + "/Indy",
    "./Source",
    "./Vendor"
  ].join(";"),

  includeSearchPath: "./Include",

  namespaces: "System;Vcl;Winapi;",

  destinationFolder: "./Bin"
});
```

## Related Documentation

- [MSBuild](MSBuild.md) - Building .NET projects
- [EBuild](EBuild.md) - Building Elements projects
- [Shell](Shell.md) - Running external tools
- [Concepts](../Concepts.md) - Understanding Train scripts
