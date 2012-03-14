namespace RemObjects.Train;

interface

uses
  RemObjects.Train.API,
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

  FailMode = public (No, Yes, Recovered, Unknown);
  ILogger = public interface
    method LogError(s: String);
    method LogMessage(s: String);
    method LogWarning(s: String);
    method LogHint(s: String);
    method LogDebug(s: String);
    method Enter(aImportant: Boolean := false; aScript: String; params args: array of Object);
    method &Exit(aImportant: Boolean := false; aScript: String; aFailMode: FailMode; params args: array of Object);
  end;  

  MultiLogger = public class(ILogger, IDisposable)
  private
  public
    constructor;
    property Loggers: List<ILogger> := new List<ILogger>; readonly;
    method Dispose;
    method LogError(s: String); locked;
    method LogMessage(s: String);locked;
    method LogWarning(s: String);locked;
    method LogHint(s: String);locked;
    method LogDebug(s: String);locked;
    method Enter(aImportant: Boolean := false; aScript: String; params args: array of Object);locked;
    method &Exit(aImportant: Boolean := false; aScript: String; aFailMode: FailMode; params args: array of Object);locked;
  end;

  XmlLogger = public class(ILogger, IDisposable)
  private
    method FindFailNodes(var aWork: XElement; aInput: sequence of XElement);
    fTarget: System.IO.Stream;
    fXmlData: System.Xml.Linq.XElement;
  public
    constructor(aTarget: System.IO.Stream);
    method Dispose;
    method LogError(s: String); locked;
    method LogMessage(s: String);locked;
    method LogWarning(s: String);locked;
    method LogHint(s: String);locked;
    method LogDebug(s: String);locked;
    method Enter(aImportant: Boolean := false; aScript: String; params args: array of Object);locked;
    method &Exit(aImportant: Boolean := false; aScript: String; aFailMode: FailMode; params args: array of Object);locked;
  end;

  LoggerSettings = public static class
  private
  public
    class property ShowDebug: Boolean := false;
    class property ShowWarning: Boolean := true;
    class property ShowMessage: Boolean := true;
    class property ShowHint: Boolean := true;
  end;

extension method ILogger.LogError(s: String; params args: array of Object);
extension method ILogger.LogMessage(s: String; params args: array of Object);
extension method ILogger.LogWarning(s: String; params args: array of Object);
extension method ILogger.LogHint(s: String; params args: array of Object);
extension method ILogger.LogDebug(s: String; params args: array of Object);

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
  var lFailElement: XElement := nil;
  FindFailNodes(var lFailElement, fXmlData.Document.Root.Elements);
  
  fXmlData.Document.Save(fTarget);
  fTarget:Dispose;
end;

method XmlLogger.LogError(s: String);
begin
  fXmlData.Add(new XElement('error', s));
end;

method XmlLogger.LogMessage(s: String);
begin
  if LoggerSettings. ShowMessage then
    fXmlData.Add(new XElement('message', s));
end;

method XmlLogger.LogWarning(s: String);
begin
  if LoggerSettings. ShowWarning then
    fXmlData.Add(new XElement('warning', s));
end;

method XmlLogger.LogHint(s: String);
begin
  if LoggerSettings. ShowHint then
    fXmlData.Add(new XElement('hint', s));
end;

method XmlLogger.LogDebug(s: String);
begin
  if LoggerSettings. ShowDebug then
    fXmlData.Add(new XElement('debug', s));
end;

method XmlLogger.Enter(aImportant: Boolean := false; aScript: String; params args: array of Object);
begin
  if not aImportant and not LoggerSettings.ShowDebug then exit;
  var lArgsString := if args = nil then '' else String.Join(', ', args.Select(a->a.ToString()).ToArray);
  var lNode := new XElement('action', new XAttribute('name', aScript), new XAttribute('args', lArgsString));
  self.fXmlData.Add(lNode);
  fXmlData := lNode;
end;

method XmlLogger.&Exit(aImportant: Boolean := false; aScript: String; aFailMode: FailMode; params args: array of Object);
begin
  if not aImportant and not LoggerSettings.ShowDebug then exit;
  if aFailMode <> FailMode.Unknown then
  fXmlData.Add(new XAttribute('result', case aFailMode of
    FailMode.No: '1';
    FailMode.Recovered: '2';
  else '0';
  end));
  fXmlData := fXmlData.Parent;
end;

method XmlLogger.FindFailNodes(var aWork: XElement; aInput: sequence of  XElement);
begin
  for each el in aInput do begin
    if (el.Name = 'action') then begin
      var lRes := String(el.Attribute('result'));
      if (lRes = "2") then continue;
      if lRes = '0' then begin
        if aWork = nil then begin
          aWork := new XElement('errors');
          el.Document.Root.AddFirst(aWork);
        end;
        var lNewEL := new XElement(el.Name, el.Attributes().Where(a->not a.IsNamespaceDeclaration));
        
        for each error in el.Elements('error') do begin
          lNewEL.Add(new XElement('error', error.Value));
        end;
        aWork.Add(lNewEL);
      end;
      FindFailNodes(var aWork, el.Elements);
    end;
  end;
end;

constructor MultiLogger;
begin

end;

method MultiLogger.LogError(s: String);
begin
  Loggers.ForEach(a->a.LogError(s));
end;

method MultiLogger.LogMessage(s: String);
begin
  Loggers.ForEach(a->a.LogMessage(s));
end;

method MultiLogger.LogWarning(s: String);
begin
  Loggers.ForEach(a->a.LogWarning(s));
end;

method MultiLogger.LogHint(s: String);
begin
  Loggers.ForEach(a->a.LogHint(s));
end;

method MultiLogger.LogDebug(s: String);
begin
  Loggers.ForEach(a->a.LogDebug(s));
end;

method MultiLogger.Enter(aImportant: Boolean := false; aScript: String; params args: array of Object);
begin
  Loggers.ForEach(a->a.Enter(aImportant, aScript, args));
end;

method MultiLogger.&Exit(aImportant: Boolean := false; aScript: String; aFailMode: FailMode; params args: array of Object);
begin
  Loggers.ForEach(a->a.Exit(aImportant,aScript , aFailMode,args ));
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

extension method ILogger.LogError(s: String; params args: array of Object);
begin
  self.LogError(String.Format(s, args));
end;

extension method ILogger.LogMessage(s: String; params args: array of Object);
begin
  self.LogMessage(String.Format(s,  args));
end;

extension method ILogger.LogWarning(s: String; params args: array of Object);
begin
  self.LogWarning(String.Format(s,  args));
end;

extension method ILogger.LogHint(s: String; params args: array of Object);
begin
  self.LogHint(String.Format(s,  args));
end;

extension method ILogger.LogDebug(s: String; params args: array of Object);
begin
  self.LogDebug(String.Format(s,  args));
end;

end.
