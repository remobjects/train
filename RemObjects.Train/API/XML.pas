namespace RemObjects.Train.API;

interface

uses 
  RemObjects.Train,
  RemObjects.Script.EcmaScript, 
  RemObjects.Script.EcmaScript.Internal, 
  System.Collections,
  System.Collections.Generic,
  System.Linq,
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
    class method xmlFromFile(aServices: IApiRegistrationServices; ec: ExecutionContext; aFN: String): XElement;
    [WrapAs('xml.fromString', SkipDryRun := true)]
    class method xmlFromString(aServices: IApiRegistrationServices; aString: String): XElement;

    [WrapAs('xml.toFile', SkipDryRun := true, wantSelf := true, Important := true)]
    class method xmlToFile(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: XElement; aFN: String);
    [WrapAs('xml.toString', SkipDryRun := true, wantSelf := true, Important := false)]
    class method xmlToString(aServices: IApiRegistrationServices; aSelf: XElement): String;
    [WrapAs('xml.xpath', SkipDryRun := true, wantSelf := true, Important := false)]
    class method xmlXpath(aServices: IApiRegistrationServices; aSelf: XElement; aPath: String): Object;
    [WrapAs('xml.xpathElement', SkipDryRun := true, wantSelf := true, Important := false)]
    class method xmlXpathElement(aServices: IApiRegistrationServices; aSelf: XElement; aPath: String): XElement;
    [WrapAs('xml.value', SkipDryRun := true, wantSelf := true, Important := false)]
    class method xmlValue(aServices: IApiRegistrationServices; aSelf: XElement): String;
    [WrapAs('xml.xlstTransform', SkipDryRun := true, wantSelf := true, Important := false)]
    class method xmlXLSTTransform(aServices: IApiRegistrationServices;ec: ExecutionContext; aSelf: XElement; aXLSTFile: String): String;
  end;


implementation

method XmlPlugin.&Register(aServices: IApiRegistrationServices);
begin
  var lProto := new EcmaScriptObject(aServices.Globals);
  lProto.AddValue('xlstTransform', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'xmlXLSTTransform')); 
  lProto.AddValue('toFile', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'xmlToFile')); 
  lProto.AddValue('toString', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'xmlToString')); 
  lProto.AddValue('xpath', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'xmlXpath', lProto));
  lProto.AddValue('xpathElement', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'xmlXpathElement', lProto));
  lProto.DefineOwnProperty('value', new PropertyValue(PropertyAttributes.Enumerable, RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'xmlValue'), nil)); 
  
  

  aServices.RegisterObjectValue('xml')
    .AddValue('fromFile', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(self),'xmlFromFile', lProto))
    .AddValue('fromString', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(self),'xmlFromString', lProto));
end;

class method XmlPlugin.xmlFromFile(aServices: IApiRegistrationServices; ec: ExecutionContext; aFN: String): XElement;
begin
  exit XElement.Load(aServices.ResolveWithBase(ec,aFN ));
end;

class method XmlPlugin.xmlFromString(aServices: IApiRegistrationServices; aString: String): XElement;
begin
  exit XElement.Parse(aString);
end;

class method XmlPlugin.xmlToFile(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: XElement; aFN: String);
begin
  aSelf.Save(aServices.ResolveWithBase(ec,aFN ));
end;

class method XmlPlugin.xmlToString(aServices: IApiRegistrationServices; aSelf: XElement): String;
begin
  exit aSelf.ToString;
end;

class method XmlPlugin.xmlXpath(aServices: IApiRegistrationServices; aSelf: XElement; aPath: String): Object;
begin
  var lDoc := new XDocument(aSelf);
  var res := System.Xml.XPath.Extensions.XPathEvaluate(lDoc, aPath);
  if res is IEnumerable then begin
    var lRes := new List<Object>;
    for each x: Object in IEnumerable(res) do begin
      lRes.Add(x.ToString());
    end;
    res := lRes.ToArray;
  end;
  exit res;
end;

class method XmlPlugin.xmlValue(aServices: IApiRegistrationServices; aSelf: XElement): String;
begin
  exit aSelf.Value;
end;

class method XmlPlugin.xmlXpathElement(aServices: IApiRegistrationServices; aSelf: XElement; aPath: String): XElement;
begin
  exit System.Xml.XPath.Extensions.XPathSelectElement(aSelf, aPath);
end;

class method XmlPlugin.xmlXLSTTransform(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: XElement; aXLSTFile: String): String;
begin
  var xlst := new System.Xml.Xsl.XslCompiledTransform();
  var output := new StringWriter();
  xlst.Load(aServices.ResolveWithBase(ec,aXLSTFile));
  xlst.Transform(aSelf.CreateReader(), nil, output);
  result := output.ToString();
end;

end.
