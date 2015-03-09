---
title: ZIP Files
---

* **zip.compress(zip, inputFN, fileMask, recurse, aPassword)** Create a new zip file with the input files in it
```
zip.compress("c:/output/my.zip", "c:/input", "file1.ext;file2.ext", false);
zip.compress("c:/output/my.zip", "c:/input", "file1.ext;file2.ext", false, "my pass");
```
* **zip.list(zip): array of zipEntryData { name, size, compressedSize }** List the content of a zip file
* **zip.extractFile(zip, aDestPath, entry)** Extract a file from a zip
* **zip.extractFiles(zip, aDestPath, entriesArray, aFlatten = false)** Extract multiple files from a zip
