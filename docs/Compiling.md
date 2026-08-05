---
status: needs-review
title: Building Train
---

This page guides you though what is needed to build Train yourself, from the source code on [GitHub](https://www.github.com/remobjects/train).

## Before compiling

* Install [Elements](https://www.elementscompiler.com/elements/download) with EBuild.
* Install the .NET 10 runtime for each machine on which Train will run.
* Clone the Train repository: `git clone https://github.com/remobjects/train.git`.

## Compiling

Open `Train.sln` in Fire or build it from the command line:

```shell
ebuild Train.sln --configuration:Release
```

Train is a .NET 10 application; there is no separate Classic/Mono target or target-selection setting. Build products are written to `Bin/Build/<Configuration>/Core`.

## Running

The build emits a managed entry point, `Train.dll`, plus framework-dependent launchers for every supported platform architecture:

* Windows: `Train-win-x64.exe`, `Train-win-x86.exe`, and `Train-win-arm64.exe`
* macOS: `Train-osx-x64` and `Train-osx-arm64`
* Linux: `Train-linux-x64` and `Train-linux-arm64`

Use the launcher matching the destination machine, for example:

```shell
Bin/Build/Release/Core/Train-osx-arm64 path/to/script.train
```

You can also use `dotnet Bin/Build/Release/Core/Train.dll path/to/script.train`. The output is framework-dependent, so the matching .NET 10 runtime must be installed; Mono is not used.
