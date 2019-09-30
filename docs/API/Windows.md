---
title: Windows
---

* **windows.createStartMenuShortcut(destPath, name,  description, subFolder)** creates shortcut in start menu.
<br/>**Note**: only `destPath` is required, other params are optional.
<br/><br/>examples:
```
windows.createStartMenuShortcut("C:/MyProgram.exe","My Program", "description", "My Company");
```
will create `%appdata%\Microsoft\Windows\Start Menu\My Company\My Program.lnk` referenced to `C:\MyProgram.exe`
```
windows.createStartMenuShortcut("C:/readme.txt");
```
will create `%appdata%\Microsoft\Windows\Start Menu\readme.lnk` referenced to `C:\readme.txt`

* **windows.createShortcut(destPath, name, folder, description)** creates shortcut in specified folder.
<br/>**Note**: only `destPath` is required, other params are optional.
<br/><br/>examples:
```
windows.createShortcut("C:/MyProgram.exe","My Program", "D:/folder1", "description");
```
will create `D:\folder1\My Program.lnk` referenced to `C:\MyProgram.exe`
```
windows.createShortcut("C:/readme.txt");
```
will create `C:\readme.lnk` referenced to `C:\readme.txt`


* **windows.getSpecialFolder(path): string** returns path to special folder. possible values:

  * AdminTools
  * ApplicationData
  * CDBurning
  * CommonAdminTools
  * CommonApplicationData
  * CommonDesktopDirectory
  * CommonDocuments
  * CommonMusic
  * CommonOemLinks
  * CommonPictures
  * CommonProgramFiles
  * CommonProgramFilesX86
  * CommonPrograms
  * CommonStartMenu
  * CommonStartup
  * CommonTemplates
  * CommonVideos
  * Cookies
  * Desktop
  * DesktopDirectory
  * Favorites
  * Fonts
  * History
  * InternetCache
  * LocalApplicationData
  * LocalizedResources
  * MyComputer
  * MyDocuments
  * MyMusic
  * MyPictures
  * MyVideos
  * NetworkShortcuts
  * Personal
  * PrinterShortcuts
  * ProgramFiles
  * ProgramFilesX86
  * Programs
  * Recent
  * Resources
  * SendTo
  * StartMenu
  * Startup
  * System
  * SystemX86
  * Templates
  * UserProfile
  * Windows
```
var fld = windows.getSpecialFolder("CommonStartMenu");
```