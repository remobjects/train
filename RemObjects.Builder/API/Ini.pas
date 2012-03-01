namespace RemObjects.Builder.API;

interface

uses 
  RemObjects.Builder,
  RemObjects.Script.EcmaScript, 
  RemObjects.Script.EcmaScript.Internal, 
  System.IO,
  System.Runtime.InteropServices;

type
  [PluginRegistration]
  IniPlugin = public class(IPluginRegistration)
  private
  public
    method &Register(aServices: IApiRegistrationServices);
  end;

  IniFileWrapper = public class(EcmaScriptObject)
  private
  public
    property Ini: IniFile;
  end;

implementation

method IniPlugin.&Register(aServices: IApiRegistrationServices);
begin
  var lProto := new EcmaScriptObject(aServices.Globals);
  lProto.AddValue('toFile', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, method(ec: ExecutionContext; aSelf: Object; args: array of Object): Object begin
    aServices.Logger.Enter('toFile', args);
    try 
      if aservices.Engine.DryRun then begin
        aservices.Engine.Logger.LogMessage('Dry run.');
        exit '';
      end;
      var lSelf := aSelf as IniFileWrapper;
      lSelf.Ini.SaveToFile(aSErvices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec)));
    finally
      aServices.Logger.Exit('toFile');
    end;
  end)); 
  lProto.AddValue('toString', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, method(ec: ExecutionContext; aSelf: Object; args: array of Object): Object begin
    aServices.Logger.Enter('toString', args);
    try 
      var lSelf := aSelf as IniFileWrapper;
      exit lSelf.ToString;
    finally
      aServices.Logger.Exit('toString');
    end;
  end)); 

  lProto.AddValue('getString', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, method(ec: ExecutionContext; aSelf: Object; args: array of Object): Object begin
    aServices.Logger.Enter('getString', args);
    try 
      var lSelf := aSelf as IniFileWrapper;
      var lSec := lSelf.Ini.Item[Utilities.GetArgAsString(args, 0, ec)];
      if lSec = nil then exit Utilities.GetArgAsString(args, 2, ec);
      var lRes: string;
      if lSec.TryGetValue(Utilities.GetArgAsString(args, 1, ec), out lRes) then exit lRes;
      exit Utilities.GetArgAsString(args, 0, ec);
    finally
      aServices.Logger.Exit('getString');
    end;
  end)); 
  lProto.AddValue('setString', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, method(ec: ExecutionContext; aSelf: Object; args: array of Object): Object begin
    aServices.Logger.Enter('setString', args);
    try 
      var lSelf := aSelf as IniFileWrapper;
      var lSec := lSelf.Ini.addsection(Utilities.GetArgAsString(args, 0, ec));
      lSEc[Utilities.GetArgAsString(args, 1, ec)] := Utilities.GetArgAsString(args, 2, ec);
      exit Undefined.Instance;
    finally
      aServices.Logger.Exit('setString');
    end;
  end)); 
  lProto.AddValue('keysInSection', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, method(ec: ExecutionContext; aSelf: Object; args: array of Object): Object begin
    aServices.Logger.Enter('keysInSection', args);
    try 
      var lSelf := aSelf as IniFileWrapper;
      var lSec := lSelf.Ini.Item[Utilities.GetArgAsString(args, 0, ec)];
      if lSec = nil then exit Undefined.Instance;
      var lres := new EcmaScriptArrayObject(0,aServices .Globals);
      for each el in lSec.KEys do 
        lRes.AddValue(el);
      exit Undefined.Instance;
    finally
      aServices.Logger.Exit('keysInSection');
    end;
  end)); 
  lProto.AddValue('deleteSection', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, method(ec: ExecutionContext; aSelf: Object; args: array of Object): Object begin
    aServices.Logger.Enter('deleteSection', args);
    try 
      var lSelf := aSelf as IniFileWrapper;
      exit lSelf.Ini.Remove(Utilities.GetArgAsString(args, 0, ec));
    finally
      aServices.Logger.Exit('deleteSection');
    end;
  end)); 
  lProto.AddValue('deleteValue', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, method(ec: ExecutionContext; aSelf: Object; args: array of Object): Object begin
    aServices.Logger.Enter('deleteValue', args);
    try 
      var lSelf := aSelf as IniFileWrapper;
      var lSec := lSelf.Ini.Item[Utilities.GetArgAsString(args, 0, ec)];
      if lSec = nil then exit Utilities.GetArgAsString(args, 2, ec);
      exit lSec.Remove(Utilities.GetArgAsString(args, 1, ec));
    finally
      aServices.Logger.Exit('deleteValue');
    end;
  end)); 

  aServices.RegisterValue('ini', new EcmaScriptFunctionObject(aServices.Globals, 'ini', method begin
    exit new IniFileWrapper(aServices.Globals, Ini := new IniFile, &Class := 'ini');
  end, 0)
  .AddValue('fromFile', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, method(ec: ExecutionContext; aSelf: Object; args: array of Object): Object begin
    aServices.Logger.Enter('fromFile', args);
    try 
      var lRes := new IniFileWrapper(aServices.Globals, &Class := 'ini');
      lRes.Ini := new IniFile;
      lRes.Ini.LoadFromFile(aServices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec)));
      exit lRes;
    finally
      aServices.Logger.Exit('fromFile');
    end;
  end))
  .AddValue('fromString', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, method(ec: ExecutionContext; aSelf: Object; args: array of Object): Object begin
    aServices.Logger.Enter('fromString', args);
    try 
      var lRes := new IniFileWrapper(aServices.Globals, &Class := 'ini');
      lRes.Ini := new IniFile;
      lRes.Ini.LoadFromStream(new StringReader(Utilities.GetArgAsString(args, 0, ec)));
      exit lRes;  
    finally
      aServices.Logger.Exit('fromString');
    end;
  end))
 );
end;

end.
