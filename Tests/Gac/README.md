# Windows Fusion/GAC regression probe

Build with Elements:

```sh
ebuild Tests/Gac/Gac.elements --configuration:Release
```

On Windows with .NET Framework 4 installed, run both modes in separate processes:

```text
dotnet Tests/Gac/Bin/GacTests.dll cache
dotnet Tests/Gac/Bin/GacTests.dll list
```

Use each available dotnet process architecture (x86, x64, ARM64). The cache mode
checks the shared install/uninstall cache-creation path without installing or
removing an assembly. Both modes enumerate the real Framework GAC, exercise
filtered enumeration, and repeat calls after Fusion has been loaded. Non-Windows
hosts report SKIP; they cannot validate Windows Fusion loading.

To check the public script API in the rebuilt Train payload as well:

```text
dotnet Bin/Build/Release/Core/Train.dll Tests/Gac/PublicApi.train
```
