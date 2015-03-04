---
title: Inno Setup
---
* **inno.build(script, options)** Build an innosetup script; Uses an InnoSetup env containing the Innosetup install path, else the HKLM key if available.
```
options: {
    destinationFolder
    extraArgs
    defines: array of string
}
```