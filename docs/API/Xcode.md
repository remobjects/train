---
title: Xcode
---

Build macOS, iOS, tvOS, and watchOS projects using Xcode. This works with .xcodeproj and .xcworkspace files.

Note: we recommend using Elements for writing applications targeting Apple platforms.

## Quick Reference

* **xcode.build(project, options)** - Build an Xcode project or workspace
* **xcode.clean(project, options)** - Clean build outputs
* **xcode.archive(project, options)** - Create an archive for distribution

## Building Projects

### xcode.build(project, [options])

Builds an Xcode project or workspace incrementally.

```javascript
// Simple build
xcode.build("MyApp.xcodeproj", {
  target: "MyApp",
  configuration: "Release"
});

// Build with specific SDK
xcode.build("iOSApp.xcodeproj", {
  target: "iOSApp",
  configuration: "Release",
  sdk: "iphoneos"
});

// Build for simulator
xcode.build("iOSApp.xcodeproj", {
  target: "iOSApp",
  configuration: "Debug",
  sdk: "iphonesimulator"
});

// Custom output location
xcode.build("Framework.xcodeproj", {
  target: "Framework",
  configuration: "Release",
  destinationFolder: "./Bin/Release"
});
```

### xcode.rebuild(project, [options])

Rebuilds an Xcode project from scratch (clean + build).

```javascript
// Clean rebuild for release
xcode.rebuild("MyApp.xcodeproj", {
  target: "MyApp for Mac",
  configuration: "Release",
  destinationFolder: "./Bin"
});
```

### xcode.clean(project, [options])

Cleans build products for an Xcode project.

```javascript
// Clean before manual build
xcode.clean("MyApp.xcodeproj", {
  target: "MyApp",
  configuration: "Release"
});
```

## Configuration Options

All build methods accept an options object:

**configuration** - Build configuration name
- Common values: "Debug", "Release"
- Must match configurations defined in your Xcode project

**target** - Target name to build
- Must match target names in your Xcode project
- Example: "MyApp", "MyApp for Mac", "Framework"

**sdk** - SDK to build against
- macOS: `"macosx"` or `"macosx14.0"`
- iOS: `"iphoneos"` or `"iphoneos17.0"`
- iOS Simulator: `"iphonesimulator"`
- tvOS: `"appletvos"`, `"appletvsimulator"`
- watchOS: `"watchos"`, `"watchsimulator"`

**destinationFolder** - Output directory for build products
- Overrides Xcode's default build location

**extraArgs** - Additional xcodebuild arguments
- Pass any extra flags to xcodebuild

```javascript
// Using all options
xcode.build("CompleteApp.xcodeproj", {
  target: "CompleteApp",
  configuration: "Release",
  sdk: "macosx14.0",
  destinationFolder: "./Bin/macOS",
  extraArgs: "CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO"
});
```

## Examples

### Multi-Platform iOS Build

```javascript
// Build for device
xcode.rebuild("iOSApp.xcodeproj", {
  target: "iOSApp",
  configuration: "Release",
  sdk: "iphoneos",
  destinationFolder: "./Bin/iOS"
});

// Build for simulator
xcode.rebuild("iOSApp.xcodeproj", {
  target: "iOSApp",
  configuration: "Release",
  sdk: "iphonesimulator",
  destinationFolder: "./Bin/iOS-Simulator"
});

log("iOS builds complete");
```

### Framework Build

```javascript
// Build universal framework
xcode.rebuild("Framework.xcodeproj", {
  target: "Framework",
  configuration: "Release",
  sdk: "macosx",
  destinationFolder: "./Bin/macOS"
});

// Package framework
var frameworkPath = "./Bin/macOS/Framework.framework";
if (folder.exists(frameworkPath)) {
  zip.compress("Framework-1.0.0.zip", "./Bin/macOS", "*.*", true);
  log("Framework packaged");
}
```

### Mac App with Version Extraction

This example shows extracting version from Info.plist after build:

```javascript
// Build Mac app
xcode.build("Builds.xcodeproj", {
  target: "Builds for Mac",
  configuration: "Release",
  destinationFolder: "./Bin"
});

// Extract version from Info.plist
var infoPlist = xml.fromFile("OnyxCI for Mac-Info.plist");
var versionElement = infoPlist.xpath("/plist/dict/key[.='CFBundleVersion']/following-sibling::*[1]/text()");
var revision = versionElement.toString();

log("Built version: " + revision);

// Create ZIP distribution
shell.cd("./Bin/Release/");
shell.exec("/usr/bin/zip", '-x *.h -r Builds-' + revision + '.zip "Builds for Mac.app"');
shell.cd("../../");

log("Distribution created: Builds-" + revision + ".zip");
```

### Code Signing Override

```javascript
// Build without code signing (for CI)
xcode.build("MyApp.xcodeproj", {
  target: "MyApp",
  configuration: "Release",
  extraArgs: "CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO"
});
```

### Workspace Build

```javascript
// Build from workspace instead of project
xcode.rebuild("MyApp.xcworkspace", {
  target: "MyApp",
  configuration: "Release",
  sdk: "iphoneos"
});
```

## Platform Notes

- **macOS only**: Xcode build methods only work on macOS where Xcode is installed
- **Xcode Command Line Tools**: Must be installed (`xcode-select --install`)
- **Target names**: Use exact target names from Xcode (case-sensitive, including spaces)
- **SDK names**: Use short names (`iphoneos`) or versioned (`iphoneos17.0`)

## Related Documentation

- [MSBuild](MSBuild.md) - Building .NET and Elements projects on Windows
- [Shell](Shell.md) - Running external tools
- [XML](XML.md) - Reading Info.plist files
- [File](File.md) - File operations
- [Zip](Zip.md) - Creating distribution archives
