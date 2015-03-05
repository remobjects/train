namespace RemObjects.Train;

interface

uses
  System.Collections.Generic,
  System.Text;

type
  DelayedLogger = public class(ILogger)
  private
    method set_InIgnore(value: Boolean);
    fInIgnore: Boolean;
    fDelayStore: LinkedList<Tuple<Integer, String, Integer, array of Object>> := new LinkedList<Tuple<Integer, String, Integer,array  of Object>>;
  protected
  public
    method LogError(s: String);
    method LogMessage(s: String);
    method LogWarning(s: String);
    method LogHint(s: String);
    method LogDebug(s: String);
    method LogInfo(s: String);
    method &Write; empty;
    property InIgnore: Boolean read fInIgnore write  set_InIgnore;

    method Enter(aImportant: Boolean := false; aScript: String; params args: array of Object);
    method &Exit(aImportant: Boolean := false; aScript: String; aFailMode: FailMode; aReturn: Object);

    method Replay(aTarget: ILogger);
  end;

implementation

method DelayedLogger.LogError(s: String);
begin
  locking fDelayStore do
  fDelayStore.AddLast(Tuple.Create(0, s, 0,array of Object(nil)));
end;

method DelayedLogger.LogMessage(s: String);
begin
  locking fDelayStore do
  fDelayStore.AddLast(Tuple.Create(1, s, 0,array of Object(nil)));
end;

method DelayedLogger.LogWarning(s: String);
begin
  locking fDelayStore do
  fDelayStore.AddLast(Tuple.Create(2, s, 0,array of Object(nil)));
end;

method DelayedLogger.LogHint(s: String);
begin
  locking fDelayStore do
  fDelayStore.AddLast(Tuple.Create(3, s,0, array of Object(nil)));
end;

method DelayedLogger.LogDebug(s: String);
begin
  locking fDelayStore do
  fDelayStore.AddLast(Tuple.Create(4, s, 0,array of Object(nil)));
end;

method DelayedLogger.Enter(aImportant: Boolean := false; aScript: String; params args: array of Object);
begin
  if LoggerSettings.ShowDebug or aImportant then 
  locking fDelayStore do
  fDelayStore.AddLast(Tuple.Create(5, aScript, 0,args ));
end;

method DelayedLogger.&Exit(aImportant: Boolean := false; aScript: String; aFailMode: FailMode; aReturn: Object);
begin
  if LoggerSettings.ShowDebug or aImportant then 
  locking fDelayStore do
  fDelayStore.AddLast(Tuple.Create(6, aScript, Integer(aFailMode),array of Object([aReturn])));
end;

method DelayedLogger.Replay(aTarget: ILogger);
begin
  var lItem := fDelayStore.First;
  while assigned(lItem) do begin
    case lItem.Value.Item1 of
      0: aTarget.LogError(lItem.Value.Item2);
      1: aTarget.LogMessage(lItem.Value.Item2);
      2: aTarget.LogWarning(lItem.Value.Item2);
      3: aTarget.LogHint(lItem.Value.Item2);
      4: aTarget.LogDebug(lItem.Value.Item2);
      6: aTarget.Enter(true,lItem.Value.Item2, lItem.Value.Item4);
      7: aTarget.Exit(true,lItem.Value.Item2, FailMode(lItem.Value.Item3), lItem.Value.Item4[0]);
      8: aTarget.LogInfo(lItem.Value.Item2);
      9: aTarget.InIgnore := Boolean(lItem.Value.Item3);
    end;
    lItem := lItem.Next;
  end;
end;

method DelayedLogger.LogInfo(s: String);
begin
  fDelayStore.AddLast(Tuple.Create(8, s, 0,array of Object(nil)));
end;

method DelayedLogger.set_InIgnore(value: Boolean);
begin
  if value = fInIgnore then exit;
  fInIgnore := value;

  fDelayStore.AddLast(Tuple.Create(9, '', if value then 1 else 0,array of Object(nil)));
end;

end.
