namespace RemObjects.Builder;

interface

uses
  RemObjects.Builder.API,
  System.Xml.Linq,
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

  FailMode = public (No, Yes, Recovered);
  ILogger = public interface
    method LogError(s: string);
    method LogMessage(s: string);
    method LogWarning(s: string);
    method LogHint(s: string);
    method LogDebug(s: string);
    method Enter(aScript: string; params args: array of Object);
    method &Exit(aScript: string; aFailMode: FailMode; params args: array of Object);
  end;  

  MultiLogger = public class(ILogger, IDisposable)
  private
  public
    constructor;
    property Loggers: List<ILogger> := new List<ILogger>; readonly;
    method Dispose;
    method LogError(s: string); locked;
    method LogMessage(s: string);locked;
    method LogWarning(s: string);locked;
    method LogHint(s: string);locked;
    method LogDebug(s: string);locked;
    method Enter(aScript: string; params args: array of Object);locked;
    method &Exit(aScript: string; aFailMode: FailMode; params args: array of Object);locked;
  end;

  XmlLogger = public class(ILogger, IDisposable)
  private
    fTarget: System.IO.Stream;
    fXmlData: System.Xml.Linq.XElement;
  public
    constructor(aTarget: System.IO.Stream);
    method Dispose;
    method LogError(s: string); locked;
    method LogMessage(s: string);locked;
    method LogWarning(s: string);locked;
    method LogHint(s: string);locked;
    method LogDebug(s: string);locked;
    method Enter(aScript: string; params args: array of Object);locked;
    method &Exit(aScript: string; aFailMode: FailMode; params args: array of Object);locked;
  end;

  LoggerSettings = public static class
  private
  public
    class property ShowDebug: Boolean := false;
    class property ShowWarning: Boolean := true;
    class property ShowMessage: Boolean := true;
    class property ShowHint: Boolean := true;
  end;

extension method ILogger.LogError(s: string; params args: array of Object);
extension method ILogger.LogMessage(s: string; params args: array of Object);
extension method ILogger.LogWarning(s: string; params args: array of Object);
extension method ILogger.LogHint(s: string; params args: array of Object);
extension method ILogger.LogDebug(s: string; params args: array of Object);

implementation

constructor XmlLogger(aTarget: System.IO.Stream);
begin
  fTarget := aTarget;
  var lDoc := new XDocument();
  fXmlData := new XElement('log');
  lDoc.Add(fXmlData);
end;

method XmlLogger.Dispose;
begin
  fXmlData.Document.Save(fTarget);
  fTarget:Dispose;
end;

method XmlLogger.LogError(s: string);
begin
  fXmlData.Add(new XElement('error', s));
end;

method XmlLogger.LogMessage(s: string);
begin
  if LoggerSettings. ShowMessage then
    fXmlData.Add(new XElement('message', s));
end;

method XmlLogger.LogWarning(s: string);
begin
  if LoggerSettings. ShowWarning then
    fXmlData.Add(new XElement('warning', s));
end;

method XmlLogger.LogHint(s: string);
begin
  if LoggerSettings. ShowHint then
    fXmlData.Add(new XElement('hint', s));
end;

method XmlLogger.LogDebug(s: string);
begin
  if LoggerSettings. ShowDebug then
    fXmlData.Add(new XElement('debug', s));
end;

method XmlLogger.Enter(aScript: string; params args: array of Object);
begin
  var lArgsString := if args = nil then '' else String.Join(', ', args.Select(a->a.ToString()).ToArray);
  var lNode := new XElement('action', new XAttribute('name', aScript), new Xattribute('args', lArgsString));
  self.fXmlData.Add(lNode);
  fXmlData := lNode;
end;

method XmlLogger.&Exit(aScript: string; aFailMode: FailMode; params args: array of Object);
begin
  fXmlData.Add(new XAttribute('result', case aFailMode of
    FailMode.No: '1';
    FailMode.Recovered: '2';
  else '0';
  end));
  fXmlData := fXmlData.Parent;
end;

constructor MultiLogger;
begin

end;

method MultiLogger.LogError(s: string);
begin
  Loggers.ForEach(a->a.LogError(s));
end;

method MultiLogger.LogMessage(s: string);
begin
  Loggers.ForEach(a->a.LogMessage(s));
end;

method MultiLogger.LogWarning(s: string);
begin
  Loggers.ForEach(a->a.LogWarning(s));
end;

method MultiLogger.LogHint(s: string);
begin
  Loggers.ForEach(a->a.LogHint(s));
end;

method MultiLogger.LogDebug(s: string);
begin
  Loggers.ForEach(a->a.LogDebug(s));
end;

method MultiLogger.Enter(aScript: string; params args: array of Object);
begin
  Loggers.ForEach(a->a.Enter(aScript, args));
end;

method MultiLogger.&Exit(aScript: string; aFailMode: FailMode; params args: array of Object);
begin
  Loggers.ForEach(a->a.Exit(aScript, aFailMode,args ));
end;

method MultiLogger.Dispose;
begin
  Loggers.ForEach(a->IDisposable(a):Dispose);
end;

method LoggingRegistration.&Register(aServices: IApiRegistrationServices);
begin
  var lLogger := aServices.Engine;
  aServices.RegisterValue('log', Utilities.SimpleFunction(aServices.Engine, a-> lLogger.Logger.LogMessage(a:FirstOrDefault:ToString, a:&Skip(1):ToArray))
    .AddValue('error', Utilities.SimpleFunction(aServices.Engine, a-> lLogger.Logger.LogError(a:FirstOrDefault:ToString, a:&Skip(1):ToArray)))
    .AddValue('message', Utilities.SimpleFunction(aServices.Engine, a-> lLogger.Logger.LogMessage(a:FirstOrDefault:ToString, a:&Skip(1):ToArray)))
    .AddValue('warning', Utilities.SimpleFunction(aServices.Engine, a-> lLogger.Logger.LogWarning(a:FirstOrDefault:ToString, a:&Skip(1):ToArray)))
    .AddValue('hint', Utilities.SimpleFunction(aServices.Engine, a-> lLogger.Logger.LogHint(a:FirstOrDefault:ToString, a:&Skip(1):ToArray)))
    .AddValue('debug', Utilities.SimpleFunction(aServices.Engine, a-> lLogger.Logger.LogDebug(a:FirstOrDefault:ToString, a:&Skip(1):ToArray)))
  );
  aServices.RegisterValue('error', Utilities.SimpleFunction(aServices.Engine, a-> begin 
    raise new Exception(a:FirstOrDefault:ToString)end ));
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
