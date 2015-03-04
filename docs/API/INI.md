---
title: INI Files
---

* **ini.fromFile(fn) : ini** Load an ini file from a file
* **ini.fromString(val) : ini** Load an ini file from a string
* **new ini(): ini** Create a new ini file (empty)
 * **.toFile(fn)** Save the ini file to a file
 * **.toString()** Returns the ini as a string
 * **.getValue(sec, key, default): string** Get a value
 * **.setValue(sec, key, value)** Set a value
 * **.deleteSection(sec)** Delete a section
 * **.deleteValue(sec, key)** Delete a value
 * **.keysInSection(sec)** Returns a list of keys in a section
 * **.sections(): array of string** returns the sections