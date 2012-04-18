namespace RemObjects.Train;

interface

uses 
  System.Linq,
  RemObjects.Script, 
  System.Collections.Generic, 
  RemObjects.Script.EcmaScript,
  RemObjects.Train.API,
  System.IO;

type
  Engine = public class(IApiRegistrationServices)
  private
    class var fGlobalPlugins: SLinkedListNode<IPluginRegistration>;
    var fTasks: List<Tuple<System.Threading.Tasks.Task, String, DelayedLogger>> := new List<Tuple<System.Threading.Tasks.Task, String, DelayedLogger>>;
    fWorkDir : String;
    fErrorPos: nullable PositionPair;
    method fEngineDebugTracePoint(sender: Object; e: ScriptDebugEventArgs);
    method set_WorkDir(value: String);
    method fEngineDebugFrameExit(sender: Object; e: ScriptDebugExitScopeEventArgs);
    method fEngineDebugFrameEnter(sender: Object; e: ScriptDebugEventArgs);
    method fEngineDebugException(sender: Object; e: ScriptDebugEventArgs);
    method RegisterValue(aName: String; aValue: Object); 
    method RegisterProperty(aName: String; aGet: Func<Object>; aSet: Action<Object>);
    method RegisterObjectValue(aName: String): EcmaScriptObject;

    property Globals: GlobalObject read fEngine.GlobalObject;
    property IntEngine: Engine read self; implements IApiRegistrationServices.Engine;
    fEnvironment: Environment;
    fEngine: EcmaScriptComponent;
    fRegEx: System.Text.RegularExpressions.Regex;
  protected
  public
    class constructor;
    method Expand(ec: ExecutionContext; s: String): String;
    constructor(aParent: Environment; aScriptPath: String; aScript: String := nil);
    method ResolveWithBase(ec: ExecutionContext;s: String; aExpand: Boolean := false): String;
    method UnregisterTask(aTask: System.Threading.Tasks.Task);
    method RegisterTask(aTask: System.Threading.Tasks.Task; aSignature: String; aLogger: DelayedLogger);
    property WorkDir: String read fWorkDir write set_WorkDir;
    property Plugins: SLinkedListNode<IPluginRegistration>;
    property Engine: EcmaScriptComponent read fEngine;
    property Logger: ILogger;
    property AsyncWorker: AsyncWorker;
    property Environment: Environment read fEnvironment;
    property DryRun: Boolean;

    method Initialize;
    method LoadInclude(aInclude: String);
    method Run;

    method CreateChildEngine: Engine;
  end;

  AbortException = public class(Exception)
  private
  public
  end;

implementation


constructor Engine(aParent: Environment; aScriptPath: String; aScript: String := nil);
begin
  fEnvironment := new Environment(aParent);
  fEngine := new EcmaScriptComponent;
  if not String.IsNullOrEmpty(aScriptPath) then begin
    WorkDir := Path.GetDirectoryName(aScriptPath);
  end else
    WorkDir := System.Environment.CurrentDirectory;

  fEngine.DebugTracePoint += fEngineDebugTracePoint;
  fEngine.DebugException += fEngineDebugException;
  fEngine.DebugFrameEnter += fEngineDebugFrameEnter;
  fEngine.DebugFrameExit += fEngineDebugFrameExit;
  fEngine.RunInThread := false;
  fEngine.Debug := true;
  fEngine.Source := coalesce(aScript, File.ReadAllText(aScriptPath));
  fEngine.SourceFileName := aScriptPath;
  var lSettings := Path.ChangeExtension(aScriptPath, 'settings');
  if File.Exists(lSettings) then
    fEnvironment.LoadIni(lSettings);

  lSettings := Path.ChangeExtension(aScriptPath, 'usersettings');
  if File.Exists(lSettings) then
    fEnvironment.LoadIni(lSettings);
  Plugins := fGlobalPlugins;
end;

