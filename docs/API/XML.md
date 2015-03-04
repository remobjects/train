---
title: XML Files
---

* **xml.fromFile(fn):xml** load xml from file, returns an xml object (see below)
* **xml.fromString(data):xml** load xml from string, returns an xml object (see below)

## Xml Object

 * **.toFile(fn)** -- save to file
 * **.toString(): string** - save to string
 * **.xpath(query): xml** -- run xpath query and returns a sequence of items
 * **.xpathElement(query): xml** -- run xpath query and returns a single element
 * **.value** -- returns the string value
 * **.xlstTransform(aXSLTFile: String)** transforms the xml based on an xlst file.