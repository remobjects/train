namespace RemObjects.Builder.API;

interface

uses 
  RemObjects.Builder,
  RemObjects.Script.EcmaScript, 
  RemObjects.Script.EcmaScript.Internal, 
  System.Xml.Linq,
  System.IO,
  System.Runtime.InteropServices;

type
  [PluginRegistration]
  XmlPlugin = public class(IPluginRegistration)
  private
  public
    method &Register(aServices: IApiRegistrationServices);

    [WrapAs('xml.fromFile', SkipDryRun := true)]
    class method xmlFromFile(aServices: IApiRegistrationServices; aFN: string): XElement;
    [WrapAs('xml.fromString', SkipDryRun := true)]
    class method xmlFromString(aServices: IApiRegistrationServices; aString: string): XElement;

    [WrapAs('xml.toFile', SkipDryRun := true, wantSelf := true)]
    class method xmlToFile(aServices: IApiRegistrationServices; aSelf: XElement; aFN: string);
    [WrapAs('xml.toString', SkipDryRun := true, wantSelf := true)]
    class method xmlToString(aServices: IApiRegistrationServices; aSelf: XElement): string;
    [WrapAs('xml.xpath', SkipDryRun := true, wantSelf := true)]
    class method xmlXpath(aServices: IApiRegistrationServices; aSelf: XElement; aPath: String): XElement;
    [WrapAs('xml.value', SkipDryRun := true, wantSelf := true)]
    class method xmlValue(aServices: IApiRegistrationServices; aSelf: XElement): string;
  end;


implementation

method XmlPlugin.&Register(aServices: IApiRegistrationServices);
begin
  var lProto := new EcmaScriptObject(aServices.Globals);
  lProto.AddValue('toFile', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, typeof(self), 'xmlToFile')); 
  lProto.AddValue('toString', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, typeof(self), 'xmlToString')); 
  lProto.AddValue('xpath', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, typeof(self), 'xmlXpath'));
  lProto.DefineOwnProperty('value', new PropertyValue(PropertyAttributes.Enumerable, RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, typeof(self), 'xmlValue'), nil)); 
  
  

  aServices.RegisterObjectValue('xml')
    .AddValue('fromFile', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, typeof(self),'xmlFromFile'))
    .AddValue('fromString', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, typeof(self),'xmlFromString'));
end;

class method XmlPlugin.xmlFromFile(aServices: IApiRegistrationServices; aFN: string): XElement;
begin
  XElement.Load(aServices.ResolveWithBase(aFN));
end;

class method XmlPlugin.xmlFromString(aServices: IApiRegistrationServices; aString: string): XElement;
begin
  exit XElement.Parse(aString);
end;

class method XmlPlugin.xmlToFile(aServices: IApiRegistrationServices; aSelf: XElement; aFN: String);
begin
  aSelf.Save(aSErvices.ResolveWithBase(aFN));
end;

class method XmlPlugin.xmlToString(aServices: IApiRegistrationServices; aSelf: XElement): string;
begin
  exit aSelf.ToString;
end;

class method XmlPlugin.xmlXpath(aServices: IApiRegistrationServices; aSelf: XElement; aPath: String): XElement;
begin
  exit System.Xml.XPath.Extensions.XPathSelectElement(aSelf, aPath);
end;

class method XmlPlugin.xmlValue(aServices: IApiRegistrationServices; aSelf: XElement): string;
begin
  exit aSelf.Value;
end;

end.
