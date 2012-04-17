namespace RemObjects.Train.API;

interface
uses
  RemObjects.Train, RemObjects.Script.EcmaScript, System.Collections.Generic, System.Linq;

type
  JVariables = public class(EcmaScriptObject)
  private
    fOwner: Engine;
  public
    property Owner: Engine read fOwner;
    constructor(aOwner: Engine);
    method DefineOwnProperty(aName: String; aValue: PropertyValue; aThrow: Boolean): Boolean; override;
    method GetOwnProperty(aName: String): PropertyValue; override;
  end;
  Environment = public class(Dictionary<String, Object>)
  private
    fPrevious : RemObjects.Train.API.Environment; readonly;
    method get_Item(s : String): Object;
    method set_Item(s : String; value: Object);
  public
    constructor; 
    method &Add(key: String; value: Object); reintroduce;
    method Clear; reintroduce;
    constructor(aEnv: Environment);
    property Previous: Environment read fPrevious;
    property Item[s: String]: Object read get_Item write set_Item; reintroduce;
    method SetGlobal(aName: String; aValue: Object);
    method LoadIni(aPath: String);
    method LoadSystem;
  end;

  [PluginRegistration]
  EnvironmentRegistration = public class(IPluginRegistration)
  private
  public
    method &Register(aServices: IApiRegistrationServices);
  end;

implementation

method EnvironmentRegistration.&Register(aServices: IApiRegistrationServices);
begin
  var lEnv := new RemObjects.Train.API.JVariables(aServices.Engine);
  aServices.RegisterValue('env', lEnv);
  aServices.RegisterProperty('wd', -> aServices.Engine.WorkDir, a-> begin aServices.Engine.WorkDir := Utilities.GetObjAsString(a, aServices.Globals.ExecutionContext) end);
  aServices.RegisterValue('export', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, a-> begin
    aServices.Logger.Enter('export', a);
    try
      var lValue := a.Skip(1):FirstOrDefault();
      if lValue is EcmaScriptObject then 
      lValue := Utilities.GetObjectAsPrimitive(aServices.Globals.ExecutionContext, EcmaScriptObject(lValue), PrimitiveType.None);
      lEnv.Owner.Environment.SetGlobal(a:FirstOrDefault():ToString, lValue);
      System.Environment.SetEnvironmentVariable(a:FirstOrDefault():ToString, lValue:ToString);
      exit Undefined.Instance;
    finally
      aServices.Logger.Exit('export', FailMode.No);
    end;
  end));
  aServices.RegisterValue('ignoreErrors', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, (a, b, c) -> 
    begin 
    aServices.Logger.Enter('ignoreErrors', c);
    var lFail := false;
    try
      try
        result := (c.FirstOrDefault as EcmaScriptObject):Call(a, c.Skip(1):ToArray);
      except
        on e: Exception do begin
          lFail := true;
          if e is AbortException then 
          aServices.Engine.Logger.LogWarning('Ignoring error') else
          aServices.Engine.Logger.LogWarning('Ignoring error: '+e.Message);
          result := Undefined.Instance; 
        end;
      end;
    finally
      aServices.Logger.Exit('ignoreErrors', if lFail then FailMode.Recovered else FailMode.No);
    end;
    end));
  aServices.RegisterValue('retry', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, (a, b, c) -> 
    begin
      aServices.Logger.Enter('retry', c);
      var lFailMode := FailMode.No;
      try
        var lCount := Utilities.GetArgAsInteger(c, 0, a, false);
        loop begin
          try
            dec(lCount);
            result := (c.Skip(1).FirstOrDefault as EcmaScriptObject):Call(a, c.Skip(2):ToArray);
            break;
          except
            on e: Exception do begin
              
              if lCount > 0 then begin
                lFailMode := FailMode.Recovered;
                if e is AbortException then 
                  aServices.Engine.Logger.LogWarning('Ignoring error') 
                else
                  aServices.Engine.Logger.LogWarning('Ignoring error: '+e.Message);
                continue;
              end;
              aServices.Engine.Logger.LogError(e);
              lFailMode := FailMode.Yes;
              raise new AbortException;
            end;
          end;
        end;
      finally
        aServices.Logger.Exit('retry', lFailMode);
      end;
    end));

 end;

method JVariables.DefineOwnProperty(aName: String; aValue: PropertyValue; aThrow: Boolean): Boolean;
begin
  fOwner.Environment[aName] := aValue:Value;
end;

method JVariables.GetOwnProperty(aName: String): PropertyValue;
begin
  var lValue := fOwner.Environment[aName];
  if lValue = nil then exit nil;
  exit new PropertyValue(PropertyAttributes.Configurable or PropertyAttributes.Enumerable, lValue);
end;

constructor JVariables(aOwner: Engine);
begin
  inherited constructor(aOwner.Engine.GlobalObject);
  fOwner := aOwner;
end;



method Environment.get_Item(s: String): Object;
begin
  var lSelf := self;
  while assigned(lSelf) do begin
    locking lSelf do begin
      if lSelf.TryGetValue(s, out result) then exit;
    end;
    lSelf := lSelf.Previous;
  end;
end;

method Environment.set_Item(s: String; value: Object);
begin
  locking self do 
    inherited Item[s] := value;
end;

constructor Environment(aEnv: Environment);
begin
  inherited constructor(StringComparer.InvariantCultureIgnoreCase);
  fPrevious := aEnv;
end;

method Environment.LoadIni(aPath: String);
begin
  locking self do begin
    var lIni := new IniFile();
    lIni.LoadFromFile(aPath);
    for each el in lIni.Sections.SelectMany(a->a.Item2, (a,b) -> new Tuple<String, String>(if String.IsNullOrEmpty(a.Item1) or (a.Item1.ToLowerInvariant() = 'globals') then b.Key else a.Item1+'.'+b.Key, b.Value)) do 
      Add(el.Item1, el.Item2);
  end;
end;

method Environment.LoadSystem;
begin
  locking self do begin
    for each el: System.Collections.DictionaryEntry in System.Environment.GetEnvironmentVariables() do begin
      var lVal := el.Value:ToString:Trim;
      if not String.IsNullOrEmpty(lVal) then 
        inherited Item[el.Key:ToString] := lVal;
    end;
  end;
end;

method Environment.SetGlobal(aName: String; aValue: Object);
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

method Environment.&Add(key: String; value: Object);
begin
  locking self do begin
    inherited Add(key, value);
  end;
end;

method Environment.Clear;
begin
  locking self do inherited Clear;
end;

constructor Environment;
begin
  inherited constructor(StringComparer.InvariantCultureIgnoreCase);
end;



end.