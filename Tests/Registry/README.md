# Registry-view regression tests

Build Train Release, then build the Oxygene harness with Elements:

```sh
ebuild Train.sln --configuration:Release
ebuild Tests/Registry/Registry.elements --configuration:Release
```

Run from an elevated Windows terminal, supplying paths to the rebuilt Train,
public API fixture, and actual CI2 Delphi include:

```text
dotnet Tests/Registry/Bin/RegistryTests.dll Bin/Build/Release/Core/Train.dll Tests/Registry/PublicApi.train "../ci2/Train Scripts/CI2DelphiShared.train"
```

Run under x86 and x64 dotnet (and ARM64 where available) on 64-bit Windows.
The harness creates a uniquely named temporary HKLM Software key in each view,
verifies actual Train script reads/writes and unchanged default-view behavior,
and removes both keys in a finally block. Missing keys/values, empty and unnamed
values, invalid views/hives, and key creation are covered.

The actual CI2 include is also executed with an isolated registry lookup stub:
missing, empty, whitespace-only, nonexistent-directory, and valid-directory
cases. The machine's real CI2 configuration is never changed. Non-Windows hosts
report SKIP.
