namespace RemObjects.Train;

interface

uses
  RemObjects.Train.API,
  System.Reflection,
  System.Xml.Linq,
  System.Linq,
  RemObjects.Script.EcmaScript,
  System.Collections.Generic,
  System.Text, 
  DiscUtils.Iscsi;

type
  [PluginRegistration]
  LoggingRegistration = public class(IPluginRegistration)
  private
  protected
  public
    method &Register(aServices: IApiRegistrationServices);

    [WrapAs(nil, SkipDryRun := false)]
    class method Log(aServices: IApiRegistrationServices; ec: ExecutionContext; params aArgs: array of String);
    [WrapAs(nil, SkipDryRun := false)]
    class method LogError(aServices: IApiRegistrationServices; ec: ExecutionContext; params aArgs: array of String);
    [WrapAs(nil, SkipDryRun := false)]
    class method Message(aServices: IApiRegistrationServices; ec: ExecutionContext; params aArgs: array of String);
    [WrapAs(nil, SkipDryRun := false)]
    class method Warning(aServices: IApiRegistrationServices; ec: ExecutionContext; params aArgs: array of String);
    [WrapAs(nil, SkipDryRun := false)]
    class method Hint(aServices: IApiRegistrationServices; ec: ExecutionContext; params aArgs: array of String);
    [WrapAs(nil, SkipDryRun := false)]
    class method Debug(aServices: IApiRegistrationServices; ec: ExecutionContext; params aArgs: array of String);
    [WrapAs(nil, SkipDryRun := false)]
    class method Info(aServices: IApiRegistrationServices; ec: ExecutionContext; params aArgs: array of String);
    [WrapAs(nil, SkipDryRun := false)]
    class method Error(aServices: IApiRegistrationServices; ec: ExecutionContext; params aArgs: array of String);
  end;

  FailMode = public (No, Yes, Recovered, Unknown);
  ILogger = public interface
    method LogError(s: String);
    method LogMessage(s: String);
    method LogWarning(s: String);
    method LogHint(s: String);
    method LogDebug(s: String);
    method LogInfo(s: String);
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
    method LogInfo(s: String); locked;
    method Enter(aImportant: Boolean := false; aScript: String; params args: array of Object);locked;
    method &Exit(aImportant: Boolean := false; aScript: String; aFailMode: FailMode; params args: array of Object);locked;
  end;

  XmlLogger = public class(ILogger, IDisposable)
  private
    method FindFailNodes(var aWork: XElement; aInput: sequence of XElement);
    fTarget: System.IO.Stream;
    fXmlData: System.Xml.Linq.XElement;
    class method Filter(s: String): String;
  public
    constructor(aTarget: System.IO.Stream);
    method Dispose;
    method LogError(s: String); locked;
    method LogMessage(s: String);locked;
    method LogWarning(s: String);locked;
    method LogHint(s: String);locked;
    method LogDebug(s: String);locked;
    method LogInfo(s: String); locked;
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
extension method ILogger.LogError(e: Exception);
extension method ILogger.LogInfo(s: String; params args: array of Object);
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
  fXmlData.Add(new XElement('error', Filter(s)));
end;

method XmlLogger.LogMessage(s: String);
begin
  if LoggerSettings. ShowMessage then
    fXmlData.Add(new XElement('message', Filter(s)));
end;

method XmlLogger.LogWarning(s: String);
begin
  if LoggerSettings. ShowWarning then
    fXmlData.Add(new XElement('warning', Filter(s)));
end;

method XmlLogger.LogHint(s: String);
begin
  if LoggerSettings. ShowHint then
    fXmlData.Add(new XElement('hint', Filter(s)));
end;

method XmlLogger.LogDebug(s: String);
begin
  if LoggerSettings. ShowDebug then
    fXmlData.Add(new XElement('debug', Filter(s)));
end;

method XmlLogger.Enter(aImportant: Boolean := false; aScript: String; params args: array of Object);
begin
  if not aImportant and not LoggerSettings.ShowDebug then exit;
  var lArgsString := if args = nil then '' else String.Join(', ', args.Select(a-> if a is EcmaScriptObject then  EcmaScriptObject(a).Root.JSONStringify(EcmaScriptObject(a).Root.ExecutionContext, nil, a):ToString else  a.ToString()).ToArray);
  var lNode := new XElement('action', new XAttribute('name', Filter(aScript)), new XAttribute('args', Filter(lArgsString)));
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

method XmlLogger.LogInfo(s: String);
begin
  LogMessage(s);
end;

class method XmlLogger.Filter(s: String): String;
begin
  if s.IndexOfAny([#0,#1, #2,#3,#4,#5,#6,#7,#8,#11,#12,#14,#15,#16,#17,#18,#19,#20,#21,#22,#23,#34,#25,#26,#27,#28,#29,#30,#31]) < 0 then exit s;
  var sb := new StringBuilder;
  for i: Integer := 0 to length(s) -1 do begin
    if s[i] not in [#0 .. #8, #11, #12, #14..#31] then
      sb.Append(s[i]);
  end;

  exit sb.ToString;
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

method MultiLogger.LogInfo(s: String);
begin
  Loggers.ForEach(a->a.LogInfo(s));
end;

method LoggingRegistration.&Register(aServices: IApiRegistrationServices);
begin
  var lLog := MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'Log');
  aServices.RegisterValue('log', lLog);
  lLog.AddValue('error', MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'LogError'));
  lLog.AddValue('message', MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'Message'));
  lLog.AddValue('warning', MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'Warning'));
  lLog.AddValue('hint', MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'Hint'));
  lLog.AddValue('debug', MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'Debug'));
  lLog.AddValue('info', MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'Info'));
  aServices.RegisterValue('error', MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'Error'));
