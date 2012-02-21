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
