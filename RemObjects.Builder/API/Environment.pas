namespace RemObjects.Builder.API;

interface
uses
  RemObjects.Builder, RemObjects.Script.EcmaScript;

type
  JEnvironment = public class
  private
    fVars: JVariables;
  public
    constructor(aEngine: RemObjects.Builder.Engine);
    property variables: JVariables read fVars;
  end;

  JVariables = public class(EcmaScriptObject)
  private
    fOwner: Engine;
  public
    constructor(aOwner: Engine);
    method DefineOwnProperty(aName: String; aValue: PropertyValue; aThrow: Boolean): Boolean; override;
    method GetOwnProperty(aName: String): PropertyValue; override;
  end;

implementation

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

constructor JEnvironment(aEngine: RemObjects.Builder.Engine);
begin
  fVars := new JVariables(aEngine);
end;

end.