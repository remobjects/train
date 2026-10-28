namespace RemObjects.Train.API;

interface

uses
  Microsoft.Win32,
  RemObjects.Script.EcmaScript,
  System.Text;

type
  [PluginRegistration]
  RegistryPlugin = public class(IPluginRegistration)
  private
    class method OpenRegistryBaseKey(aKeyName: String; aView: Int32; out aSubKey: String): RegistryKey;
  public
    method &Register(aServices: IApiRegistrationServices);

    [WrapAs('reg.getValue', SkipDryRun := true)]
    class method registryGetValue(aServices: IApiRegistrationServices; KeyName: String; ValueName: String; DefaultValue: Object; aView: Int32 := 0): Object;
    [WrapAs('reg.setValue', SkipDryRun := true)]
    class method registrySetValue(aServices: IApiRegistrationServices; KeyName: String; ValueName: String; Value: Object; aView: Int32 := 0);
  end;

implementation

method RegistryPlugin.Register(aServices: IApiRegistrationServices);
begin
  var lProto := new EcmaScriptObject(aServices.Globals);
  aServices.RegisterObjectValue('reg')
    .AddValue('getValue', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(self),'registryGetValue', lProto))
    .AddValue('setValue', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(self),'registrySetValue', lProto));
end;

class method RegistryPlugin.OpenRegistryBaseKey(aKeyName: String; aView: Int32; out aSubKey: String): RegistryKey;
begin
  var lView: RegistryView;
  case aView of
    32: lView := RegistryView.Registry32;
    64: lView := RegistryView.Registry64;
    else raise new ArgumentOutOfRangeException('view', 'Registry view must be 0 (process default), 32, or 64.');
  end;

  if not assigned(aKeyName) then
    raise new ArgumentNullException('key');
  var lSeparator := aKeyName.IndexOf('\');
  var lHiveName := if lSeparator >= 0 then aKeyName.Substring(0, lSeparator) else aKeyName;
  aSubKey := if lSeparator >= 0 then aKeyName.Substring(lSeparator+1) else '';
  var lHive: RegistryHive;
  case lHiveName.ToUpperInvariant of
    'HKEY_CLASSES_ROOT': lHive := RegistryHive.ClassesRoot;
    'HKEY_CURRENT_USER': lHive := RegistryHive.CurrentUser;
    'HKEY_LOCAL_MACHINE': lHive := RegistryHive.LocalMachine;
    'HKEY_USERS': lHive := RegistryHive.Users;
    'HKEY_PERFORMANCE_DATA': lHive := RegistryHive.PerformanceData;
    'HKEY_CURRENT_CONFIG': lHive := RegistryHive.CurrentConfig;
    else raise new ArgumentException('Registry key must start with a full HKEY_ hive name.', 'key');
  end;
  result := RegistryKey.OpenBaseKey(lHive, lView);
end;

class method RegistryPlugin.registryGetValue(aServices: IApiRegistrationServices; KeyName: String; ValueName: String; DefaultValue: Object; aView: Int32): Object;
begin
  if aView = 0 then
    exit Registry.GetValue(KeyName, ValueName, DefaultValue);

  using lBaseKey := OpenRegistryBaseKey(KeyName, aView, out var lSubKey) do
    using lKey := lBaseKey.OpenSubKey(lSubKey) do begin
      // Match Registry.GetValue: a missing key returns nil; a missing value
      // in an existing key returns DefaultValue.
      if not assigned(lKey) then
        exit nil;
      result := lKey.GetValue(ValueName, DefaultValue);
    end;
end;

class method RegistryPlugin.registrySetValue(aServices: IApiRegistrationServices; KeyName: String; ValueName: String; Value: Object; aView: Int32);
begin
  if aView = 0 then begin
    Registry.SetValue(KeyName, ValueName, Value);
    exit;
  end;

  using lBaseKey := OpenRegistryBaseKey(KeyName, aView, out var lSubKey) do
    using lKey := lBaseKey.CreateSubKey(lSubKey) do
      lKey.SetValue(ValueName, Value);
end;

end.
