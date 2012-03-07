namespace RemObjects.Builder.API;

interface

uses
  System.Collections.Generic,
  System.Linq,
  System.Text;

type
  Wrapper = public class
  private
    fMethod: System.Reflection.MethodInfo;
    fWrapInfo: WrapAsAttribute;
    fServices: IApiRegistrationServices;
  protected
  public
    constructor(aServices: IApiRegistrationServices; aMethod: System.Reflection.MethodInfo);

    method Run(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; aArgs: array of Object): Object;

    method Convert(aVal: Object; aDestType: &Type; aDefault: Object): Object;
    method ConvertBack(aVal: Object): Object;
  end;
  WrapAsAttribute = public class(Attribute)
  private
    fLogName : String;
  public
    constructor(aLogName: string);
    property WantExecutionContext: Boolean;
    property WantSelf: Boolean;
    property LogName: string read fLogName;
  end;

implementation

constructor WrapAsAttribute(aLogName: string);
begin
  fLogName := aLogName;
end;

constructor Wrapper(aServices: IApiRegistrationServices; aMethod: System.Reflection.MethodInfo);
begin
  fMethod := aMethod;
  fServices := aServices;
  fWrapInfo := array of WrapAsAttribute(aMethod.GetCustomAttributes(typeof(WrapAsAttribute), false)):First;
end;

method Wrapper.Run(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; aArgs: array of Object): Object;
begin
  result := RemObjects.Script.EcmaScript.Undefined.Instance;
  fServices.Logger.Enter(fWrapInfo.LogName, aArgs);
  try
    if fServices.Engine.DryRun then exit;
    var lList := new List<Object>;
    var lArgs := fMethod.GetParameters().ToList();
    if largs.FirstOrDefault:ParameteRType = typeof(IApiRegistrationServices) then begin
      lList.Add(fservices);
      lArgs.RemoveAt(0);
    end;
    if fWrapInfo.WantExecutionContext then begin
      if lArgs.First.ParameterType <> typeOf(RemObjects.Script.EcmaScript.ExecutionContext) then raise new Exception('No EC as first parameter');
      lList.Add(ec);
      lArgs.RemoveAt(0);
    end;
    if fWrapInfo.WantSelf then begin
      lList.Add(aSelf);
      lArgs.RemoveAt(0);
    end;

    var lInArgs := aArgs.ToList;
    while (lInArgs.Count>0) and (lARgs.Count > 0) do begin
      lList.Add(Convert(lInargs[0], lArgs[0].ParameterType, lArgs[0].RawDefaultValue));
      lArgs.RemoveAt(0);
      lInArgs.RemoveAt(0);
    end;
    while lArgs.Count > 0 do begin
      if lArgs[0].RawDefaultValue = DBNull.Value then
        lList.Add(nil)
      else 
        lList.Add(lArgs[0].RawDefaultValue);
      lArgs.RemoveAt(0);
    end;

    exit ConvertBack(fMethod.Invoke(nil, lList.ToArray));
  except
    on e: System.Reflection.TargetInvocationException do
      raise e.InnerException;
  finally
    fServices.Logger.Exit(fWrapInfo.LogName, aArgs);
  end;
end;

method Wrapper.Convert(aVal: Object; aDestType: &Type; aDefault: Object): Object;
begin
  if (aVal = nil) or (aVal = RemObjects.Script.EcmaScript.Undefined.Instance) then aVal := aDefault;
  if aVal = DBNull.Value then aVal := nil;
  if (aDestType.IsArray) and (aVal is RemObjects.Script.EcmaScript.EcmaScriptArrayObject) then begin
    var lArr := RemObjects.Script.EcmaScript.EcmaScriptArrayObject(aval);
    Result := Array.CreateInstance(aDestType.GetElementType(), lARr.Length);
    for i: Integer := 0 to lArr.Length -1 do begin
      Array(Result).SetValue(Convert(lArr.Get(self.fServices.Globals.ExecutionContext, 0, i.ToString()), aDestType.GetElementType(), nil), i);
    end;
  end else if (&Type.GetTypeCode(aDestType) = TypeCode.Object) and (aVal is RemObjects.Script.EcmaScript.EcmaScriptObject) then begin
    var lVal := RemObjects.Script.EcmaScript.EcmaScriptObject(aVal);
    result := Activator.CreateInstance(aDestType);
    for each el in aDestType.GetProperties(System.Reflection.BindingFlags.Public or System.Reflection.BindingFlags.Instance) do begin
      if not el.CanRead or not el.CanWrite then continue;
      var lEl := lVal.Get(fServices.Globals.ExecutionContext, 0, el.Name);
      if (lEl <> nil) and (lEl <> RemObjects.Script.EcmaScript.Undefined.Instance) then begin
        el.SetValue(result, Convert(lEl, el.PropertyType, nil), []);
      end;
    end;
  end else
    exit System.Convert.ChangeType(aVal, aDestType);
end;

method Wrapper.ConvertBack(aVal: Object): Object;
begin
  exit aVal;
end;

end.
