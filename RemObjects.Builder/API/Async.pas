namespace RemObjects.Builder.API;

interface

uses
  RemObjects.Builder,
  RemObjects.Script,
  RemObjects.Script.EcmaScript,
  System.Collections.Generic,
  System.Linq,
  System.Text, 
  System.Threading.Tasks;

type
  [PluginRegistration]
  &AsyncRegistration = public class(IPluginRegistration)
  private
  protected
  public
    method &Register(aServices: IApiRegistrationServices);
  end;
  TaskWrapper = public class(EcmaScriptObject)
  public
    property Task: Task;
  end;


  AsyncWorker = public class
  private
    method CloneScope(aInput: EnvironmentRecord; aTarget: GlobalObject);
    method MakeSafe(aInput: GlobalObject; aValue: Object): Object;
    fEngine: Engine;
    fTaskProto: EcmaScriptObject;
    fRegEx: System.Text.RegularExpressions.Regex;
  public
    constructor(aEngine: Engine);
    property TaskProto: EcmaScriptObject read fTaskProto;
    method CallAsync(aScope: ExecutionContext; aSelf: Object; params args: array of Object): Object;
    method run(aScope: ExecutionContext; aSelf: Object; params args: array of Object): Object;
    method runAsync(aScope: ExecutionContext; aSelf: Object; params args: array of Object): Object;
    method expand(aScope: ExecutionContext; aSelf: Object; params args: array of Object): Object;
    method WaitFor(ec: ExecutionContext; args: EcmaScriptObject; aTimeout: Integer);
  end;


  AsyncRun = public class
  private
  public
    property FuncBody: string;
    property FuncName: string;
    property Engine: EcmaScriptComponent;
    property Args: array of Object;
    method Run;
  end;
implementation

method AsyncRun.Run;
begin
  if FuncName  <> nil then begin
    var lData := EcmaScriptObject(Engine.GlobalObject.Get(FuncName));
    if lData <> nil then begin
      lData.Call(Engine.GlobalObject.ExecutionContext, args);
      exit;
    end;
  end;

  var lValue := EcmaScriptObject(Engine.GlobalObject.eval(Engine.GlobalObject.ExecutionContext, Engine.GlobalObject, FuncBody));
  if lValue = nil then Engine.GlobalObject.RaiseNativeError(NativeErrorType.ReferenceError, 'First parameter in async has to be function');

  try
  lValue.Call(Engine.GlobalObject.ExecutionContext, args);
  finally
    lValue := nil;
  end;
  
end;

method AsyncRegistration.&Register(aServices: IApiRegistrationServices);
begin
  var lAsync := new AsyncWorker(aServices.Engine);
  aServices.AsyncWorker := lAsync;
  aServices.RegisterValue('async', 
    new RemObjects.Script.EcmaScript.Internal.EcmaScriptFunctionObject(aServices.Globals, 
    'async', @lAsync.CallAsync, 1, false, true));  
  aServices.RegisterValue('run', 
    new RemObjects.Script.EcmaScript.Internal.EcmaScriptFunctionObject(aServices.Globals, 
    'run', @lAsync.run, 1, false, true));
  aServices.RegisterValue('runAsync', 
    new RemObjects.Script.EcmaScript.Internal.EcmaScriptFunctionObject(aServices.Globals, 
    'runAsync', @lAsync.runAsync, 1, false, true));
  aServices.RegisterValue('expand', 
    new RemObjects.Script.EcmaScript.Internal.EcmaScriptFunctionObject(aServices.Globals, 
    'expand', @lAsync.expand, 1, false, true));
  aServices.RegisterValue('waitFor', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, (a,b,c) -> 
    begin 
      lAsync.WaitFor(a, Utilities.GetArgAsEcmaScriptObject(c, 0, a), 
      Utilities.GetArgAsInteger(c, 1, a));  
      exit Undefined.Instance; 
    end));
end;


