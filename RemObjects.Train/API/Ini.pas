namespace RemObjects.Train.API;

interface

uses 
  RemObjects.Train,
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
    class method FromFile(aServices: IApiRegistrationServices; aFN: String): IniFile;
    [WrapAs('ini.fromString', SkipDryRun := false)]
    class method FromString(aServices: IApiRegistrationServices; aString: String): IniFile;

    [WrapAs('ini.toFile', SkipDryRun := true, wantSelf := true, Important := false)]
    class method ToFile(aServices: IApiRegistrationServices; aSelf: IniFile; aFN: String);
    [WrapAs('ini.toString', SkipDryRun := false, wantSelf := true, Important := false)]
    class method _ToString(aServices: IApiRegistrationServices; aSelf: IniFile): String;
    [WrapAs('ini', SkipDryRun := false)]
    class method Ctor(aServices: IApiRegistrationServices): IniFile;
    [WrapAs('ini.getValue', SkipDryRun := true, wantSelf := true, Important := false)]
    class method GetString(aServices: IApiRegistrationServices; aSelf: IniFile; aSection, aKey: String; aDefault: Object := nil): Object;
    [WrapAs('ini.setValue', SkipDryRun := true, wantSelf := true, Important := false)]
    class method SetString(aServices: IApiRegistrationServices; aSelf: IniFile; aSection, aKey: String; aValue: Object);
    [WrapAs('ini.deleteSection', SkipDryRun := true, wantSelf := true, Important := false)]
    class method DeleteSection(aServices: IApiRegistrationServices; aSelf: IniFile; aSection: String);
    [WrapAs('ini.deleteValue', SkipDryRun := true, wantSelf := true, Important := false)]
    class method DeleteValue(aServices: IApiRegistrationServices; aSelf: IniFile; aSection, aKey: String);
    [WrapAs('ini.keysInSection', SkipDryRun := true, wantSelf := true, Important := false)]
    class method KeysInSection(aServices: IApiRegistrationServices; aSelf: IniFile; aSection: String): array of String;
    [WrapAs('ini.sections', SkipDryRun := true, wantSelf := true, Important := false)]
    class method Sections(aServices: IApiRegistrationServices; aSelf: IniFile): array of String;
  end;

implementation

method IniPlugin.&Register(aServices: IApiRegistrationServices);
begin
  var lProto := new EcmaScriptObject(aServices.Globals);
  lProto.AddValue('toFile', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine,typeOf(IniPlugin), 'ToFile'));
  lProto.AddValue('toString', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine,typeOf(IniPlugin), '_ToString'));

  var lCtor := RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(IniPlugin), 'Ctor');
  aServices.RegisterValue('ini', lCtor);
  lCtor.Class := 'ini';
  lCtor.AddValue('fromFile', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(IniPlugin), 'FromFile', lProto));
  lCtor.AddValue('fromString', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(IniPlugin), 'FromString', lProto));


  lProto.AddValue('getValue', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(IniPlugin), 'GetString'));
  lProto.AddValue('setValue', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(IniPlugin), 'SetString'));
  lProto.AddValue('deleteSection', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(IniPlugin), 'DeleteSection'));
  lProto.AddValue('deleteValue', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(IniPlugin), 'DeleteValue'));
  lProto.AddValue('keysInSection', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(IniPlugin), 'KeysInSection'));
  (*  
  lProto.AddValue('keysInSection', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, method(ec: ExecutionContext; aSelf: Object; args: array of Object): Object begin
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
  lProto.AddValue('deleteValue', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, method(ec: ExecutionContext; aSelf: Object; args: array of Object): Object begin
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

class method IniPlugin.FromFile(aServices: IApiRegistrationServices; aFN: String): IniFile;
begin
  result := new IniFile();
  result.LoadFromFile(aServices.ResolveWithBase(aFN));
end;

class method IniPlugin.FromString(aServices: IApiRegistrationServices; aString: String): IniFile;
begin
  result := new IniFile();
  result.LoadFromStream(new StringReader(aString));
end;

class method IniPlugin.ToFile(aServices: IApiRegistrationServices; aSelf: IniFile; aFN: String);
begin
  aSelf.SaveToFile(aServices.ResolveWithBase(aFN));
end;

class method IniPlugin._ToString(aServices: IApiRegistrationServices; aSelf: IniFile): String;
begin
  exit aSelf.ToString;
end;

class method IniPlugin.Ctor(aServices: IApiRegistrationServices): IniFile;
begin
  exit new IniFile();
end;

class method IniPlugin.GetString(aServices: IApiRegistrationServices; aSelf: IniFile; aSection: String; aKey: String; aDefault: Object): Object;
begin
  var lSec := aSelf.Item[aSection];
  if lSec = nil then exit aDefault;
  var lRes: String;
  if lSec.TryGetValue(aKey, out lRes) then exit lRes;
  exit aDefault;
end;

class method IniPlugin.SetString(aServices: IApiRegistrationServices; aSelf: IniFile; aSection: String; aKey: String; aValue: Object);
begin
  var lSec := aSelf.AddSection(aSection);
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

class method IniPlugin.KeysInSection(aServices: IApiRegistrationServices; aSelf: IniFile; aSection: String): array of String;
begin
  var lSec := aSelf.Item[aSection];
  if lSec <> nil then
    exit lSec.Keys.ToArray();
  exit [];
end;

class method IniPlugin.Sections(aServices: IApiRegistrationServices; aSelf: IniFile): array of String;
begin
  exit aSelf.Sections.Select(a->a.Item1).ToArray;
end;

end.
