---
title: SSH
---

* **ssh.execute(host, command, user, password)**  password optional; If no password is passed one of the keys loaded through loadKey will be used.
* **ssh.loadKey(fn, password)** -- load an openssh key
* **sftp.connect(host, path, username, password): sftp connection**

The returned object supports these APIs:
 * **.close** -- close the connection
 * **.listFiles(path): array of string** -- list all files in the given path.
 * **.listFolders(path): array of string** -- list all folders in the given path.
 * **.download(remote, local)** Download a file to a local file
 * **.upload(local, remote)** Upload a local file