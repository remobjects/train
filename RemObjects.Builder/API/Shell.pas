namespace RemObjects.Builder.API;

interface

type
  [PluginRegistration]
  ShellRegistration = public class(IPluginRegistration)
  private
  public
    method &Register(aServices: IApiRegistrationServices);
  end;

  Shell = public class
  private
    fEngine: IApiRegistrationServices;
  public
    constructor(aItem: IApiRegistrationServices);
    method Exec(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method ExecAsync(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method System(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
  end;

implementation

method Shell.Exec(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  // TODO: Implement
end;

method Shell.ExecAsync(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  // TODO: Implement
end;

method Shell.System(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  // TODO: Implement
end;

constructor Shell(aItem: IApiRegistrationServices);
begin
  fEngine := aItem;
end;

method ShellRegistration.&Register(aServices: IApiRegistrationServices);
begin

  var lInstance := new Shell(aServices);
  aServices.RegisterValue('shell', 
    new RemObjects.Script.EcmaScript.EcmaScriptObject(aServices.Globals)
  .AddValue('cd', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, (a, b, c) -> 
    begin
      var lCurrPath := aServices.Engine.WorkDir;
      var lPath := RemObjects.Script.EcmaScript.Utilities.GetArgAsString(c, 0, a);
      if System.IO.Path.IsPathRooted(lPath) then 
        aServices.Engine.WorkDir := lPath
      else
        aServices.Engine.WorkDir  := System.IO.Path.Combine(aServices.Engine.WorkDir, lPath);
      var lFunc := RemObjects.Script.EcmaScript.Utilities.GetArgAsEcmaScriptObject(c, 1, a);
      if lFunc <> nil then
      try 
        lFunc.Call(a);
      finally
        aServices.Engine.WorkDir := lCurrPath;
      end;
    end))
  .AddValue('exec', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lInstance.Exec))
  .AddValue('execAsync', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lInstance.ExecAsync))
  .AddValue('system', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lInstance.System)));
end;

end.
