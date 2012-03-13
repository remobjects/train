namespace RemObjects.Train.API;

interface

uses
  RemObjects.Train,
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

    [WrapAs('include')]
    class method Include(aServices: IApiRegistrationServices; aFN: String);
    [WrapAs('sleep')]
    class method Sleep(aServices: IApiRegistrationServices; msec: Int64);
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
    property FuncBody: String;
    property FuncName: String;
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
      lData.Call(Engine.GlobalObject.ExecutionContext, Args);
      exit;
    end;
  end;

  var lValue := EcmaScriptObject(Engine.GlobalObject.eval(Engine.GlobalObject.ExecutionContext, Engine.GlobalObject, FuncBody));
  if lValue = nil then Engine.GlobalObject.RaiseNativeError(NativeErrorType.ReferenceError, 'First parameter in async has to be function');

  try
  lValue.Call(Engine.GlobalObject.ExecutionContext, Args);
  finally
    lValue := nil;
  end;
  
end;

method AsyncRegistration.&Register(aServices: IApiRegistrationServices);
begin
  var lAsync := new AsyncWorker(aServices.Engine);
  aServices.AsyncWorker := lAsync;
  aServices.RegisterValue('include', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(Self), 'Include'));
  aServices.RegisterValue('sleep', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(Self), 'sleep'));
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
  aServices.RegisterValue('waitFor', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, (a,b,c) -> 
    begin 
      lAsync.WaitFor(a, Utilities.GetArgAsEcmaScriptObject(c, 0, a), 
      Utilities.GetArgAsInteger(c, 1, a));  
      exit Undefined.Instance; 
    end));
end;

class method AsyncRegistration.Include(aServices: IApiRegistrationServices; aFN: String);
begin
  aFN := aServices.ResolveWithBase(aFN);
  aServices.Engine.Engine.Include(aFN,System.IO.File.ReadAllText(aFN));
end;

class method AsyncRegistration.Sleep(aServices: IApiRegistrationServices; msec: Int64);
begin
  System.Threading.Thread.Sleep(msec);
end;


method AsyncWorker.CallAsync(aScope: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  var lEngine := fEngine.CreateChildEngine;
  lEngine.Engine.JustFunctions := true;
  lEngine.Initialize;
  lEngine.Engine.Run; // should do nothing now.
  var lLogger := new DelayedLogger;
  lEngine.Logger := lLogger;
  
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
  fEngine.RegisterTask(lStart, String.Format('[{0}] async command', lStart.Id), lLogger);
  exit new TaskWrapper(fEngine.Engine.GlobalObject, fTaskProto, Task := lStart);
end;

method AsyncWorker.WaitFor(ec: ExecutionContext; args: EcmaScriptObject; aTimeout: Integer);
begin
  var lFail := true;
  fEngine.Logger.Enter('waitFor', ''+args+' '+aTimeout);
    var lTasks := new List<System.Threading.Tasks.Task>;
  try
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
      if not System.Threading.Tasks.Task.WaitAll(lTasks.ToArray, aTimeout) then raise new Exception('Timeout waiting for tasks: ');
    lFail := false;
  finally
    for each el in lTasks.Where(a->a.IsCompleted) do
      fEngine.UnregisterTask(el);
    fEngine.Logger.Exit('waitFor', if lFail then FailMode.Yes else FailMode.No);
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
  result := Undefined.Instance;
  var lFail := true;
  fEngine.Logger.Enter('run', args);
  try
    if fEngine.DryRun then exit;
    var lPath := fEngine.ResolveWithBase(Utilities.GetArgAsString(args, 0, aScope));
    
    new Engine(fEngine.Environment, lPath, System.IO.File.ReadAllText(lPath)).Run();
    lFail := false;
  finally
    fEngine.Logger.Exit('run', if lFail then FailMode.Yes else FailMode.No, lFail);
  end;
  
end;

method AsyncWorker.runAsync(aScope: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  result := Undefined.Instance;
  var lFail := true;
  fEngine.Logger.Enter('runAsync', args);
  var lLogger := new DelayedLogger;
  var lPath := fEngine.ResolveWithBase(Utilities.GetArgAsString(args, 0, aScope));
  try
    var lTask := new Task(method begin
      if fEngine.DryRun then exit;
    
      new Engine(fEngine.Environment, lPath, System.IO.File.ReadAllText(lPath), Logger := lLogger).Run();
    end);
    lTask.Start;
    fEngine.RegisterTask(lTask, String.Format('[{0}] runAsync {1}', lTask.Id, fEngine.ResolveWithBase(Utilities.GetArgAsString(args, 0, aScope))), lLogger);
    result := new TaskWrapper(fEngine.Engine.GlobalObject, Task := lTask);
    lFail := false;
  finally
    fEngine.Logger.Exit('runAsync', if lFail then FailMode.Yes else FailMode.No, args);
  end;
end;

method AsyncWorker.expand(aScope: ExecutionContext; aSelf: Object; params args: array of Object): Object;
begin
  var lArg := coalesce(Utilities.GetArgAsString(args, 0, aScope), '');
  

  exit fEngine.Expand(aScope, lArg);
end;


end.
