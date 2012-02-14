namespace RemObjects.Builder;

interface

uses 
  System.Linq,
  RemObjects.Script, 
  System.Collections.Generic, 
  System.IO;

type
  Environment = public class(Dictionary<string, Object>)
  private
    method get_Item(s : String): Object;
    method set_Item(s : String; value: Object);
  public
    constructor; empty;
    constructor(aEnv: Environment);
    property Item[s: string]: Object read get_Item write set_Item; reintroduce;
    method Load(aPath: String);
  end;


  Engine = public class
  private
    method fEngineDebugTracePoint(sender: Object; e: ScriptDebugEventArgs);
    method fEngineDebugFrameExit(sender: Object; e: ScriptDebugEventArgs);
    method fEngineDebugFrameEnter(sender: Object; e: ScriptDebugEventArgs);
    method fEngineDebugException(sender: Object; e: ScriptDebugEventArgs);
    fRoot, fEnvironment: Environment;
    fEngine: EcmaScriptComponent;
  protected
  public
    constructor(aRoot, aParent: Environment; aScriptPath: string);
    property Engine: EcmaScriptComponent read fEngine;
    property Logger: ILogger;

    method Run;
  end;

  ILogger = public interface
    method LogError(s: string);
    method LogMessage(s: string);
    method LogWarning(s: string);
    method LogHint(s: string);
    method LogDebug(s: string);
  end;  

extension method ILogger.LogError(s: string; arg0: Object; params args: array of Object);
extension method ILogger.LogMessage(s: string; arg0: Object; params args: array of Object);
extension method ILogger.LogWarning(s: string; arg0: Object; params args: array of Object);
extension method ILogger.LogHint(s: string; arg0: Object; params args: array of Object);
extension method ILogger.LogDebug(s: string; arg0: Object; params args: array of Object);

implementation

extension method ILogger.LogError(s: string; arg0: Object; params args: array of Object);
begin
  self.LogError(String.Format(s, arg0, args));
end;

extension method ILogger.LogMessage(s: string; arg0: Object; params args: array of Object);
begin
  self.LogMessage(String.Format(s, arg0, args));
end;

extension method ILogger.LogWarning(s: string; arg0: Object; params args: array of Object);
begin
  self.LogWarning(String.Format(s, arg0, args));
end;

extension method ILogger.LogHint(s: string; arg0: Object; params args: array of Object);
begin
  self.LogHint(String.Format(s, arg0, args));
end;

extension method ILogger.LogDebug(s: string; arg0: Object; params args: array of Object);
begin
  self.LogDebug(String.Format(s, arg0, args));
end;


method Environment.get_Item(s: String): Object;
begin
  TryGetValue(s, out result);
end;

method Environment.set_Item(s: String; value: Object);
begin
  Item[s] := value;
end;

constructor Environment(aEnv: Environment);
begin
  for each el in aEnv do begin
    Add(el.Key, el.Value);
  end;
end;

method Environment.Load(aPath: String);
begin
  var lIni := new IniFile();
  lIni.LoadFromFile(aPath);
  for each el in lIni.Sections.SelectMany(a->a.Item2, (a,b) -> new Tuple<string, string>(if string.IsNullOrEmpty(a.Item1) then b.Key else a.Item1+'.'+b.Key, b.Value)) do 
    Add(el.Item1, el.Item2);
end;

constructor Engine(aRoot, aParent: Environment; aScriptPath: string);
begin
  fRoot := aRoot;
  fEnvironment := new Environment(coalesce(aParent, aRoot));
  fEngine := new EcmaScriptComponent;
  fEngine.DebugTracePoint += fEngineDebugTracePoint;
  fEngine.DebugException += fEngineDebugException;
  fEngine.DebugFrameEnter += fEngineDebugFrameEnter;
  fEngine.DebugFrameExit += fEngineDebugFrameExit;
  fEngine.Debug := true;
  fEngine.Source := File.ReadAllText(aScriptPath);
  fEngine.SourceFileName := aScriptPath;
  var lSettings := Path.ChangeExtension(aScriptPath, 'settings');
  if File.Exists(lSettings) then
    fEnvironment.Load(lSettings);

  lSettings := Path.ChangeExtension(aScriptPath, 'usersettings');
  if File.Exists(lSettings) then
    fEnvironment.Load(lSettings);
end;

method Engine.Run;
begin
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

end.