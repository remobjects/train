---
title: Xcode
---

* **xcode.clean(project, options)**  Cleans an Xcode project
* **xcode.build(project, options)**  Builds an Xcode project
* **xcode.rebuild(project, options)**  Rebuild an Xcode project

```
options: {
  configuration: The configuration to build
  target: the target to build
  sdk: the sdk to use
  destinationFolder: the target folder
  extraArgs: extra arguments to pass to xcodebuild.
}
```
