namespace RemObjects.Builder.API;

interface
uses System.Collections.Generic, System.Diagnostics;
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

    method GetProcess(aCommand, aArgs: string; aComSpec: Boolean; aTargetError: Action<string>; aTargetOutput: Action<String>; environment: array of KeyValuePair<String, String>; aTimeout: nullable TimeSpan): Integer;
  public
    constructor(aItem: IApiRegistrationServices);
    method Exec(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
      method ExecAsync(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method INTSystem(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
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

method Shell.INTSystem(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  
  // TODO: Implement
end;

constructor Shell(aItem: IApiRegistrationServices);
begin
  fEngine := aItem;
end;

method Shell.GetProcess(aCommand: string; aArgs: string; aComSpec: Boolean; aTargetError: Action<string>; aTargetOutput: Action<String>; environment: array of KeyValuePair<String, String>; aTimeout: nullable TimeSpan): Integer;
begin
  var lProcess := new Process();
  if lProcess.StartInfo = nil then lProcess.StartInfo := new ProcessStartInfo();
  if aComSpec then begin
    lProcess.StartInfo.FileName := if RemObjects.Builder.Utilities.Windows then coalesce(System.Environment.GetEnvironmentVariable('COMSPEC'), 'CMD.EXE') else coalesce(System.Environment.GetEnvironmentVariable('SHELL'), '/bin/sh');
    if not aCommand.StartsWith('"') then 
      aCommand := '"'+aCommand.Replace('"', '""')+'"';
    lProcess.StartInfo.Arguments := (if RemObjects.Builder.Utilities.Windows then '-c ' else '/C ')+ aCommand+' '+aArgs;
  end else begin
    lProcess.StartInfo.FileName := aCommand;
    lProcess.StartInfo.Arguments := aArgs;
  end;

  lProcess.StartInfo.UseShellExecute := false;
  if aTargetError <> nil then begin
    lProcess.StartInfo.RedirectStandardError := true;
    lProcess.ErrorDataReceived += method (o: Object; ar: DataReceivedEventArgs) begin
      aTargetError:Invoke(ar.Data);
    end;
  end;
  if aTargetOutput <> nil then begin
    lProcess.StartInfo.RedirectStandardError := true;
    lProcess.OutputDataReceived += method (o: Object; ar: DataReceivedEventArgs) begin
      aTargetOutput:Invoke(ar.Data);
    end;
  end;
  try 
    if not lProcess.Start then raise new Exception('Could not start process');
    if aTimeout = nil then
      lProcess.WaitForExit()
    else 
      if not lProcess.WaitForExit(Integer(aTimeout.TotalMilliseconds)) then raise new Exception('Timeout!');
    exit lProcess.ExitCode;
  finally
    aTargetError := nil;
    aTargetOutput := nil;
    lProcess.Dispose;
  end;
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
  .AddValue('system', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lInstance.INTSystem)));
end;

end.
