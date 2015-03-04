---
title: Globals
---


* **wd** - Work directory
* **env** - Environment
* **sleep(msec)** - sleep for a given number of msec.
* **export(key, value)** - Sets an environment in the "root" environment so it persists in the parent script environment.
* **ignoreErrors(function() { .. })** - Run the code in the passed function but catch and ignore any errors that happen.
* **retry(c, function() { .. })** - Run the code in the passed function c times until it fails.
* **async(function() { .. })** - Run code async in another thread; Returns a task that can be waited for
* **run(scriptFN)** - Run a script (blocking)
* **runAsync(scriptFN)** - Runs a script asynchronously; returns a task that can be waited for
* **include(scriptFn)** - Include the content of a script in the current script
* **waitFor(tasksArray, timeout)** - Timeout is optional (infinite by default); raises any exception that was thrown in the async ones.
* **expand(value)** - Expands $name or $(name) to the js variable; $$ becomes $.