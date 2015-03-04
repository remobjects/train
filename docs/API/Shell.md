---
title: Shell
---

* **shell.cd("rel or absolute path")** << change the work directory. cd(env["scriptpath"]) gets you back
* **shell.cd("rel or absolute path", function() { .... })** change the path; run function and return to the original path.
* **shell.exec(path, args, options) **
```
options:{
  environment: object -- override the local environment
  timeout: Integer -- seconds; Negative timeout means don't wait at all
  workdir: String -- Work dir (null = none)
  capture: boolean or function -- if true returns the output as a string; if a function it gets called for any output from the app.
}
```
* **shell.execAsync(path, args, options): task** -- same as exec; returns task; no capture support
* **shell.system(command, workDir): string** -- execute through cmdspec/shell
* **shell.kill(task)** -- Kill a process task.