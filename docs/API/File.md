---
title: File
---

* **file.setAttributes(fileName, fileFlagsOptions)** set the attributes of a file; This is a plain object with ReadOnly, Hidden or Archive booleans.
* **file.copy(sourceFileMask, destFileOrFolder, recurse = false, overwrite = true)** Copy 1 or more files/directories to a target. Recurse will recurse into directories, if overwrite is false it will fail if the file already exists.
* **file.move(sourceFileMask, destFileOrFolder, delete)** Copy 1 or more files/directories to a target. Recurse will recurse into directories, if overwrite is false it will fail if the file already exists.
* **file.list(pathandmask, recurse): array of string** Show a list of files given a mask; recurse defines if it shows files in sub directories.
* **file.remove(filename)** Remove a file
* **file.read(filename): string** Read a file and return the content as a string
* **file.write(filename, data)** Write a file with a string as content
* **file.append(filename, data)** Append a string to a file
* **file.exists(filename): bool** Check if a file exists