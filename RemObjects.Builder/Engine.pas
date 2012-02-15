namespace RemObjects.Builder;

interface

uses 
  System.Linq,
  RemObjects.Script, 
  System.Collections.Generic, 
  RemObjects.Script.EcmaScript,
  RemObjects.Builder.API,
  System.IO;

type


  Engine = public class
  private
    method fEngineDebugTracePoint(sender: Object; e: ScriptDebugEventArgs);
    method fEngineDebugFrameExit(sender: Object; e: ScriptDebugEventArgs);
    method fEngineDebugFrameEnter(sender: Object; e: ScriptDebugEventArgs);
    method fEngineDebugException(sender: Object; e: ScriptDebugEventArgs);
    fEnvironment: Environment;
    fEngine: EcmaScriptComponent;
  protected
    method WaitFor(ec: ExecutionContext; args: EcmaScriptObject; aTimeout: Integer);
    method CallAsync(aScope: ExecutionContext; aSelf: Object; params args: Array of Object): Object;
  public
    constructor(aParent: Environment; aScriptPath: string; aScript: string := nil);
    property Engine: EcmaScriptComponent read fEngine;
    property Logger: ILogger;
    property Environment: Environment read fEnvironment;

    method Run;

    method CreateChildEngine: Engine;
  end;

  ILogger = public interface
    method LogError(s: string);
    method LogMessage(s: string);
    method LogWarning(s: string);
    method LogHint(s: string);
    method LogDebug(s: string);
  end;  

extension method ILogger.LogError(s: string; params args: array of Object);
extension method ILogger.LogMessage(s: string; params args: array of Object);
extension method ILogger.LogWarning(s: string; params args: array of Object);
extension method ILogger.LogHint(s: string; params args: array of Object);
extension method ILogger.LogDebug(s: string; params args: array of Object);

implementation

extension method ILogger.LogError(s: string; params args: array of Object);
begin
  self.LogError(String.Format(s, args));
end;

extension method ILogger.LogMessage(s: string; params args: array of Object);
begin
  self.LogMessage(String.Format(s,  args));
end;

extension method ILogger.LogWarning(s: string; params args: array of Object);
begin
  self.LogWarning(String.Format(s,  args));
end;

extension method ILogger.LogHint(s: string; params args: array of Object);
begin
  self.LogHint(String.Format(s,  args));
end;

extension method ILogger.LogDebug(s: string; params args: array of Object);
begin
  self.LogDebug(String.Format(s,  args));
end;


constructor Engine(aParent: Environment; aScriptPath: string; aScript: string := nil);
begin
  fEnvironment := new Environment(aParent);
  fEngine := new EcmaScriptComponent;
  fEngine.DebugTracePoint += fEngineDebugTracePoint;
  fEngine.DebugException += fEngineDebugException;
  fEngine.DebugFrameEnter += fEngineDebugFrameEnter;
  fEngine.DebugFrameExit += fEngineDebugFrameExit;
  fEngine.Debug := true;
  fEngine.Source := coalesce(aScript, File.ReadAllText(aScriptPath));
  fEngine.SourceFileName := aScriptPath;
  var lSettings := Path.ChangeExtension(aScriptPath, 'settings');
  if File.Exists(lSettings) then
    fEnvironment.LoadIni(lSettings);

  lSettings := Path.ChangeExtension(aScriptPath, 'usersettings');
  if File.Exists(lSettings) then
    fEnvironment.LoadIni(lSettings);
end;

