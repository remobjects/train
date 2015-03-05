---
title: Api
index: Globals.md
index: -
index: Delphi.md
index: File.md
index: Folder.md
index: FTP.md
index: Gac.md
index: Http.md
index: INI.md
index: Images.md
index: InnoSetup.md
index: Logging.md
index: Mail.md
index: MD5.md
index: MSBuild.md
index: Path.md
index: PEVerify.md
index: Registry.md
index: Shell.md
index: SSH.md
index: XCode.md
index: XML.md
index: Zip.md
---

All scripts have an environment called "env", environments are linked to the parent environment. this is a variable that can be used to access any environment variable as defined by the parent process.

When setting something on env it's stored on the current envirnment. Reading first checks the current one, then the parent ones until it finds one (or returns undefined). 


## Work directory

Each script has it's own work directory, stored in the global **"wd"** property. All file operations are relative to the work directory, when a path starts with "~/" it's resolved to the user home dir. On Windows / is replaced with \ when used. 

All arguments are automatically expanded, it turns $(Test) into the local or environment value _Test_, if 'Test' is not available in the scope and environment it leaves it as-is, use $$ when you want $.
