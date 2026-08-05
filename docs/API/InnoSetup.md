---
title: Inno Setup
---

Build Windows installers using Inno Setup. Inno Setup is a popular free installer for Windows applications.

## Quick Reference

* **inno.build(script, options)** - Build Inno Setup installer (uses env or registry to find ISCC.exe)
* **shell.exec(ISCC, args)** - Direct ISCC.exe invocation (recommended pattern in most scripts)

## Building Installers

Train provides two approaches for building Inno Setup installers: using the `inno` object or calling `ISCC.exe` directly via `shell.exec()`.

### Using shell.exec (Recommended Pattern)

Most Train scripts call ISCC.exe directly because it gives more control over environment variables and paths:

```javascript
// Find ISCC.exe from environment variable
var ISCC = env["ISCC"];
if (ISCC == null) error("ISCC not found. Install Inno Setup and set ISCC environment variable.");

// Path to .iss script (use backslashes on Windows)
var project = expand("$(projectDir)/Build/Setup.iss");
project = project.replace("/", "\\");

// Compile installer
shell.exec(ISCC, '/q "' + project + '"');

log("Installer created");
```

### Passing Configuration via INI File

A common pattern is to pass configuration to the Inno Setup script via a Setup.ini file:

```javascript
// Create configuration INI file
var iniFileName = "Setup.ini";
file.remove(iniFileName);  // Remove old config

var iniFile = new ini();
iniFile.setValue("Options", "OutputDir", expand("$(outputFolder)"));
iniFile.setValue("Options", "OutputBaseFilename", "MyApp-Setup-1.0.0");
iniFile.setValue("Options", "Edition", "Full");
iniFile.setValue("Options", "Mode", "Release");
iniFile.toFile(iniFileName);

// Build installer (Inno Setup script reads Setup.ini)
var ISCC = env["ISCC"];
if (ISCC == null) error("ISCC not defined");

var project = "Setup.iss".replace("/", "\\");
shell.exec(ISCC, '/q "' + project + '"');
```

Then in your Setup.iss file:

```pascal
#define OutputDir ReadIni("Setup.ini", "Options", "OutputDir", "")
#define OutputBaseFilename ReadIni("Setup.ini", "Options", "OutputBaseFilename", "MyApp-Setup")
#define Edition ReadIni("Setup.ini", "Options", "Edition", "Full")

[Setup]
AppName=My Application
OutputDir={#OutputDir}
OutputBaseFilename={#OutputBaseFilename}
```

### Passing Environment Variables

Inno Setup scripts can read environment variables. Pass them via `shell.exec()` options:

```javascript
var ISCC = env["ISCC"];
var project = "Setup.iss".replace("/", "\\");

shell.exec(ISCC, '/q "' + project + '"', {
  environment: {
    VERSION: "1.0.0",
    BUILD_DIR: "C:\\Build\\Release",
    TOOLS_DIR: "C:\\BuildTools"
  }
});
```

In Setup.iss:

```pascal
#define MyAppVersion GetEnv("VERSION")
#define BuildDir GetEnv("BUILD_DIR")

[Setup]
AppVersion={#MyAppVersion}

[Files]
Source: "{#BuildDir}\MyApp.exe"; DestDir: "{app}"
```

### Using inno.build()

Train also provides an `inno` object:

```javascript
// Simple build
inno.build("Setup.iss", {
  destinationFolder: "./Installers"
});

// With defines
inno.build("Setup.iss", {
  destinationFolder: "./Installers",
  defines: ["VERSION=1.0.0", "EDITION=Full"],
  extraArgs: "/Q"  // Quiet mode
});
```

**Note**: Most production Train scripts use `shell.exec()` directly for more control.

## Finding ISCC.exe

ISCC.exe is Inno Setup's command-line compiler. Find it using registry or environment variables:

```javascript
// Try environment variable first
var ISCC = env["ISCC"];

// Fall back to common install locations
if (ISCC == null && file.exists("C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe")) {
  ISCC = "C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe";
}

if (ISCC == null) {
  error("Inno Setup Compiler (ISCC.exe) not found. Install from https://jrsoftware.org/isinfo.php");
}
```

## Code Signing the Installer

After creating the installer, sign it:

```javascript
function codeSign(exe) {
  var signTool = "C:\\Program Files (x86)\\Windows Kits\\10\\bin\\10.0.22000.0\\x64\\signtool.exe";
  var certPath = "MyCertificate.pfx";
  var certPassword = "password";
  var timestampUrl = "http://timestamp.digicert.com";

  shell.exec(signTool,
    'sign /f "' + certPath + '" ' +
    '/p "' + certPassword + '" ' +
    '/t "' + timestampUrl + '" ' +
    '/fd SHA256 "' + exe + '"');
}

// Build and sign
inno.build("Setup.iss", { destinationFolder: "./Installers" });
codeSign("./Installers/MyApp-Setup-1.0.0.exe");

log("Signed installer created");
```

## Complete Example

```javascript
// Configuration
var appName = "MyApplication";
var version = "2.5.0";
var configuration = "Release";
var buildDir = "./Bin/Release";
var setupDir = "./Build";
var outputDir = "./Installers";

// Find ISCC
var ISCC = env["ISCC"];
if (ISCC == null && file.exists("C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe")) {
  ISCC = "C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe";
}
if (ISCC == null) {
  error("ISCC not found. Set ISCC environment variable or install Inno Setup.");
}

// Create output directory
folder.create(outputDir, true);

// Create Setup.ini configuration
var iniFile = new ini();
iniFile.setValue("Options", "OutputDir", outputDir);
iniFile.setValue("Options", "OutputBaseFilename", appName + "-Setup-" + version);
iniFile.setValue("Options", "Version", version);
iniFile.setValue("Options", "BuildDir", buildDir);
iniFile.toFile(setupDir + "/Setup.ini");

log("Building installer for " + appName + " " + version);

// Build installer
var project = (setupDir + "/Setup.iss").replace("/", "\\");
shell.exec(ISCC, '/q "' + project + '"', {
  environment: {
    APP_VERSION: version,
    BUILD_CONFIG: configuration
  }
});

// Sign installer (if signing enabled)
var setupExe = outputDir + "/" + appName + "-Setup-" + version + ".exe";
if (file.exists(setupExe)) {
  log("Installer created: " + setupExe);

  // Code sign here if needed
  // codeSign(setupExe);
} else {
  error("Installer not created - check Inno Setup script for errors");
}

log("Build complete");
```

## ISCC Command-Line Options

Common ISCC.exe command-line options:

- `/Q` or `/q` - Quiet mode (minimal output)
- `/O"dir"` - Output directory
- `/F"filename"` - Output filename (without extension)
- `/D"name=value"` - Define preprocessor variable
- `/S"name=value"` - Set SignTool configuration

```javascript
// Using command-line options directly
shell.exec(ISCC,
  '/q ' +
  '/O"' + outputDir + '" ' +
  '/F"' + baseName + '" ' +
  '/DVERSION="' + version + '" ' +
  '"' + project + '"');
```

## Platform Notes

- **Windows only**: Inno Setup only runs on Windows
- **Backslashes required**: Inno Setup requires Windows-style paths with backslashes
- **Use `.replace("/", "\\")` on all paths** passed to ISCC
- **Registry keys**: Inno Setup installer path is typically in registry after installation

## Related Documentation

- [Registry](Registry.md) - Reading ISCC path from registry
- [INI](INI.md) - Passing configuration to Inno Setup scripts
- [Shell](Shell.md) - Running external programs
- [MSBuild](MSBuild.md) - Building applications before creating installers
- [Delphi](Delphi.md) - Building Delphi applications
