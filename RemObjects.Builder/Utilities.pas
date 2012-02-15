namespace RemObjects.Builder;

interface

uses
  System.Collections.Generic,
  RemObjects.Script.EcmaScript,
  RemObjects.Script.EcmaScript.Internal,
  System.Text;

type
  Utilities = public class
  private
  protected
  public
    class method SimpleFunction(aOwner: Engine; aDelegate: InternalDelegate): EcmaScriptFunctionObject;
    class method SimpleFunction(aOwner: Engine; aDelegate: Func<Object, array of Object, Object>): EcmaScriptFunctionObject;
    class method SimpleFunction(aOwner: Engine; aDelegate: Func<array of Object, Object>): EcmaScriptFunctionObject;
  end;

implementation

class method Utilities.SimpleFunction(aOwner: Engine; aDelegate: InternalDelegate): EcmaScriptFunctionObject;
begin
  exit new EcmaScriptFunctionObject(aOwner.Engine.GlobalObject, '', aDelegate, 0, false, false);
end;

class method Utilities.SimpleFunction(aOwner: Engine; aDelegate: Func<Object, array of Object, Object>): EcmaScriptFunctionObject;
begin
  exit SimpleFunction(aOwner, (a,b,c) -> aDelegate(b,c));
end;

class method Utilities.SimpleFunction(aOwner: Engine; aDelegate: Func<array of Object, Object>): EcmaScriptFunctionObject;
begin
  exit SimpleFunction(aOwner, (a,b,c) -> aDelegate(c));
end;

end.