method AsyncWorker.CallAsync(aScope: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  var lEngine := fEngine.CreateChildEngine;
  lEngine.Engine.JustFunctions := true;
  lEngine.Initialize;
  lEngine.Engine.Run; // should do nothing now.
  
  CloneScope(aScope.LexicalScope, lEngine.Engine.GlobalObject);
  for i: Integer := 1 to length(args) -1 do begin
    args[i] := MakeSafe(aScope.Global, args[i]);
  end;
  var lRun := new AsyncRun;
  var lFunc := EcmaScriptBaseFunctionObject(args[0]);
  if  lFunc = nil then aScope.Global.RaiseNativeError(NativeErrorType.ReferenceError, 'First parameter in async has to be function');
  lRun.FuncName := lFunc.OriginalName;
  lRun.Engine := lEngine.Engine;
  lRun.FuncBody := EcmaScriptInternalFunctionObject(lFunc):OriginalBody;
  lRun.Args := args.Skip(1).ToArray;
  if (lRun.FuncName = nil) and (lRun.FuncBody = nil) then aScope.Global.RaiseNativeError(NativeErrorType.ReferenceError, 'First parameter in async has to be function');
  
  var lStart := new System.Threading.Tasks.Task(@lRun.Run);
  lStart.Start();
  exit new TaskWrapper(fEngine.Engine.GlobalObject, fTaskProto, Task := lStart);
end;

method AsyncWorker.WaitFor(ec: ExecutionContext; args: EcmaScriptObject; aTimeout: Integer);
begin
  fEngine.Logger.Enter('waitFor', ''+args+' '+aTimeout);
  try
    var lTasks := new List<System.Threading.Tasks.Task>;
    for i: Integer := 0 to RemObjects.Script.EcmaScript.Utilities.GetObjAsInteger(args.Get(ec, 0, 'length'), ec) -1 do begin
      var lItem := args.Get(ec, 0, i.ToString());
      if lItem is TaskWrapper then begin
      lTasks.Add(TaskWrapper(lItem).Task);
      end else 
        raise new Exception('Array element '+i+' in call to waitFor is not a task');
    end;
    if length(lTasks) = 0 then ec.Global.RaiseNativeError(NativeErrorType.ReferenceError, 'More than 0 items expected in the first parameter array');
    if aTimeout <=0 then
      System.Threading.Tasks.Task.WaitAll(lTasks.ToArray)
    else
      if not System.Threading.Tasks.Task.WaitAll(lTasks.ToArray, aTimeout) then raise new Exception('Timeout waiting for tasks');
  finally
    fEngine.Logger.Exit('waitFor');
  end;
end;

constructor AsyncWorker(aEngine: Engine);
begin
  fEngine := aEngine;
  fTaskProto := new EcmaScriptObject(aEngine.Engine.GlobalObject, &Class :='Task');
end;

method AsyncWorker.CloneScope(aInput: EnvironmentRecord; aTarget: GlobalObject);
begin
  if aInput = nil then exit;
  CloneScope(aInput.Previous, aTarget);
  if aInput.IsDeclarative then begin
    var lData := DeclarativeEnvironmentRecord(aInput);
    for each el in lData.Bag do begin
      if not aTarget.HasProperty(el.Key) then
        aTarget.AddValue(el.Key, MakeSafe(aInput.Global, el.Value.Value));
    end;
  end;
end;

method AsyncWorker.MakeSafe(aInput: GlobalObject; aValue: Object): Object;
begin
  if aValue is EcmaScriptObject then
    exit Utilities.GetObjectAsPrimitive(aInput.ExecutionContext, EcmaScriptObject(aValue), PrimitiveType.None);
  exit aValue;
end;

method AsyncWorker.run(aScope: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  result := undefined.Instance;
  fEngine.Logger.Enter('run', args);
  try
    if fEngine.DryRun then exit;
    var lPath := fEngine.ResolveWithBase(Utilities.GetArgAsString(args, 0, aScope));
    
    new Engine(fEngine.Environment, lPath, System.IO.File.ReadAllText(lPath)).Run();
  finally
    fEngine.Logger.Exit('run', args);
  end;
  
end;

method AsyncWorker.runAsync(aScope: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  result := undefined.Instance;
  fEngine.Logger.Enter('runAsync', args);
  try
    var lTask := new Task(method begin
      if fEngine.DryRun then exit;
      var lPath := fEngine.ResolveWithBase(Utilities.GetArgAsString(args, 0, aScope));
    
      new Engine(fEngine.Environment, lPath, System.IO.File.ReadAllText(lPath)).Run();
    end);
    lTask.Start;
    exit new TaskWrapper(fEngine.Engine.GlobalObject, Task := lTask);
  finally
    fEngine.Logger.Exit('runAsync', args);
  end;
end;

method AsyncWorker.expand(aScope: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  var lArg := coalesce(Utilities.GetArgAsString(args, 0, aScope), '');
  

  if fRegex = nil then 
    fRegEx := new System.Text.RegularExpressions.Regex('\$\$|\$(?<value>\([a-zA-Z_\-0-9]+\))|\$(?<value>[a-zA-Z_\-0-9]+)', System.Text.RegularExpressions.RegexOptions.Compiled);
  exit fRegEx.Replace(lArg, method (match: System.Text.RegularExpressions.Match) begin
   var lValue := match.Groups['value']:Value;
   if lValue = '' then exit '$';
   if lValue.StartsWith('(') and lValue.EndsWith(')') then 
     lValue := lValue.Substring(1, lValue.Length -2);
   exit utilities.GetObjAsString(aScope.LexicalScope.GetBindingValue(lValue, false), aScope);
  end);
  //Log.de
end;

end.
