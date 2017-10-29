namespace RemObjects.Train;

interface

uses
  System.Collections.Generic,
  System.Linq,
  RemObjects.Script.EcmaScript,
  RemObjects.Script.EcmaScript.Internal,
  System.Text;

type
  MUtilities = public class
  private
  protected
  public
    class method SimpleFunction(aOwner: Engine; aDelegate: InternalDelegate): EcmaScriptFunctionObject;
    class method SimpleFunction(aOwner: Engine; aDelegate: Func<Object, array of Object, Object>): EcmaScriptFunctionObject;
    class method SimpleFunction(aOwner: Engine; aDelegate: Func<array of Object, Object>): EcmaScriptFunctionObject;
    class method SimpleFunction(aOwner: Engine; aType: &Type; aMethod: String; aProto: EcmaScriptObject := nil; aExpand: Boolean := true): EcmaScriptFunctionObject;
    class method Windows: Boolean;

    class method MyFormat(s: String; params args: array of Object): String;
  end;

  SLinkedListNode<T> = public readonly class
  private
    fValue : T;
    fNext : SLinkedListNode<T>;
  public
    constructor(aNext: SLinkedListNode<T>; aValue: T);
    property Value: T read fValue;
    property Next: SLinkedListNode<T> read fNext;
    class method Enumerate(aValue: SLinkedListNode<T>): sequence of T; iterator; // DO NOT MAKE INSTANCE; has to allow calls on NIL
    class operator Add(aLeft: T; aRight: SLinkedListNode<T>): SLinkedListNode<T>;
  end;

  extension method String.Quote: String;

implementation

constructor SLinkedListNode<T>(aNext: SLinkedListNode<T>; aValue: T);
begin
  fNext := aNext;
  fValue := aValue;
end;

class operator SLinkedListNode<T>.Add(aLeft: T; aRight: SLinkedListNode<T>): SLinkedListNode<T>;
begin
  exit new SLinkedListNode<T>(aRight, aLeft);
end;

class method SLinkedListNode<T>.Enumerate(aValue: SLinkedListNode<T>): sequence of  T;
begin
  while assigned(aValue) do begin
    yield aValue.Value;
    aValue := aValue.Next;
  end;
end;

class method MUtilities.SimpleFunction(aOwner: Engine; aDelegate: InternalDelegate): EcmaScriptFunctionObject;
begin
  exit new EcmaScriptFunctionObject(aOwner.Engine.GlobalObject, '', aDelegate, 0, false, false);
end;

class method MUtilities.SimpleFunction(aOwner: Engine; aDelegate: Func<Object, array of Object, Object>): EcmaScriptFunctionObject;
begin
  exit SimpleFunction(aOwner, (a,b,c) -> aDelegate(b,c));
end;

class method MUtilities.SimpleFunction(aOwner: Engine; aDelegate: Func<array of Object, Object>): EcmaScriptFunctionObject;
begin
  exit SimpleFunction(aOwner, (a,b,c) -> aDelegate(c));
end;

class method MUtilities.Windows: Boolean;
begin
  exit Environment.OSVersion.Platform in [PlatformID.Win32NT, PlatformID.Win32S, PlatformID.Win32Windows, PlatformID.WinCE];
end;

class method MUtilities.SimpleFunction(aOwner: Engine; aType: &Type; aMethod: String; aProto: EcmaScriptObject := nil; aExpand: Boolean := true): EcmaScriptFunctionObject;
begin
  var lRes := new RemObjects.Train.API.Wrapper(aOwner, aType.GetMethod(aMethod), aProto, DoExpand := aExpand);

  exit new EcmaScriptFunctionObject(aOwner.Engine.GlobalObject, aMethod, @lRes.Run, 0);
end;

class method MUtilities.MyFormat(s: String; params args: array of Object): String;
begin
  if (length(args) = 1) and (args[0] <> nil) and (args[0] is Array) then
    args := Array(args).OfType<Object>.ToArray;
  for i: Integer := 0 to length(args) -1 do
    if args[i] is EcmaScriptObject then
      args[i] := EcmaScriptObject(args[i]).Root.JSONStringify(EcmaScriptObject(args[i]).Root.ExecutionContext, nil, EcmaScriptObject(args[i]));
  exit String.Format(s, args);
end;

extension method String.Quote: String;
begin
  result := '"' + self + '"';
end;


end.