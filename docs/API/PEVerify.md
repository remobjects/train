---
title: PEVerify
---

These APIs sepxect a PEVerify env var to be set.

* **peverify.verifyFile(aFilename, aErrorCodesToIgnore)** Checks if a .NET pe file is valid and fail if it's not
* **peverify.verifyFolder(aFolderName, aSearchPattern, aOptions: array of {Filename, ErrorIgnoreCodes})** Checks if a .NET pe file is valid and fail if it's not