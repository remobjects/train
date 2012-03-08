namespace RemObjects.Builder;

interface

uses
  System.Collections.Generic,
  System.Text;

type
  DelayedLogger = public class(ILogger)
  private
    fDelayStore: LinkedList<Tuple<Integer, String, array of Object>> := new LinkedList<Tuple<Integer, String, array of Object>>;
  protected
  public
    method LogError(s: string);
    method LogMessage(s: string);
    method LogWarning(s: string);
    method LogHint(s: string);
    method LogDebug(s: string);
    method Enter(aScript: string; params args: array of Object);
    method &Exit(aScript: string; params args: array of Object);

    method Replay(aTarget: ILogger);
  end;

implementation

method DelayedLogger.LogError(s: string);
begin
  locking fDelayStore do
  fDelayStore.AddLast(Tuple.Create(0, s, array of Object(nil)));
end;

method DelayedLogger.LogMessage(s: string);
begin
  locking fDelayStore do
  fDelayStore.AddLast(Tuple.Create(1, s, array of Object(nil)));
end;

method DelayedLogger.LogWarning(s: string);
begin
  locking fDelayStore do
  fDelayStore.AddLast(Tuple.Create(2, s, array of Object(nil)));
end;

method DelayedLogger.LogHint(s: string);
begin
  locking fDelayStore do
  fDelayStore.AddLast(Tuple.Create(3, s, array of Object(nil)));
end;

method DelayedLogger.LogDebug(s: string);
begin
  locking fDelayStore do
  fDelayStore.AddLast(Tuple.Create(4, s, array of Object(nil)));
end;

method DelayedLogger.Enter(aScript: string; params args: array of Object);
begin
  locking fDelayStore do
  fDelayStore.AddLast(Tuple.Create(5, aScript, args));
end;

method DelayedLogger.&Exit(aScript: string; params args: array of Object);
begin
  locking fDelayStore do
  fDelayStore.AddLast(Tuple.Create(6, aScript, args));
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
      6: aTarget.Enter(lItem.Value.Item2, lItem.Value.Item3);
      7: aTarget.Exit(lItem.Value.Item2, lItem.Value.Item3);
    end;
    lItem := lItem.Next;
  end;
end;

end.