method Engine.Run;
begin
  Initialize;
  var lFail := false;
  Logger.Enter(true,'script', fEngine.SourceFileName);
  try
    fEngine.Run();
    for each el in fTasks do begin
      Logger.LogWarning('Unfinished task was never waited for: {0}', el.Item2);
    end;
    if fTasks.Count > 0 then begin
      Logger.LogMessage('Waiting for unfinished tasks');
      if not System.Threading.Tasks.Task.WaitAll(fTasks.Select(a->a.Item1).ToArray,  TimeSpan.FromSeconds(60)) then 
        Logger.LogMessage('Unfinished tasks timed out');
    end;
  except
    on e: Exception do begin
      lFail := true;
      if e is not AbortException then
        if fErrorPos <> nil then
          Logger:LogError('Error while running script {0} ({2}:{3}): {1}', fErrorPos.File, e.Message, fErrorPos.StartRow, fErrorPos.StartCol)
        else
          Logger:LogError('Error while running script {0}: {1}', fEngine.SourceFileName, e.Message);
      raise new AbortException;
    end;
  finally
    for each el in fTasks.ToArray do 
      UnregisterTask(el.Item1);
    Logger.Exit(true, 'script', if lFail then FailMode.Yes else FailMode.No);
  end;
end;

method Engine.fEngineDebugTracePoint(sender: Object; e: ScriptDebugEventArgs);
begin
  fErrorPos := e.SourceSpan;
  if assigned(e.SourceSpan:File) then
    Logger:LogDebug('Running line {0} ({1}:{2})',e.SourceSpan.File, e.SourceSpan.StartRow, e.SourceSpan.StartCol);
end;

method Engine.fEngineDebugException(sender: Object; e: ScriptDebugEventArgs);
begin
  Logger:LogDebug('Exception {0}',e.Exception:Message);
end;

method Engine.fEngineDebugFrameEnter(sender: Object; e: ScriptDebugEventArgs);
begin
  if e.Name.Contains('.') then exit;
  var lEnv := fEngine.CallStack.LastOrDefault():Frame;
  var n := if (lEnv = nil) or (not lEnv.HasBinding('arguments')) then nil else lEnv.GetBindingValue('arguments', false);
  var ev :=  EcmaScriptObject(n);
  var lArgs: String := '';
  if ev <> nil then begin
    for i: Integer := 0 to RemObjects.Script.ecmascript.Utilities.GetObjAsInteger(ev.Get('length'), fEngine.GlobalObject.ExecutionContext) -1 do begin
      if i <> 0 then lArgs := lArgs + ', ';
      lArgs := lArgs + MUtilities.MyFormat('{0}', ev.Get(i.ToString));
    end;
  end;

  Logger:Enter(true, 'function '+e.Name, lArgs);
end;

method Engine.fEngineDebugFrameExit(sender: Object; e: ScriptDebugExitScopeEventArgs);
begin
  if e.Name.Contains('.') then exit;
  if e.WasException then begin
    var lVal := ScriptRuntimeException.Unwrap(e.Result);
    if lVal is not AbortException then begin
      if lVal is Exception then lVal := Exception(lVal).Message; // don't want the callstack.
      Logger:LogError(lVal:ToString);
    end;
    Logger:&Exit(true, 'function '+e.Name, FailMode.Yes, nil);
  end else
    Logger:&Exit(true, 'function '+e.Name, FailMode.No, ScriptRuntimeException.Unwrap(e.Result));
end;

method Engine.CreateChildEngine: Engine;
begin
  result := new Engine(Environment, Engine.SourceFileName, Engine.Source, Logger := Logger, WorkDir := WorkDir, DryRun := DryRun);
end;


method Engine.RegisterValue(aName: String; aValue: Object);
begin
  fEngine.GlobalObject.DefineOwnProperty(aName, new PropertyValue(PropertyAttributes.Enumerable, EcmaScriptScope.DoTryWrap(fEngine.GlobalObject, aValue)));
end;

method Engine.RegisterProperty(aName: String; aGet: Func<Object>; aSet: Action<Object>);
begin
  fEngine.GlobalObject.DefineOwnProperty(aName, new PropertyValue(PropertyAttributes.Enumerable, MUtilities.SimpleFunction(self, a -> begin
    exit aGet();
  end), MUtilities.SimpleFunction(self, a-> begin
    aSet(EcmaScriptScope.DoTryWrap(fEngine.GlobalObject, coalesce(a:FirstOrDefault, Undefined.Instance)));
    exit Undefined.Instance;
  end)));
end;

class constructor Engine;
begin
  for each el in AppDomain.CurrentDomain.GetAssemblies() do begin
    if el.IsDynamic then continue;
    try
      for each at in el.GetTypes() do begin
        if length(at.GetCustomAttributes(typeOf(PluginRegistrationAttribute), false)) > 0 then begin
          fGlobalPlugins := (Activator.CreateInstance(at) as IPluginRegistration) + fGlobalPlugins;
        end;
      end;
    except // ignore errors
    end;
  end;
