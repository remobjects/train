namespace RemObjects.Train.API;

interface

uses 
  RemObjects.Train,
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
    class method xmlFromFile(aServices: IApiRegistrationServices; aFN: String): XElement;
    [WrapAs('xml.fromString', SkipDryRun := true)]
    class method xmlFromString(aServices: IApiRegistrationServices; aString: String): XElement;

    [WrapAs('xml.toFile', SkipDryRun := true, wantSelf := true)]
    class method xmlToFile(aServices: IApiRegistrationServices; aSelf: XElement; aFN: String);
    [WrapAs('xml.toString', SkipDryRun := true, wantSelf := true)]
    class method xmlToString(aServices: IApiRegistrationServices; aSelf: XElement): String;
    [WrapAs('xml.xpath', SkipDryRun := true, wantSelf := true)]
    class method xmlXpath(aServices: IApiRegistrationServices; aSelf: XElement; aPath: String): XElement;
    [WrapAs('xml.value', SkipDryRun := true, wantSelf := true)]
    class method xmlValue(aServices: IApiRegistrationServices; aSelf: XElement): String;
  end;


implementation

method XmlPlugin.&Register(aServices: IApiRegistrationServices);
begin
  var lProto := new EcmaScriptObject(aServices.Globals);
  lProto.AddValue('toFile', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(self), 'xmlToFile')); 
  lProto.AddValue('toString', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(self), 'xmlToString')); 
  lProto.AddValue('xpath', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(self), 'xmlXpath'));
  lProto.DefineOwnProperty('value', new PropertyValue(PropertyAttributes.Enumerable, RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(self), 'xmlValue'), nil)); 
  
  

  aServices.RegisterObjectValue('xml')
    .AddValue('fromFile', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(self),'xmlFromFile'))
    .AddValue('fromString', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(self),'xmlFromString'));
end;

class method XmlPlugin.xmlFromFile(aServices: IApiRegistrationServices; aFN: String): XElement;
begin
  XElement.Load(aServices.ResolveWithBase(aFN));
end;

class method XmlPlugin.xmlFromString(aServices: IApiRegistrationServices; aString: String): XElement;
begin
  exit XElement.Parse(aString);
end;

class method XmlPlugin.xmlToFile(aServices: IApiRegistrationServices; aSelf: XElement; aFN: String);
begin
  aSelf.Save(aServices.ResolveWithBase(aFN));
end;

class method XmlPlugin.xmlToString(aServices: IApiRegistrationServices; aSelf: XElement): String;
begin
  exit aSelf.ToString;
end;

class method XmlPlugin.xmlXpath(aServices: IApiRegistrationServices; aSelf: XElement; aPath: String): XElement;
begin
  exit System.Xml.XPath.Extensions.XPathSelectElement(aSelf, aPath);
end;

class method XmlPlugin.xmlValue(aServices: IApiRegistrationServices; aSelf: XElement): String;
begin
  exit aSelf.Value;
end;

end.
