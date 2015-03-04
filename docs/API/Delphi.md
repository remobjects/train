---
title: Delphi
---
* **delphi.getBasePath(delphi)** returns the path where Delphi is installed.
* **delphi.build(project, options)** build a delphi project;
```
options: {
  dcc: string; // overrides any version
  delphi: string;
  platform: string;
  aliases: string;
  conditionalDefines: array of string;
  destinationFolder: string;
  dcuDestinationFolder: string;
  includeSearchPath: string;
  unitSearchPath:string;
  namespaces: string
  otherParameters: string;
  updateIcon: string
  updateVersionInfo: {
    codePage: UInt16;
    resLang: UInt16;
    isDll: Boolean;
    version: String;
    fileVersion: String;
    company: String;
    description: String;
    legalCopyright: String;
    legalTrademarks: String;
    productName: String;
    title: String;
    extraFields: EcmaScriptObject;
    }
```