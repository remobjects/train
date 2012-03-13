namespace RemObjects.Train;

interface

uses
  System.Collections.Generic,
  System.Text;

type
  DelayedLogger = public class(ILogger)
  private
    fDelayStore: LinkedList<Tuple<Integer, String, Integer, array of Object>> := new LinkedList<Tuple<Integer, String, Integer,array  of Object>>;
  protected
  public
    method LogError(s: String);
    method LogMessage(s: String);
    method LogWarning(s: String);
    method LogHint(s: String);
    method LogDebug(s: String);
    method Enter(aScript: String; params args: array of Object);
    method &Exit(aScript: String; aFailMode: FailMode; params args: array of Object);

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

method DelayedLogger.Enter(aScript: String; params args: array of Object);
begin
  locking fDelayStore do
  fDelayStore.AddLast(Tuple.Create(5, aScript, 0,args ));
end;

method DelayedLogger.&Exit(aScript: String; aFailMode: FailMode; params args: array of Object);
begin
  locking fDelayStore do
  fDelayStore.AddLast(Tuple.Create(6, aScript, Integer(aFailMode),args ));
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
      6: aTarget.Enter(lItem.Value.Item2, lItem.Value.Item4);
      7: aTarget.Exit(lItem.Value.Item2, FailMode(lItem.Value.Item3), lItem.Value.Item4);
    end;
    lItem := lItem.Next;
  end;
end;

end.
