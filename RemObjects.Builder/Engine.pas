namespace RemObjects.Builder;

interface

uses 
  System.Linq,
  RemObjects.Script, 
  System.Collections.Generic, 
  RemObjects.Script.EcmaScript,
  System.IO;

type
  Environment = public class(Dictionary<string, Object>)
  private
    method get_Item(s : String): Object;
    method set_Item(s : String; value: Object);
  public
    constructor; empty;
    constructor(aEnv: Environment);
    property Previous: Environment;
    property Item[s: string]: Object read get_Item write set_Item; reintroduce;
    method SetGlobal(aName, aValue: string);
    method LoadIni(aPath: String);
    method LoadSystem;
  end;


  Engine = public class
  private
    method fEngineDebugTracePoint(sender: Object; e: ScriptDebugEventArgs);
    method fEngineDebugFrameExit(sender: Object; e: ScriptDebugEventArgs);
    method fEngineDebugFrameEnter(sender: Object; e: ScriptDebugEventArgs);
    method fEngineDebugException(sender: Object; e: ScriptDebugEventArgs);
    fEnvironment: Environment;
    fEngine: EcmaScriptComponent;
  protected
  public
    constructor(aParent: Environment; aScriptPath: string);
    property Engine: EcmaScriptComponent read fEngine;
    property Logger: ILogger;
    property Environment: Environment read fEnvironment;

    method Run;
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


method Environment.get_Item(s: String): Object;
begin
  var lSelf := self;
  while assigned(lSelf) do begin
    if TryGetValue(s, out result) then exit;
    lSelf := lSelf.Previous;
  end;
end;

method Environment.set_Item(s: String; value: Object);
begin
  inherited Item[s] := value;
end;

constructor Environment(aEnv: Environment);
begin
  Previous := aEnv;
end;

method Environment.LoadIni(aPath: String);
begin
  var lIni := new IniFile();
  lIni.LoadFromFile(aPath);
  for each el in lIni.Sections.SelectMany(a->a.Item2, (a,b) -> new Tuple<string, string>(if string.IsNullOrEmpty(a.Item1) then b.Key else a.Item1+'.'+b.Key, b.Value)) do 
    Add(el.Item1, el.Item2);
end;

method Environment.LoadSystem;
begin
  for each el: System.Collections.DictionaryEntry in System.Environment.GetEnvironmentVariables() do begin
    Item[el.Key:ToString] := el.Value:ToString;
  end;
end;

method Environment.SetGlobal(aName: string; aValue: string);
begin
  var lSelf := self;
  while assigned(lSelf) do begin
    if lSelf.Previous = nil then 
      lSelf[aName] := aValue 
    else
      lSelf.Remove(aName);
    lSelf := lSelf.Previous;
  end;
end;

constructor Engine(aParent: Environment; aScriptPath: string);
begin
  fEnvironment := new Environment(aParent);
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