end;

method Engine.Initialize;
begin
  self.fEnvironment['scriptfile'] := Path.GetFullPath(fEngine.SourceFileName);
  self.fEnvironment['scriptdirectory'] := Path.GetDirectoryName(Path.GetFullPath(fEngine.SourceFileName));
  self.fEnvironment['base'] := self.fEnvironment['scriptdirectory'];

  for each el in SLinkedListNode<IPluginRegistration>.Enumerate(Plugins) do begin
    el.Register(selF);
  end;

end;

method Engine.LoadInclude(aInclude: String);
begin
  EcmaScriptObject(Globals.Get('run')).Call(Globals.ExecutionContext, aInclude);
end;

method Engine.set_WorkDir(value: String);
begin
  if String.IsNullOrEmpty(value) then value := System.Environment.CurrentDirectory;
  value := Path.GetFullPath(value); // resolve it
  if value <> fWorkDir then begin
    if not Directory.Exists(value) then 
      raise new Exception('Directory not valid: '+value);
    fWorkDir := value;
    Logger:LogMessage('Changing directory to '+value);
  end;
end;

method Engine.ResolveWithBase(ec: ExecutionContext; s: String; aExpand: Boolean := false): String;
begin
  if s = nil then exit nil;
  if aExpand then
    s := Expand(ec,s  );
  if s.StartsWith('~/') or s.StartsWith('~\') then
    s := Path.Combine(system.Environment.GetFolderPath(System.Environment.SpecialFolder.UserProfile), s.Substring(2));
  if System.IO.Path .DirectorySeparatorChar = '\' then
    s:= s.Replace('/', '\');
  if System.IO.Path.IsPathRooted(s) or (s.StartsWith('$')) then
    exit s;
  exit System.IO.Path.Combine(WorkDir, s)
end;

method Engine.RegisterObjectValue(aName: String): EcmaScriptObject;
begin
  result := new EcmaScriptObject(Globals);
  RegisterValue(aName, result);
end;

method Engine.UnregisterTask(aTask: System.Threading.Tasks.Task);
begin
  for each el in fTasks do begin
    if (el.Item1 = aTask) then begin
      if el.Item1.IsCompleted then
        Logger.Enter('Finished Task: '+el.Item2) 
      else
        Logger.Enter('Unfinished Task: '+el.Item2);
      el.Item3.Replay(Logger);
      Logger.Exit('Finished Task: '+el.Item2, if  el.Item1.IsFaulted then FailMode.Yes else FailMode.No);

      el.Item1.Dispose;


      fTasks.Remove(el);
      break;
    end;
  end;
end;

method Engine.RegisterTask(aTask: System.Threading.Tasks.Task; aSignature: String; aLogger: DelayedLogger);
begin
  Logger.LogMessage('Started Task: '+aSignature);
  fTasks.Add(Tuple.Create(aTask, aSignature, aLogger));
end;

method Engine.Expand(ec: ExecutionContext; s: String): String;
begin
  if fRegEx = nil then 
    fRegEx := new System.Text.RegularExpressions.Regex('\$\$|\$(?<value>\([a-zA-Z_\-0-9]+\))|\$(?<value>[a-zA-Z_\-0-9]+)', System.Text.RegularExpressions.RegexOptions.Compiled);
  exit fRegEx.Replace(s, method (match: System.Text.RegularExpressions.Match) begin
   var lValue := match.Groups['value']:Value;
   if lValue = '' then exit '$';
   if lValue.StartsWith('(') and lValue.EndsWith(')') then 
     lValue := lValue.Substring(1, lValue.Length -2);
    
    var lScope := ec:LexicalScope;
    var lRes: String := nil;
    while assigned(lScope) do begin
      if lScope.HasBinding(lValue) then begin
        var n := lScope.GetBindingValue(lValue, false);
        if (n <> nil) and (n <> Undefined.Instance) then begin
          lRes := RemObjects.Script.EcmaScript.Utilities.GetObjAsString(n, ec);
          break;
        end;
      end;
      lScope := lScope.Previous;
    end;
    if (lRes = nil) then lRes := Environment[lValue]:ToString;
    if lRes = nil then lRes := '$'+match.Groups['value']:Value;
    
    exit lRes;
  end);
end;
    


end.