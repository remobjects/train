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
  end;

  XmlFileWrapper = public class(EcmaScriptObject)
  private
  public
    property Xml: XElement;
  end;

implementation

method XmlPlugin.&Register(aServices: IApiRegistrationServices);
begin
  var lProto := new EcmaScriptObject(aServices.Globals);
  lProto.AddValue('toFile', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, method(ec: ExecutionContext; aSelf: Object; args: array of Object): Object begin
    aServices.Logger.Enter('toFile', args);
    try 
      if aservices.Engine.DryRun then begin
        aservices.Engine.Logger.LogMessage('Dry run.');
        exit '';
      end;
      var lSelf := aSelf as XmlFileWrapper;
      lSelf.Xml.Save(aSErvices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec)));
    finally
      aServices.Logger.Exit('toFile');
    end;
  end)); 
  lProto.AddValue('toString', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, method(ec: ExecutionContext; aSelf: Object; args: array of Object): Object begin
    aServices.Logger.Enter('toString', args);
    try 
      var lSelf := aSelf as XmlFileWrapper;
      exit lSelf.ToString;
    finally
      aServices.Logger.Exit('toString');
    end;
  end)); 

  lProto.AddValue('xpath', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, method(ec: ExecutionContext; aSelf: Object; args: array of Object): Object begin
    aServices.Logger.Enter('xpath', args);
    try 
      var lSelf := aSelf as XmlFileWrapper;
      var lSec := Utilities.GetArgAsString(args, 0, ec);
      var lValue := System.Xml.XPath.Extensions.XPathEvaluate(lSELF.Xml, lSec);
      if lValue is XElement then
        exit new XmlFileWrapper(aServices.Globals, Xml := XElement(lValue), &Class := 'xelement');
      exit lValue.ToString;
    finally
      aServices.Logger.Exit('xpath');
    end;
  end)); 
   lProto.DefineOwnProperty('value', new PropertyValue(PropertyAttributes.Enumerable, RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, method(ec: ExecutionContext; aSelf: Object; args: array of Object): Object begin
    var lSelf := aSelf as XmlFileWrapper;
    exit lSelf.Xml.Value;
  end), nil)); 

  aServices.RegisterValue('xml', new EcmaScriptFunctionObject(aServices.Globals, 'xml', method begin
    exit new XmlFileWrapper(aServices.Globals, Xml := new XElement('node'), &Class := 'xelement');
  end, 0)
  .AddValue('fromFile', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, method(ec: ExecutionContext; aSelf: Object; args: array of Object): Object begin
    aServices.Logger.Enter('fromFile', args);
    try 
      var lRes := new XmlFileWrapper(aServices.Globals, &Class := 'ini');
      lRes.Xml := XElement.Load(aServices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec)));
      exit lRes;
    finally
      aServices.Logger.Exit('fromFile');
    end;
  end))
  .AddValue('fromString', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, method(ec: ExecutionContext; aSelf: Object; args: array of Object): Object begin
    aServices.Logger.Enter('fromString', args);
    try 
      var lRes := new XmlFileWrapper(aServices.Globals, &Class := 'ini');
      lRes.Xml := XElement.Parse(Utilities.GetArgAsString(args, 0, ec));
      exit lRes;  
    finally
      aServices.Logger.Exit('fromString');
    end;
  end))
 );
end;

end.