method Engine.Run;
begin
  self.fEnvironment['scriptfile'] := Path.GetFullPath(fEngine.SourceFileName);
  self.fEnvironment['scriptdirectory'] := Path.GetDirectoryName(Path.GetFullPath(fEngine.SourceFileName));
  self.fEnvironment['base'] := self.fEnvironment['scriptdirectory'];
  var lEnv := new RemObjects.Builder.API.JEnvironment(self);
  fEngine.GlobalObject.DefineOwnProperty('environment', new PropertyValue(PropertyAttributes.Enumerable, lEnv));
  fEngine.GlobalObject.DefineOwnProperty('vars', new PropertyValue(PropertyAttributes.Enumerable, lEnv));
  fEngine.GlobalObject.DefineOwnProperty('base', new PropertyValue(PropertyAttributes.Enumerable, 
    Utilities.SimpleFunction(self, a -> fEnvironment['base']), 
    Utilities.SimpleFunction(self, a -> begin fEnvironment['base'] := a:FirstOrDefault; exit Undefined.Instance end)));
  fEngine.GlobalObject.AddValue('log', new EcmaScriptObject(fEngine.GlobalObject)
    .AddValue('error', Utilities.SimpleFunction(self, a-> Logger.LogError(a:FirstOrDefault:ToString, a:&Skip(1):ToArray)))
    .AddValue('message', Utilities.SimpleFunction(self, a-> Logger.LogMessage(a:FirstOrDefault:ToString, a:&Skip(1):ToArray)))
    .AddValue('warning', Utilities.SimpleFunction(self, a-> Logger.LogWarning(a:FirstOrDefault:ToString, a:&Skip(1):ToArray)))
    .AddValue('hint', Utilities.SimpleFunction(self, a-> Logger.LogHint(a:FirstOrDefault:ToString, a:&Skip(1):ToArray)))
    .AddValue('debug', Utilities.SimpleFunction(self, a-> Logger.LogDebug(a:FirstOrDefault:ToString, a:&Skip(1):ToArray)))
  );
  fEngine.GlobalObject.AddValue('async', new RemObjects.Script.EcmaScript.Internal.EcmaScriptFunctionObject(fEngine.GlobalObject, 'async', @CallAsync, 1, false, true));
  fEngine.GlobalObject.AddValue('waitFor', Utilities.SimpleFunction(self, (a,b,c) -> begin WaitFor(a,RemObjects .Script.EcmaScript.Utilities.GetArgAsEcmaScriptObject(c, 0, a), RemObjects.Script.EcmaScript.Utilities.GetArgAsInteger(c, 1, a));  exit Undefined.Instance; end));

  Logger:LogMessage('Running script {0}', fEngine.SourceFileName);
  try
    fEngine.Run();
  except
    on e: Exception do
    Logger:LogError('Error while running script {0}: {1}', fengine.SourceFileName, e.Message);
  finally
    Logger:LogMessage('Done running script {0}', fEngine.SourceFileName);
  end;
end;

method Engine.fEngineDebugTracePoint(sender: Object; e: ScriptDebugEventArgs);
begin
  if assigned(e.SourceSpan:File) then
    Logger:LogDebug('Running line {0} ({1}:{2})',e.SourceSpan.File, e.SourceSpan.StartRow, e.SourceSpan.StartCol);
end;

method Engine.fEngineDebugException(sender: Object; e: ScriptDebugEventArgs);
begin
  Logger:LogDebug('Exception {0}',e.Exception:Message);
end;

method Engine.fEngineDebugFrameEnter(sender: Object; e: ScriptDebugEventArgs);
begin
  Logger:LogDebug('Frame enter {0}', e.Name);
end;

method Engine.fEngineDebugFrameExit(sender: Object; e: ScriptDebugEventArgs);
begin
  Logger:LogDebug('Frame exit {0}', e.Name);
end;

method Engine.CreateChildEngine: Engine;
begin
  result := new Engine(Environment, Engine.SourceFileName, Engine.Source, Logger := Logger);
end;

method Engine.CallAsync(aScope: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  var lStart := new System.Threading.Tasks.Task(method begin
    var lEngine := CreateChildEngine;
    // Clone the state here!
   
  end);
  lStart.Start();
  exit lStart;
end;

method Engine.WaitFor(ec: ExecutionContext; args: EcmaScriptObject; aTimeout: Integer);
begin
  var lTasks := new List<System.Threading.Tasks.Task>;
  for i: Integer := 0 to RemObjects.Script.EcmaScript.Utilities.GetObjAsInteger(args.Get(ec, 0, 'length'), ec) -1 do begin
    var lItem := args.Get(ec, 0, i.ToString());
    if lItem is System.Threading.Tasks.Task then 
    lTasks.Add(System.Threading.Tasks.Task(lItem));
  end;
  if length(lTasks) = 0 then ec.Global.RaiseNativeError(NativeErrorType.ReferenceError, 'More than 0 items expected in the first parameter array');
  if aTimeout <0 then
    System.Threading.Tasks.Task.WaitAll(lTasks.ToArray)
  else
    System.Threading.Tasks.Task.WaitAll(lTasks.ToArray, aTimeout);
end;


end.