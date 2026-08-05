---
title: Command Line
---
RemObjects Train has a simple command command line and expects the main script as a single parameter.

```plain
RemObjects Train - JavaScript-based build automation
Copyright 2013-2026 RemObjects Software, LLC. All rights reserved.

Train <script.train> [options]

  -o, --options=VALUE        Override the ini file with the global options
  -c, --colors               Use colors
  -d, --debug                Show debug-level messages
  -w, --warning              Show warning messages
  -i, --hint                 Show hint messages
  -m, --message              Show info messages
  -h, -?, --help             Show detailed help
  -v, --var=NAME:VALUE       Define global vars; sets name=value; multiple allowed
      --xslt=VALUE           Override XSLT for html output
  -t, --html=VALUE           Write HTML log to file
  -x, --xml=VALUE            Write XML log to file
      --plugin=VALUE         Use this folder to load plugins
      --include=VALUE        Include a script
      --wait                 Wait for a key press before finishing
      --dryrun               Do a script dry run (skips file/exec actions)
  -l, --lfnenter             Enable/Disable function enter/exit logging
```

The most common parameters will be `-v` to pass custom global/environment variables to the script, and `-t` to emit a human-readable log file. For example:

```
train MyScript.train -vSomeVariable=foo -t=MyScript.html
```

## Train.ini

An optional `Train.ini` file can be placed next to the Train executable to provide paths to well-known tools used by Train APIs. The following values are supported:

```
[Globals]
SVN=C:\Program Files\SlikSvn\bin\svn.exe
GIT=C:\Program Files (x86)\Git\bin\git.exe
MSBuild=C:\Windows\Microsoft.NET\Framework\v4.0.30319\MsBuild.exe
RC=C:/Program Files (x86)/Microsoft.NET/SDK/v2.0/Bin/rc.exe
ISCC=C:/Program Files (x86)/Inno Setup 5/iscc.exe
```
