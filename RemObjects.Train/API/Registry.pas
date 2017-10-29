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
  public
    method &Register(aServices: IApiRegistrationServices);

    [WrapAs('reg.getValue', SkipDryRun := true)]
    class method registryGetValue(aServices: IApiRegistrationServices; KeyName: String; ValueName: String; DefaultValue: Object): Object;
    [WrapAs('reg.setValue', SkipDryRun := true)]
    class method registrySetValue(aServices: IApiRegistrationServices; KeyName: String; ValueName: String; Value: Object);
  end;

implementation

method RegistryPlugin.Register(aServices: IApiRegistrationServices);
begin
  var lProto := new EcmaScriptObject(aServices.Globals);
  aServices.RegisterObjectValue('reg')
    .AddValue('getValue', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(self),'registryGetValue', lProto))
    .AddValue('setValue', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(self),'registrySetValue', lProto));
end;

class method RegistryPlugin.registryGetValue(aServices: IApiRegistrationServices; KeyName: String; ValueName: String; DefaultValue: Object): Object;
begin
  exit Registry.GetValue(KeyName, ValueName, DefaultValue);
end;

class method RegistryPlugin.registrySetValue(aServices: IApiRegistrationServices; KeyName: String; ValueName: String; Value: Object);
begin
  Registry.SetValue(KeyName, ValueName, Value);
end;

end.