end;

class method LoggingRegistration.Log(aServices: IApiRegistrationServices; ec: ExecutionContext; params aArgs: array of String);
begin
  if length(aArgs) = 0 then exit;
  if length(aArgs) = 1 then
    aServices.Logger.LogMessage(aArgs[0])
  else
    aServices.Logger.LogMessage(aArgs[0], aArgs.Skip(1).OfType<Object>().ToArray);
end;

class method LoggingRegistration.LogError(aServices: IApiRegistrationServices; ec: ExecutionContext; params aArgs: array of String);
begin
  if length(aArgs) = 0 then exit;
  if length(aArgs) = 1 then
    aServices.Logger.LogError(aArgs[0])
  else
    aServices.Logger.LogError(aArgs[0], aArgs.Skip(1).OfType<Object>().ToArray);
end;

class method LoggingRegistration.Message(aServices: IApiRegistrationServices; ec: ExecutionContext; params aArgs: array of String);
begin
  if length(aArgs) = 0 then exit;
  if length(aArgs) = 1 then
    aServices.Logger.LogMessage(aArgs[0])
  else
    aServices.Logger.LogMessage(aArgs[0], aArgs.Skip(1).OfType<Object>().ToArray);
end;

class method LoggingRegistration.Warning(aServices: IApiRegistrationServices; ec: ExecutionContext; params aArgs: array of String);
begin
  if length(aArgs) = 0 then exit;
  if length(aArgs) = 1 then
    aServices.Logger.LogWarning(aArgs[0])
  else
    aServices.Logger.LogWarning(aArgs[0], aArgs.Skip(1).OfType<Object>().ToArray);
end;

class method LoggingRegistration.Hint(aServices: IApiRegistrationServices; ec: ExecutionContext; params aArgs: array of String);
begin
  if length(aArgs) = 0 then exit;
  if length(aArgs) = 1 then
    aServices.Logger.LogHint(aArgs[0])
  else
    aServices.Logger.LogHint(aArgs[0], aArgs.Skip(1).OfType<Object>().ToArray);
end;

class method LoggingRegistration.Debug(aServices: IApiRegistrationServices; ec: ExecutionContext; params aArgs: array of String);
begin
  if length(aArgs) = 0 then exit;
  if length(aArgs) = 1 then
    aServices.Logger.LogDebug(aArgs[0])
  else
    aServices.Logger.LogDebug(aArgs[0], aArgs.Skip(1).OfType<Object>().ToArray);
end;

class method LoggingRegistration.Info(aServices: IApiRegistrationServices; ec: ExecutionContext; params aArgs: array of String);
begin
  if length(aArgs) = 0 then exit;
  if length(aArgs) = 1 then
    aServices.Logger.LogInfo(aArgs[0])
  else
    aServices.Logger.LogInfo(aArgs[0], aArgs.Skip(1).OfType<Object>().ToArray);
end;

class method LoggingRegistration.Error(aServices: IApiRegistrationServices; ec: ExecutionContext; params aArgs: array of String);
begin
  if length(aArgs) = 0 then exit;
  if length(aArgs) = 1 then
    raise new Exception(aArgs[0])
  else
    raise new Exception(String.Format(aArgs[0], aArgs.Skip(1).OfType<Object>().ToArray));
end;

extension method ILogger.LogError(s: String; params args: array of Object);
begin
  self.LogError(MUtilities.MyFormat(s, args));
end;


extension method ILogger.LogError(e: Exception);
begin
  if e = nil then exit;
  if e is TargetInvocationException then
    e := TargetInvocationException(e).InnerException;
  if e is AbortException then exit; // ignore, already logged
  var lAgg := AggregateException(e);
  if lAgg <> nil then begin
    for each el in lAgg.InnerExceptions do
    self.LogError(el);
  end else begin
    if (e is NullReferenceException) or (e is ArgumentException) then
      LogError(e.ToString)
    else
      LogError(e.Message);
  end;
end;

extension method ILogger.LogMessage(s: String; params args: array of Object);
begin
  self.LogMessage(MUtilities.MyFormat(s,  args));
end;

extension method ILogger.LogWarning(s: String; params args: array of Object);
begin
  self.LogWarning(MUtilities.MyFormat(s,  args));
end;

extension method ILogger.LogHint(s: String; params args: array of Object);
begin
  self.LogHint(MUtilities.MyFormat(s,  args));
end;

extension method ILogger.LogDebug(s: String; params args: array of Object);
begin
  self.LogDebug(MUtilities.MyFormat(s,  args));
end;

extension method ILogger.LogInfo(s: String; params args: array of Object);
begin
  self.LogInfo(MUtilities.MyFormat(s,  args));
end;

end.
