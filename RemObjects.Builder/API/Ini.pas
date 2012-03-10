namespace RemObjects.Builder.API;

interface

uses 
  RemObjects.Builder,
  RemObjects.Script.EcmaScript, 
  System.Linq,
  RemObjects.Script.EcmaScript.Internal, 
  System.IO,
  System.Runtime.InteropServices;

type
  [PluginRegistration]
  IniPlugin = public class(IPluginRegistration)
  private
  public
    method &Register(aServices: IApiRegistrationServices);

    [WrapAs('ini.fromFile', SkipDryRun := true)]
    class method FromFile(aServices: IApiRegistrationServices; aFN: string): IniFile;
    [WrapAs('ini.fromString', SkipDryRun := false)]
    class method FromString(aServices: IApiRegistrationServices; aString: string): IniFile;

    [WrapAs('ini.toFile', SkipDryRun := true, wantSelf := true)]
    class method ToFile(aServices: IApiRegistrationServices; aSelf: IniFile; aFN: string);
    [WrapAs('ini.toString', SkipDryRun := false, wantSelf := true)]
    class method _ToString(aServices: IApiRegistrationServices; aSelf: IniFile): string;
    [WrapAs('ini', SkipDryRun := false)]
    class method Ctor(aServices: IApiRegistrationServices): IniFile;
    [WrapAs('ini.getString', SkipDryRun := true, wantSelf := true)]
    class method GetString(aServices: IApiRegistrationServices; aSelf: IniFile; aSection, aKey: string; aDefault: Object := nil): Object;
    [WrapAs('ini.setString', SkipDryRun := true, wantSelf := true)]
    class method SetString(aServices: IApiRegistrationServices; aSelf: IniFile; aSection, aKey: string; aValue: Object);
    [WrapAs('ini.deleteSection', SkipDryRun := true, wantSelf := true)]
    class method DeleteSection(aServices: IApiRegistrationServices; aSelf: IniFile; aSection: String);
    [WrapAs('ini.deleteValue', SkipDryRun := true, wantSelf := true)]
    class method DeleteValue(aServices: IApiRegistrationServices; aSelf: IniFile; aSection, aKey: String);
    [WrapAs('ini.keysInSection', SkipDryRun := true, wantSelf := true)]
    class method KeysInSection(aServices: IApiRegistrationServices; aSelf: IniFile; aSection: String): array of STring;
    [WrapAs('ini.sections', SkipDryRun := true, wantSelf := true)]
    class method Sections(aServices: IApiRegistrationServices; aSelf: IniFile): array of STring;
  end;

implementation

method IniPlugin.&Register(aServices: IApiRegistrationServices);
begin
  var lProto := new EcmaScriptObject(aServices.Globals);
  lProto.AddValue('toFile', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine,typeof(IniPlugin), 'ToFile'));
  lProto.AddValue('toString', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine,typeof(IniPlugin), '_ToString'));

  var lCtor := RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, typeof(IniPlugin), 'Ctor');
  aServices.RegisterValue('ini', lCtor);
  lCtor.Class := 'ini';
  lCtor.AddValue('fromFile', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, typeof(IniPlugin), 'FromFile'));
  lCtor.AddValue('fromString', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, typeof(IniPlugin), 'FromString'));


  lProto.AddValue('getString', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, typeof(IniPlugin), 'GetString'));
  lProto.AddValue('setString', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, typeof(IniPlugin), 'SetString'));
  lProto.AddValue('deleteSection', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, typeof(IniPlugin), 'DeleteSection'));
  lProto.AddValue('deleteValue', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, typeof(IniPlugin), 'DeleteValue'));
  lProto.AddValue('keysInSection', RemOBjects.Builder.Utilities.SimpleFunction(aSErvices.Engine, typeof(IniPlugin), 'KeysInSection'));
  (*  
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
  end)); *)

end;

class method IniPlugin.FromFile(aServices: IApiRegistrationServices; aFN: string): IniFile;
begin
  result := new IniFile();
  result.LoadFromFile(aServices.ResolveWithBase(aFN));
end;

class method IniPlugin.FromString(aServices: IApiRegistrationServices; aString: string): IniFile;
begin
  result := new IniFile();
  result.LoadFromStream(new StringReader(aString));
end;

class method IniPlugin.ToFile(aServices: IApiRegistrationServices; aSelf: IniFile; aFN: string);
begin
  aSelf.SaveToFile(aServices.ResolveWithBase(aFN));
end;

class method IniPlugin._ToString(aServices: IApiRegistrationServices; aSelf: IniFile): string;
begin
  exit aSelf.ToString;
end;

class method IniPlugin.Ctor(aServices: IApiRegistrationServices): IniFile;
begin
  exit new IniFile();
end;

class method IniPlugin.GetString(aServices: IApiRegistrationServices; aSelf: IniFile; aSection: string; aKey: string; aDefault: Object): Object;
begin
  var lSec := aSelf.Item[aSEction];
  if lSec = nil then exit aDefault;
  var lRes: string;
  if lSec.TryGetValue(aKey, out lRes) then exit lRes;
  exit aDefault;
end;

class method IniPlugin.SetString(aServices: IApiRegistrationServices; aSelf: IniFile; aSection: string; aKey: string; aValue: Object);
begin
  var lSec := aSelf.addsection(aSection);
  lSec.Item[aKey] := aValue:ToString;
end;

class method IniPlugin.DeleteSection(aServices: IApiRegistrationServices; aSelf: IniFile; aSection: String);
begin
  aSelf.Remove(aSection);
end;

class method IniPlugin.DeleteValue(aServices: IApiRegistrationServices; aSelf: IniFile; aSection: String; aKey: String);
begin
  var lSec := aSelf.Item[aSection];
  if lSec <> nil then
    lSec.Remove(aKey);
end;

class method IniPlugin.KeysInSection(aServices: IApiRegistrationServices; aSelf: IniFile; aSection: String): array of STring;
begin
  var lSec := aSelf.Item[aSection];
  if lSec <> nil then
    exit lSec.Keys.ToArray();
  exit [];
end;

class method IniPlugin.Sections(aServices: IApiRegistrationServices; aSelf: IniFile): array of STring;
begin
  exit aSelf.Sections.Select(a->a.Item1).ToArray;
end;

end.
