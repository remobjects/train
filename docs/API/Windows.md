---
title: Windows
---

* **windows.createStartMenuShortcut(destPath, name,  description, subFolder)** creates shortcut in start menu.

```
windows.createStartMenuShortcut("C:/MyProgram.exe","My Program", "description", "My Company");
```
will create `%appdata%\Microsoft\Windows\Start Menu\My Company\My Program.lnk` referenced to `C:\MyProgram.exe`