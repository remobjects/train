---
title: XML Files
---

Read, modify, and query XML files using XPath. This is commonly used for configuration files, .plist files (macOS/iOS), and project files.

## Quick Reference

* **xml.fromFile(filename)** - Load XML file from disk
* **xml.fromString(xmlString)** - Parse XML from string
* **xml.xpath(expression)** - Query XML using XPath
* **xml.toFile(filename)** - Save XML to file
* **xml.toString()** - Convert XML to string

## Loading XML

### xml.fromFile(filename)

Loads an XML file and returns an xml object.

```javascript
// Load XML file
var config = xml.fromFile("config.xml");

// Load macOS/iOS Info.plist
var infoPlist = xml.fromFile("Info.plist");

// Load project file
var projectXml = xml.fromFile("Project.csproj");
```

### xml.fromString(xmlString)

Parses XML from a string and returns an xml object.

```javascript
var xmlContent = '<config><version>1.0.0</version></config>';
var config = xml.fromString(xmlContent);
```

## Saving XML

### xml.toFile(filename)

Saves the XML object to a file.

```javascript
var config = xml.fromFile("config.xml");
// ... modify config ...
config.toFile("config.xml");
```

### xml.toString()

Returns the XML as a string.

```javascript
var config = xml.fromFile("config.xml");
var xmlString = config.toString();
log(xmlString);
```

## Querying XML with XPath

### xml.xpath(query)

Runs an XPath query and returns a sequence of matching nodes/values. Returns an xml object that can be iterated or converted to string.

```javascript
// Query for all version elements
var versions = config.xpath("//version");

// Query with predicate
var releaseVersion = config.xpath("/config/version[@type='release']");

// Query for text content
var versionText = config.xpath("//version/text()");
var version = versionText.toString();
```

### xml.xpathElement(query)

Runs an XPath query and returns a single element. Useful when you expect exactly one result.

```javascript
// Get single element
var versionElement = config.xpathElement("/config/version");
var version = versionElement.value;
```

### xml.value

Returns the string value of the current XML node.

```javascript
var versionElement = config.xpathElement("//version");
var versionString = versionElement.value;  // Gets text content
```

## XPath Examples

### Reading Info.plist (macOS/iOS)

Info.plist files use a specific XML format with key-value pairs:

```javascript
// Load Info.plist
var infoPlist = xml.fromFile("MyApp-Info.plist");

// Extract CFBundleVersion
// The structure is: <key>CFBundleVersion</key><string>1.0</string>
var versionElement = infoPlist.xpath("/plist/dict/key[.='CFBundleVersion']/following-sibling::*[1]/text()");
var version = versionElement.toString();

log("Bundle version: " + version);

// Extract CFBundleIdentifier
var bundleIdElement = infoPlist.xpath("/plist/dict/key[.='CFBundleIdentifier']/following-sibling::*[1]/text()");
var bundleId = bundleIdElement.toString();

log("Bundle ID: " + bundleId");
```

### Reading Configuration Files

```javascript
var config = xml.fromFile("app.config");

// Get database connection string
var connString = config.xpath("//configuration/connectionStrings/add[@name='MainDB']/@connectionString");
log("Connection: " + connString.toString());

// Get app setting
var settingValue = config.xpath("//appSettings/add[@key='ApiKey']/@value");
log("API Key: " + settingValue.toString());
```

### Reading Project Files

```javascript
var project = xml.fromFile("MyProject.csproj");

// Get target framework
var framework = project.xpath("//Project/PropertyGroup/TargetFramework/text()");
log("Target: " + framework.toString());

// Get all package references
var packages = project.xpath("//PackageReference/@Include");
// Note: packages is a sequence, convert to string to see all
log("Packages: " + packages.toString());
```

## XSLT Transformation

### xml.xsltTransform(xsltFile)

Transforms the XML using an XSLT stylesheet.

```javascript
var sourceXml = xml.fromFile("data.xml");
var transformedXml = sourceXml.xsltTransform("transform.xslt");

// Save transformed result
transformedXml.toFile("output.xml");
```

## Complete Examples

### Extract and Use Version from Info.plist

```javascript
// Build Xcode project
xcode.build("MyApp.xcodeproj", {
  target: "MyApp",
  configuration: "Release"
});

// Extract version from Info.plist
var infoPlist = xml.fromFile("MyApp-Info.plist");
var versionElement = infoPlist.xpath("/plist/dict/key[.='CFBundleVersion']/following-sibling::*[1]/text()");
var version = versionElement.toString().trim();

log("Built version " + version);

// Create versioned ZIP
var zipName = "MyApp-" + version + ".zip";
zip.compress(zipName, "./Build/Release/MyApp.app", "*.*", true);

log("Created: " + zipName);
```

### Modify XML Configuration

```javascript
var config = xml.fromFile("config.xml");

// Note: Modifying XML in Train is limited
// For complex modifications, consider:
// 1. Reading the file as text with file.read()
// 2. Using string replace operations
// 3. Writing back with file.write()

// Read as text for modification
var configText = file.read("config.xml");
configText = configText.replace('<version>1.0.0</version>', '<version>2.0.0</version>');
file.write("config.xml", configText);
```

### Validate XML Structure

```javascript
// Check if expected elements exist
var config = xml.fromFile("config.xml");

var dbElement = config.xpath("//database");
if (dbElement.toString() == "") {
  error("Configuration missing database section");
}

var hostElement = config.xpath("//database/host/text()");
if (hostElement.toString() == "") {
  error("Database host not configured");
}

log("Configuration validated");
```

### Read Multiple Values

```javascript
var project = xml.fromFile("Project.csproj");

// Get assembly name
var assemblyName = project.xpath("//AssemblyName/text()").toString();

// Get output type
var outputType = project.xpath("//OutputType/text()").toString();

// Get target framework
var targetFramework = project.xpath("//TargetFramework/text()").toString();

log("Project: " + assemblyName);
log("Type: " + outputType);
log("Framework: " + targetFramework);
```

## XPath Quick Reference

Common XPath patterns used in Train scripts:

```javascript
// Select element by name
xml.xpath("//elementName")

// Select element by path
xml.xpath("/root/parent/child")

// Select element with attribute
xml.xpath("//element[@attr='value']")

// Select attribute value
xml.xpath("//element/@attribute")

// Select text content
xml.xpath("//element/text()")

// Select sibling after specific key (for plist files)
xml.xpath("//key[.='KeyName']/following-sibling::*[1]")

// Select first matching element
xml.xpathElement("/root/element")
```

## Platform Notes

- XML parsing uses standard XML libraries available on all platforms
- XPath 1.0 syntax is supported
- For .plist files (macOS/iOS), remember they use a key/value dictionary structure
- Train's XML modification capabilities are limited - for complex changes, use text manipulation with [file.read()](File.md) and [file.write()](File.md)

## Related Documentation

- [File](File.md) - Reading/writing files as text
- [INI](INI.md) - INI configuration files
- [Xcode](Xcode.md) - Building Xcode projects (uses Info.plist)
- [Globals](Globals.md) - String manipulation functions
