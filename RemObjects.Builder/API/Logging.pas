namespace RemObjects.Builder;

interface

uses
  RemObjects.Builder.API,
  System.Linq,
  RemObjects.Script.EcmaScript,
  System.Collections.Generic,
  System.Text;

type
  [PluginRegistration]
  LoggingRegistration = public class(IPluginRegistration)
  private
  protected
  public
    method &Register(aServices: IApiRegistrationServices);
  end;

  ILogger = public interface
    method LogError(s: string);
    method LogMessage(s: string);
    method LogWarning(s: string);
    method LogHint(s: string);
    method LogDebug(s: string);
    method Enter(aScript: string; params args: array of string);
    method &Exit(aScript: string; params args: array of string);
  end;  

extension method ILogger.LogError(s: string; params args: array of Object);
extension method ILogger.LogMessage(s: string; params args: array of Object);
extension method ILogger.LogWarning(s: string; params args: array of Object);
extension method ILogger.LogHint(s: string; params args: array of Object);
extension method ILogger.LogDebug(s: string; params args: array of Object);

implementation

method LoggingRegistration.&Register(aServices: IApiRegistrationServices);
begin
  var lLogger := aServices.Engine;
  aServices.RegisterValue('log', new EcmaScriptObject(aServices.Globals)
    .AddValue('error', Utilities.SimpleFunction(aServices.Engine, a-> lLogger.Logger.LogError(a:FirstOrDefault:ToString, a:&Skip(1):ToArray)))
    .AddValue('message', Utilities.SimpleFunction(aServices.Engine, a-> lLogger.Logger.LogMessage(a:FirstOrDefault:ToString, a:&Skip(1):ToArray)))
    .AddValue('warning', Utilities.SimpleFunction(aServices.Engine, a-> lLogger.Logger.LogWarning(a:FirstOrDefault:ToString, a:&Skip(1):ToArray)))
    .AddValue('hint', Utilities.SimpleFunction(aServices.Engine, a-> lLogger.Logger.LogHint(a:FirstOrDefault:ToString, a:&Skip(1):ToArray)))
    .AddValue('debug', Utilities.SimpleFunction(aServices.Engine, a-> lLogger.Logger.LogDebug(a:FirstOrDefault:ToString, a:&Skip(1):ToArray)))
  );
end;

extension method ILogger.LogError(s: string; params args: array of Object);
begin
  self.LogError(String.Format(s, args));
end;

extension method ILogger.LogMessage(s: string; params args: array of Object);
begin
  self.LogMessage(String.Format(s,  args));
end;

extension method ILogger.LogWarning(s: string; params args: array of Object);
begin
  self.LogWarning(String.Format(s,  args));
end;

extension method ILogger.LogHint(s: string; params args: array of Object);
begin
  self.LogHint(String.Format(s,  args));
end;

extension method ILogger.LogDebug(s: string; params args: array of Object);
begin
  self.LogDebug(String.Format(s,  args));
end;

end.
