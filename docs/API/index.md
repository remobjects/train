---
status: needs-review
title: API
index: Globals.md
index: Logging.md
index: -
index: MSBuild.md
index: Xcode.md
index: Delphi.md
index: -
index: File.md
index: Folder.md
index: Path.md
index: FTP.md
index: HTTP.md
index: S3.md
index: -
index: Zip.md
index: ISO.md
index: XML.md
index: INI.md
index: -
index: GAC.md
index: PEVerify.md
index: Registry.md
index: Shell.md
index: SSH.md
index: InnoSetup.md
index: Mail.md
index: MD5.md
---

All scripts have access to the environment variables via an indexer variable called called `env`. The environment is linked inherited from the parent environment.

When setting values on `env`, they are stored on the current envirnment. Reading `env` first checks the current environment, then the parent ones until it finds a value (or returns `Undefined`).

Paramaters to Train APIs can use known variables inline using a `$(VariableName)` syntax, and are automatically expanded. This can be escaped using a double dollar sign, `$$`.

## Working directory

Each script has it's own work directory, stored in the global `wd` property, preset to the script's location on disk. When including sub-scripts, the working directory changes as execution enters and exits the main flow of these sub-scripts.

All file operations are relative to the work directory, unless absolute oaths are provided. When a path starts with "~/" it's resolved to the user home dir.

On Windows, the forward slash "`/`" can be used in all filename parameters, and will be replaced with "`\`" internally. This makes it easy to write cross-platform scripts that can use "`/`" consistently, and avoids having to worry about escaping the "`\`" character in JavaScript string literals.

