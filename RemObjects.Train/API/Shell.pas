namespace RemObjects.Train.API;

interface
uses System.Collections.Generic, System.Diagnostics, RemObjects.Script.EcmaScript;
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
    class method ExecuteProcess(aCommand, aArgs, AWD: String; aComSpec: Boolean; aTargetError: Action<String>; aTargetOutput: Action<String>; environment: array of KeyValuePair<String, String>; aTimeout: nullable TimeSpan): Integer;
    constructor(aItem: IApiRegistrationServices);
    method Exec(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method ExecAsync(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method INTSystem(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
  end;

implementation

method Shell.Exec(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  var lCMD := Utilities.GetArgAsString(args, 0, ec);
  var lFail := true;
  var lArg := Utilities.GetArgAsString(args, 1, ec);
  var lOpt := Utilities.GetArgAsEcmaScriptObject(args, 2, ec);
  var lEnv := new List<KeyValuePair<String, String>>;
  var lTimeout: nullable TimeSpan := nil;
  var lCaptureMode: Boolean := false;
  var lCaptureFunc: EcmaScriptBaseFunctionObject := nil;
  var LWD: String := nil;
  if lOpt <> nil then begin
    var lVal := lOpt.Get('capture');
    if (lVal <> nil) and (lVal <> Undefined.Instance) then begin
      lCaptureFunc := EcmaScriptBaseFunctionObject(lVal);
      if (lCaptureFunc = nil) and (Utilities.GetObjAsBoolean(lVal, ec)) then begin
        lCaptureMode := true;
      end;
    end;
    lVAl := lOpt.Get('workdir');
    if lVAl is String then
      lWD := fEngine.ResolveWithBase(String(lVal));

    lVal := lOpt.Get('timeout');
    if (lVal <> nil) and (lVal <> Undefined.Instance) then 
      lTimeout := TimeSpan.FromSeconds(Utilities.GetObjAsInteger(lVal, ec));
    lVal := lOpt.Get('environment');
    var lObj := EcmaScriptObject(lVal);
    if lObj  <> nil then begin
      for each el in lObj.Values do begin
        lEnv.Add(new KeyValuePair<String,String>(el.Key, Utilities.GetObjAsString(el.Value, ec)));
      end;
    end;
  end;

  fEngine.Engine.Logger.Enter(String.Format('exec({0}, {1})', lCMD, lArg));
  try
    if fEngine.Engine.DryRun then begin
      fEngine.Engine.Logger.LogMessage('Dry run.');
      exit '';
    end;
    var sb := new System.Text.StringBuilder;
    var lExit := ExecuteProcess(lCMD, lArg, lWD,false , a-> begin
      locking(sb) do begin
        sb.Append(a);
      end;
      if assigned(lCaptureFunc) then begin
        try
          lCaptureFunc.Call(ec, a);
        except
        end;
      end;
    end, a-> begin
      locking(sb) do sb.Append(a);
      if assigned(lCaptureFunc) then begin
        try
          lCaptureFunc.Call(ec, a);
        except
        end;
      end;
    end, lEnv.ToArray, lTimeout);
    fEngine.Engine.Logger.LogMessage('Output: '#13#10+sb.ToString);
    if 0 <> lExit then begin
      var lErr := 'Failed with error code: '+lExit;
      fEngine.Engine.Logger.LogError(lErr);
      raise new Exception(lErr);
    end;
    if lCaptureMode then 
      exit sb.ToString()
    else
      exit Undefined.Instance;
    lFail := false;
  finally
    fEngine.Engine.Logger.Exit(String.Format('system({0})', lArg), if lFail then RemObjects.Train.FailMode.Yes else RemObjects.Train.FailMode.No);
  end;
end;

method Shell.ExecAsync(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  var lCMD := Utilities.GetArgAsString(args, 0, ec);
  var lArg := Utilities.GetArgAsString(args, 1, ec);
  var lFail := true;
  var lOpt := Utilities.GetArgAsEcmaScriptObject(args, 2, ec);
  var lEnv := new List<KeyValuePair<String, String>>;
  var lTimeout: nullable TimeSpan := nil;
  var lWD: String;
  if lOpt <> nil then begin
    var lVal := lOpt.Get('timeout');
    if (lVal <> nil) and (lVal <> Undefined.Instance) then 
      lTimeout := TimeSpan.FromSeconds(Utilities.GetObjAsInteger(lVal, ec));
    lVAl := lOpt.Get('workdir');
    if lVAl is String then
      lWD := fEngine.ResolveWithBase(String(lVal));
    lVal := lOpt.Get('environment');
    var lObj := EcmaScriptObject(lVal);
    if lObj  <> nil then begin
      for each el in lObj.Values do begin
        lEnv.Add(new KeyValuePair<String,String>(el.Key, Utilities.GetObjAsString(el.Value, ec)));
      end;
    end;
  end;
  var lLogger := new RemObjects.Train.DelayedLogger;
  var lTask := new System.Threading.Tasks.Task(method begin
    lLogger.Enter(String.Format('exec({0}, {1})', lCMD, lArg));
    try
      if fEngine.Engine.DryRun then begin
        lLogger.LogMessage('Dry run.');
        exit '';
      end;
      var sb := new System.Text.StringBuilder;
      var lExit := ExecuteProcess(lCMD, lArg, LWD, false, a-> begin
        locking(sb) do begin
          sb.Append(a);
        end;
      end, a-> begin
        locking(sb) do sb.Append(a);
      end, lEnv.ToArray, lTimeout);
      lLogger.LogMessage('Output: '#13#10+sb.ToString);
      if 0 <> lExit then begin
        var lErr := 'Failed with error code: '+lExit;
        lLogger.LogError(lErr);
        raise new Exception(lErr);
      end;
      lFail := false;
    finally
      lLogger.Exit(String.Format('system({0})', lArg), if lFail then RemObjects.Train.FailMode.Yes else RemObjects.Train.FailMode.No);
    end;
  end);
  fEngine.RegisterTask(lTask, String.Format('[{0}] {1} {2}', lTask.Id, lCMD, lArg), lLogger);
  exit new TaskWrapper(fEngine.Engine.Engine.GlobalObject, fEngine.AsyncWorker.TaskProto, Task := lTask);
end;

method Shell.INTSystem(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  var lArg := Utilities.GetArgAsString(args, 0, ec);
  var lWD := Utilities.GetArgAsString(args, 1, ec);
  var lFail := true;
  fEngine.Engine.Logger.Enter(String.Format('system({0})', lArg));
  try
    if fEngine.Engine.DryRun then begin
      fEngine.Engine.Logger.LogMessage('Dry run.');
      exit '';
    end;
    var sb := new System.Text.StringBuilder;
    var lExit := ExecuteProcess(nil, lArg, lWD,true , a-> begin
      locking(sb) do sb.Append(a);
    end, a-> begin
      locking(sb) do sb.Append(a)
    end, nil, nil);
    fEngine.Engine.Logger.LogMessage('Output: '#13#10+sb.ToString);
    if 0 <> lExit then begin
      var lErr := 'Failed with error code: '+lExit;
      fEngine.Engine.Logger.LogError(lErr);
      raise new Exception(lErr);
    end;
    lFail := false;
    exit sb.ToString();
  finally
    fEngine.Engine.Logger.Exit(String.Format('system({0})', lArg), if lFail then RemObjects.Train.FailMode.Yes else RemObjects.Train.FailMode.No);
  end;
end;

constructor Shell(aItem: IApiRegistrationServices);
begin
  fEngine := aItem;
end;

class method Shell.ExecuteProcess(aCommand: String; aArgs, AWD: String; aComSpec: Boolean; aTargetError: Action<String>; aTargetOutput: Action<String>; environment: array of KeyValuePair<String, String>; aTimeout: nullable TimeSpan): Integer;
begin
  var lProcess := new Process();
  if lProcess.StartInfo = nil then lProcess.StartInfo := new ProcessStartInfo();
  if aComSpec then begin
    lProcess.StartInfo.FileName := if RemObjects.Train.Utilities.Windows then coalesce(System.Environment.GetEnvironmentVariable('COMSPEC'), 'CMD.EXE') else coalesce(System.Environment.GetEnvironmentVariable('SHELL'), '/bin/sh');
    if String.IsNullOrEmpty(aCommand) then begin
      lProcess.StartInfo.Arguments := (if RemObjects.Train.Utilities.Windows then '-c ' else '/C ')+ aArgs;
    end else begin
      if not aCommand.StartsWith('"') then 
        aCommand := '"'+aCommand.Replace('"', '""')+'"';
      lProcess.StartInfo.Arguments := (if RemObjects.Train.Utilities.Windows then '-c ' else '/C ')+ aCommand+' '+aArgs;
    end;
  end else begin
    lProcess.StartInfo.FileName := aCommand;
    lProcess.StartInfo.Arguments := aArgs;
  end;

  if assigned(aWD) then
    lProcess.StartInfo.WorkingDirectory := aWD;
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

  for each el in environment do begin
    lProcess.StartInfo.EnvironmentVariables.Add(el.Key, el.Value);
  end;

  try 
    if not lProcess.Start then raise new Exception('Could not start process');
    if aTargetOutput <> nil then lProcess.BeginOutputReadLine;
    if aTargetError <> nil then lProcess.BeginErrorReadLine;
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
  .AddValue('cd', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, (a, b, c) -> 
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
  .AddValue('exec', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, @lInstance.Exec))
  .AddValue('execAsync', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, @lInstance.ExecAsync))
  .AddValue('system', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, @lInstance.INTSystem)));
end;

end.
