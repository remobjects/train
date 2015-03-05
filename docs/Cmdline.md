---
title: Command Line
---
RemObjects Train has a simple command command line and expects the main script as a single parameter.

```
RemObjects Train - JavaScript-based build automation
Copyright (c) RemObjects Software, 2013. All rights reserved.
Train.exe <script.js> [options]
  -o, --options=VALUE        Override the ini file with the global options
  -c, --colors               Use colors
  -d, --debug                Show debugging messages
  -w, --warning              Show warning messages
  -i, --hint                 Show hint messages
  -m, --message              Show info messages
  -h, -?, --help             show help
  -v, --var=name:value       Defines global vars; sets name=value; multiple allowed
      --xslt=VALUE           Override XSLT for html output
  -t, --html=VALUE           Write HTML log to file
  -x, --xml=VALUE            Write XML log to file
      --plugin=VALUE         use this folder to load plugins
      --include=VALUE        Include a script
      --wait                 Wait for a key before finishing
      --dryrun               Do a script dry run (skips file/exec actions)
  -l, --lfnenter             Enable/Disable function enter/exit logging
```