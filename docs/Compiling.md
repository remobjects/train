---
title: Compiling

---
## Before compiling

1. Get Oxygene. The command line compiler is free, or there's a trial of the full Visual Studio integrated version. Download at
[RemObjects.com/trials#oxygene](http://www.remobjects.com/trials#oxygene).
2. Clone the Train repository: `git clone https://github.com/remobjects/train.git`
3. Do `git submodule update --init` to get the "script" repository. 
4. **Script\Source\RemObjects.Script\Properties\AssemblyInfo.pas** has a [assembly: AssemblyKeyName('RemObjectsSoftware')], comment that out (or create & install a "RemObjectsSoftware" key). 

## Compiling with Visual Studio

Compile in Visual Studio by opening **..\RemObjects.Train.sln** and building it. The resulting output files are in **..\Train\bin\Debug**.  The compiled binary is **Train.exe**

## Compiling at the Command Line

Use msbuild: `msbuild RemObjects.Train.sln /p:Configuration=Release`

(Note: if msbuild isn't in your path, it's probably located at C:\Windows\Microsoft.NET\Framework\V4.0.30319\msbuild.exe)

Your resulting output files are in **Train/bin/Release**.