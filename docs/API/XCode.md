---
title: XCode
---

* **xcode.clean(project, options)**  Cleans an xcode project
* **xcode.build(project, options)**  Builds an xcode project
* **xcode.rebuild(project, options)**  Rebuild an xcode project

```
options: {
  configuration: The configuration to build
  target: the target to build
  sdk: the sdk to use
  destinationFolder: the target folder
  extraArgs: extra arguments to pass to xcodebuild.
}
```
