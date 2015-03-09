---
status: needs-review
title: Building Train
---

This page guides you though what is needed to build Train yourself, from the source code on [GitHub](https://www.github.com/remobjects/train).

## Before compiling

* Get Oxygene [here](http://www.elementscompiler.com/elements/download). <br />The command line compiler is free, and there's a trial version integrated in Visual Studio or [Fire](http://remobjects.com/fire).
* Clone the Train repository: `git clone https://github.com/remobjects/train.git`
* Run `git submodule update --init` to get the "script" repository.
* **Script\Source\RemObjects.Script\Properties\AssemblyInfo.pas** has a line reading `[assembly: AssemblyKeyName('RemObjectsSoftware')]`, comment that out (or create & install a "RemObjectsSoftware" key using the `sn` tool).

## Compiling in Fire or Visual Studio

Compile in Visual Studio by opening **RemObjects.Train.sln** and building it. The resulting output files are in **Train/Bin/Debug**. The compiled binary is **Train.exe**.

You will need [Mono](http://www.go-mono.com) to run Train on Mac (and Linux).

## Compiling from the Command Line on Windows

Use msbuild: `msbuild RemObjects.Train.sln /p:Configuration=Release`

(Note: if msbuild isn't in your path, it's probably located at `C:\Windows\Microsoft.NET\Framework\V4.0.30319\msbuild.exe`)

Your resulting output files are in **Train\bin\Release**.

## Compiling from the Command Line on Mac or Linux

You will need to install [Mono](http://www.go-mono.com) to build (and use) Train on Mac and Linux.

Once done, use xbuild: `xbuild RemObjects.Train.sln /p:Configuration=Release`

Your resulting output files are in **Train/bin/Release**.
