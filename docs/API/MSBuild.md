---
title: MSBuild
---
* **msbuild.build(project, options)** Build a project (only if not changed)
* **msbuild.rebuild(project, options)** Rebuild a project (force a build)
* **msbuild.clean(project, options)** Clean a project
* **msbuild.custom(project, options)** Call msbuild without a target

```
options:{
    configuration: string
    platform: string
    destinationFolder: string
    extraArgs: string
    toolsVersion: string  << accepted values "2","2.0","3.5","4","4.0"
}  
```

* **msbuild.updateAssemblyVersion(files, assemblyVersion, fileversion)** << fileVersion defaults to assemblyversion unless given.
```
msbuild.updateAssemblyVersion("AssemblyInfo.cs", MyVersion);
msbuild.updateAssemblyVersion("AssemblyInfo.pas", MyVersion);
```
