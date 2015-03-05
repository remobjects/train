---
title: Folder
---

* **folder.list(pathandmask, recurse): array of string** List the folders in a folder
* **folder.exists(filename):bool** returns true if a folder exists
* **folder.create(foldername)** create a folder (recursively if needed); will do nothing if the target exists
* **folder.move(sourcePath, destPath)** move 1 folder to another
* **folder.remove(foldername, recurse)** Remove a folder; will fail if it contains files/folders and recurse is false.
* **folder.setAttributes(folderName, recurse,  fileFlagsOptions)** Set the attributes of files in a folder. This is a plain object with ReadOnly, Hidden or Archive booleans.