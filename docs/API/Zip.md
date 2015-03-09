---
title: ZIP Files
---

The `zip` object provides static methods for working with .zip archive files:

## zip.compress()

```
zip.compress(zip, path, fileMask, recurse)
```

Create a new .zip file with specified file(s). The `fileMasks` may contain wildcards and relative paths to include portion of the path in the zip itself.

```
zip.compress("c:/output/my.zip", "c:/input", "file1.ext;file2.ext", false);
zip.compress("c:/output/my.zip", "c:/input", "file1.ext;file2.ext", false);
zip.compress("c:/output/my.zip", "c:/input", "subfolder/*.*", true);
```

## zip.list()

```
function zip.list(zip): array of zipEntryData { name, size, compressedSize }
```

Returns a list of all files in the zip archive.

## zip.extractFile()

```
function zip.extractFile(zip, localTarget, fileInZip)
```

Extract a file from the zip archive to the local disk.  If `localTarget` ends on a path separator, it is treated as folder name, and the filename will be derived from the orogonalfile. If it does not, `localTarget` will be the destination file.

## zip.extractFiles()

```
zip.extractFiles(zip, localTarget, fileInZipArray, aFlatten = false)
```
Extract multiple files from a zip. Passing `null` or omitting `entriesArray` will extract _all_ files in the archive.
