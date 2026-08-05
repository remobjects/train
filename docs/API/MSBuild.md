---
title: MSBuild
---

Build .NET and Elements projects using MSBuild. This works with Visual Studio solutions and project files.

**Note**: While MSBuild can build Delphi projects, Train has dedicated [Delphi support](Delphi.md) with more control over Delphi-specific options.

## Quick Reference

* **msbuild.rebuild(project, options)** - Rebuild a project from scratch (most common)
* **msbuild.build(project, options)** - Incremental build
* **msbuild.clean(project, options)** - Clean build outputs
* **msbuild.custom(project, target, options)** - Run custom MSBuild target
* **msbuild.updateAssemblyVersion(asminfo, version, fileVersion, informationalVersion)** - Update AssemblyInfo.cs version numbers

## Building Projects

### msbuild.rebuild(project, [options])

Rebuilds a project or solution from scratch. This is the most commonly used method - it ensures a clean build by deleting intermediate files first.

```javascript
// Simple rebuild (uses Debug configuration by default)
msbuild.rebuild("Project.sln");

// Release build
msbuild.rebuild("MyApp.csproj", {
  configuration: "Release"
});

// Multi-architecture build
var architectures = ["x86", "x64", "arm64"];
for (var i = 0; i < architectures.length; i++) {
  msbuild.rebuild("CrossPlatform.sln", {
    configuration: "Release",
    platform: architectures[i]
  });
}

// With additional MSBuild properties
msbuild.rebuild("Library.csproj", {
  configuration: "Release",
  platform: "AnyCPU",
  extraArgs: "/p:DefineConstants=TRACE;DEBUG /p:OutputPath=../Bin"
});
```

### msbuild.build(project, [options])

Builds a project incrementally (only rebuilds changed files). Faster than `rebuild()` but may not catch all changes.

```javascript
// Incremental build for faster iteration
msbuild.build("Project.sln", {
  configuration: "Debug"
});
```

Use `rebuild()` for release builds and CI to ensure consistency. Use `build()` for fast local development iteration.

### msbuild.clean(project, [options])

Removes all build outputs for a project.

```javascript
// Clean before rebuild
msbuild.clean("Project.sln", { configuration: "Release" });
msbuild.rebuild("Project.sln", { configuration: "Release" });
```

### msbuild.custom(project, [options])

Runs MSBuild without specifying a target. Useful for custom MSBuild targets defined in your project.

```javascript
// Run custom target
msbuild.custom("Build.proj", {
  extraArgs: "/t:CustomTarget /p:CustomProperty=Value"
});
```

## Configuration Options

All build methods accept an options object with these properties:

**configuration** - Build configuration name (default: "Debug")
- Common values: "Debug", "Release"
- Can be any configuration defined in your solution

**platform** - Target platform (default: solution default)
- Common values: "AnyCPU", "x86", "x64", "arm64"
- Must match platforms defined in your solution

**destinationFolder** - Override output directory
- Sets MSBuild's `OutputPath` property
- Useful for collecting outputs in a central location

**extraArgs** - Additional MSBuild command-line arguments
- Pass any MSBuild switches or properties
- Format: "/p:Property=Value /t:Target"

**toolsVersion** - MSBuild tools version to use
- Values: "2", "2.0", "3.5", "4", "4.0"
- Usually not needed - MSBuild auto-detects

```javascript
// Using all options
msbuild.rebuild("Complete.sln", {
  configuration: "Release",
  platform: "x64",
  destinationFolder: "./Bin/Release/x64",
  extraArgs: "/p:Version=1.0.0 /p:DebugSymbols=false",
  toolsVersion: "4.0"
});
```

## Version Management

### msbuild.updateAssemblyVersion(file, version, [fileVersion])

Updates version numbers in AssemblyInfo files before building. Works with C#, VB.NET, and Pascal (Elements) files.

```javascript
// Update version before build
var version = "2.5.1.0";
msbuild.updateAssemblyVersion("Properties/AssemblyInfo.cs", version);
msbuild.rebuild("Project.csproj", { configuration: "Release" });

// Use different file version
msbuild.updateAssemblyVersion("Properties/AssemblyInfo.pas",
  "2.5.1.0",      // Assembly version
  "2.5.1.5000"    // File version (includes build number)
);

// Update multiple files
var files = [
  "Project/Properties/AssemblyInfo.cs",
  "Library/Properties/AssemblyInfo.cs"
];
for (var i = 0; i < files.length; i++) {
  msbuild.updateAssemblyVersion(files[i], version);
}
```

The version parameter should be in format "Major.Minor.Build.Revision" (e.g., "1.2.3.4").

If `fileVersion` is not provided, both AssemblyVersion and AssemblyFileVersion are set to the same value.

## Examples

### Release Build for Multiple Platforms

```javascript
export("version", "1.0.0.0");

// Update versions
msbuild.updateAssemblyVersion("Properties/AssemblyInfo.cs", expand("$(version)"));

// Build each platform
var platforms = ["x86", "x64"];
for (var i = 0; i < platforms.length; i++) {
  var platform = platforms[i];
  log("Building " + platform + " release");

  msbuild.rebuild("Application.sln", {
    configuration: "Release",
    platform: platform,
    destinationFolder: "./Bin/Release/" + platform
  });
}

log("All platforms built successfully");
```

### CI Build with Versioning

```javascript
// Get version from environment or Git
var version = env["CI_VERSION"] || "1.0.0.0";
var commit = env["CI_COMMIT"] || "dev";

log("Building version " + version + " from commit " + commit);

// Update assembly versions
msbuild.updateAssemblyVersion("App/Properties/AssemblyInfo.cs", version);
msbuild.updateAssemblyVersion("Library/Properties/AssemblyInfo.cs", version);

// Clean and rebuild
msbuild.clean("Solution.sln", { configuration: "Release" });
msbuild.rebuild("Solution.sln", {
  configuration: "Release",
  extraArgs: "/p:SourceRevisionId=" + commit
});
```

### RemObjects CrossBox Build

CrossBox enables cross-compilation - build macOS/Linux binaries from Windows, or Windows binaries from Mac.

```javascript
// Configure CrossBox server
export("crossBoxServer", "mac-build-server.local");

// Build using CrossBox remote Mac
msbuild.rebuild("CrossPlatformLib.sln", {
  configuration: "Release",
  extraArgs: expand("/p:CrossBox=$(crossBoxServer);CrossBoxDeviceID=Mac;CrossBoxDevice=Mac")
});
```

See also [Xcode](Xcode.md) for building macOS/iOS projects and [Shell](Shell.md) for running other build tools.
