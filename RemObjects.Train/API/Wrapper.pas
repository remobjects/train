namespace RemObjects.Train.API;

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
    fProto: RemObjects.Script.EcmaScript.EcmaScriptObject;
  protected
  public
    constructor(aServices: IApiRegistrationServices; aMethod: System.Reflection.MethodInfo; aProto: RemObjects.Script.EcmaScript.EcmaScriptObject);

    method Run(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; aArgs: array of Object): Object;

    method Convert(aVal: Object; aDestType: &Type; aDefault: Object): Object;
    method ConvertBack(aVal: Object): Object;
  end;
  WrapAsAttribute = public class(Attribute)
  private
    fLogName : String;
  public
    constructor(aLogName: String);
    property WantSelf: Boolean;
    property Important: Boolean := true;
    property SkipDryRun: Boolean;
    property LogName: String read fLogName;
  end;

  WrapperObject = public class(RemObjects.Script.EcmaScript.EcmaScriptObject)
  private
  public
    property Val: Object;
  end;

implementation

constructor WrapAsAttribute(aLogName: String);
begin
  fLogName := aLogName;
end;

constructor Wrapper(aServices: IApiRegistrationServices; aMethod: System.Reflection.MethodInfo; aProto: RemObjects.Script.EcmaScript.EcmaScriptObject);
begin
  fMethod := aMethod;
  fProto := aProto;
  fServices := aServices;
  fWrapInfo := array of WrapAsAttribute(aMethod.GetCustomAttributes(typeOf(WrapAsAttribute), false)):First;
end;

method Wrapper.Run(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; aArgs: array of Object): Object;
begin
  result := RemObjects.Script.EcmaScript.Undefined.Instance;
  fServices.Logger.Enter(fWrapInfo.Important, fWrapInfo.LogName, aArgs);
  var lFail := true;
  try
    if (fServices.Engine.DryRun) and (fWrapInfo.SkipDryRun) then begin lFail := false; exit; end;
    var lList := new List<Object>;
    var lArgs := fMethod.GetParameters().ToList();
    if lArgs.FirstOrDefault:ParameterType = typeOf(IApiRegistrationServices) then begin
      lList.Add(fServices);
      lArgs.RemoveAt(0);
    end;
    if lArgs.FirstOrDefault:ParameterType = typeOf(RemObjects.Script.EcmaScript.ExecutionContext) then begin
//      if lArgs.First.ParameterType <> typeOf(RemObjects.Script.EcmaScript.ExecutionContext) then raise new Exception('No EC as first parameter');
      lList.Add(ec);
      lArgs.RemoveAt(0);
    end;
    if fWrapInfo.WantSelf then begin
      lList.Add(Convert(aSelf, lArgs[0].ParameterType, nil));
      lArgs.RemoveAt(0);
    end;

    var lInArgs := aArgs.ToList;
    var lPargs: System.Collections.ArrayList := nil;
    while (lInArgs.Count>0) and (lArgs.Count > 0) do begin
      if (lArgs.First.ParameterType.IsArray) and (length(lArgs.First.GetCustomAttributes(typeOf(ParamArrayAttribute), true)) > 0) then begin
        if lPargs = nil then lPargs := new System.Collections.ArrayList;
        lPargs.Add(Convert(lInArgs[0], lArgs[0].ParameterType.GetElementType, nil));
        lInArgs.RemoveAt(0);
      end else begin
        lList.Add(Convert(lInArgs[0], lArgs[0].ParameterType, lArgs[0].RawDefaultValue));
        lArgs.RemoveAt(0);
        lInArgs.RemoveAt(0);
      end;
    end;
    if lPargs <> nil then begin
      lArgs.RemoveAt(0);
      lList.Add(lPargs.ToArray(fMethod.GetParameters().Last.ParameterType.GetElementType));
    end;
    while lArgs.Count > 0 do begin
      if lArgs[0].RawDefaultValue = DBNull.Value then
        lList.Add(nil)
      else 
        lList.Add(lArgs[0].RawDefaultValue);
      lArgs.RemoveAt(0);
    end;

    result := ConvertBack(fMethod.Invoke(nil, lList.ToArray));
    lFail := false;
  except
    on e: System.Reflection.TargetInvocationException do begin
      fServices.Logger.LogError(e.InnerException.Message);
      raise e.InnerException;
    end;
  finally
    fServices.Logger.Exit(fWrapInfo.Important, fWrapInfo.LogName, if lFail then RemObjects.Train.FailMode.Yes else RemObjects.Train.FailMode.No, aArgs );
  end;
end;

method Wrapper.Convert(aVal: Object; aDestType: &Type; aDefault: Object): Object;
begin
  if (aVal = nil) or (aVal = RemObjects.Script.EcmaScript.Undefined.Instance) then aVal := aDefault;
  if aVal = DBNull.Value then aVal := nil;
  if aVal is WrapperObject then 
    exit WrapperObject(aVal).Val else 
  if (aDestType.IsArray) and (aVal is RemObjects.Script.EcmaScript.EcmaScriptArrayObject) then begin
    var lArr := RemObjects.Script.EcmaScript.EcmaScriptArrayObject(aVal);
    Result := Array.CreateInstance(aDestType.GetElementType(), lArr.Length);
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
  end else if aVal = RemObjects.Script.EcmaScript.Undefined.Instance then exit nil 
  else if (aDestType = typeOf(String)) and (aVal is RemObjects.Script.EcmaScript.EcmaScriptObject) then begin
    exit aVal.ToString
  end else
    exit System.Convert.ChangeType(aVal, aDestType);
end;

method Wrapper.ConvertBack(aVal: Object): Object;
begin
  if aVal = nil then exit nil;
  if aVal is Array then begin
    var lArr := new RemObjects.Script.EcmaScript.EcmaScriptArrayObject(0, fServices.Globals);
    for i: Integer := 0 to Array(aVal).Length -1 do
      lArr.AddValue(ConvertBack(Array(aVal).GetValue(i)));
    exit lArr;
  end;

  if &Type.GetTypeCode(aVal.GetType()) = TypeCode.Object then
    exit new WrapperObject(fServices.Globals, fProto, &Class := aVal.GetType().Name, Val := aVal);
  exit aVal;
end;

end.
