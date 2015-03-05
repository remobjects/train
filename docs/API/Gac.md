---
title: GAC (Global Assembly Cache)
---

Works with the Windows global assembly cache. (Fails on Posix!)

* **gac.install(fn)** Install a file in the gac. Requires admin access.
* **gac.uninstall(name)** Remove an assembly name (Full!) from the gac. Requires admin access.
* **gac.list("contains filter"): array of string** List the content of the gac with a filter.