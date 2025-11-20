---
status: needs-review
title: Building Train
---

This page guides you though what is needed to build Train yourself, from the source code on [GitHub](https://www.github.com/remobjects/train).

## Before compiling

Train can be built with .Net 4.5 and later.

* Get Oxygene [here](http://www.elementscompiler.com/elements/download). <br />The command line compiler is free, and there's a trial version integrated in Visual Studio or [Fire](http://remobjects.com/fire) (macOS IDE) or [Water](http://remobjects.com/water) (Windows IDE).
* Clone the Train repository: `git clone https://github.com/remobjects/train.git`
* Run `git submodule update --init` to get the "script" repository.
* **Script\Source\RemObjects.Script\Properties\AssemblyInfo.pas** has a line reading `[assembly: AssemblyKeyName('RemObjectsSoftware')]`, comment that out (or create & install a "RemObjectsSoftware" key using the `sn` tool).

## Compiling in Fire, Water, or Visual Studio

Open **Train.sln** and build it. The resulting output files are in **Train/Bin/Debug**. The compiled binary is **Train.exe**.

You will need [Mono](http://www.go-mono.com) to run Train on macOS (and Linux).

## Compiling from the Command Line

Use EBuild to compile Train:

```bash
# Windows
ebuild Train.sln --configuration:Release

# macOS/Linux
ebuild Train.sln --configuration:Release
```

Your resulting output files are in **Train/bin/Release**.

**Note**: You need the Elements compiler installed. The command line compiler is free - get it at [elementscompiler.com](http://www.elementscompiler.com/elements/download).
