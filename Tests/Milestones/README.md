# CI milestone regression probe

```sh
ebuild Train.sln --configuration:Release
ebuild Tests/Milestones/Milestones.elements --configuration:Release
dotnet Tests/Milestones/Bin/MilestoneTests.dll Bin/Build/Release/Core/Train.dll
```

The Oxygene harness runs the real Train script API in normal, dry-run and debug
modes. It verifies the exact CI2 markers in stdout and XML, whitespace trimming,
and suppression of empty/null milestones. Temporary files are removed afterward.
It does not contact CI2 or queue a build.
