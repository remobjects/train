namespace RemObjects.Train;

interface

uses
  System.Collections.Generic,
  System.IO,
  System.Linq,
  System.Reflection,
  System.Security.Cryptography.X509Certificates,
  System.Text,
  System.Xml,
  System.Xml.Linq,
  System.Xml.XPath,
  System.Xml.Xsl,
  RemObjects.Script.EcmaScript,
  RemObjects.Train.API,
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
    method LogLive(s: String);
    method Enter(aImportant: Boolean := false; aScript: String; params args: array of Object);
    method &Exit(aImportant: Boolean := false; aScript: String; aFailMode: FailMode; aResult: Object := nil);
    method &Write;
    property InIgnore: Boolean read write;
  end;  

  MultiLogger = public class(ILogger, IDisposable)
  private
    method set_InIgnore(value: Boolean); locked;
    method get_InIgnore: Boolean; locked;
  public
    constructor;
    property Loggers: List<ILogger> := new List<ILogger>; readonly;
    method Dispose;
    method &Write; locked;
    method LogError(s: String); locked;
    method LogMessage(s: String);locked;
    method LogWarning(s: String);locked;
    method LogHint(s: String);locked;
    method LogDebug(s: String);locked;
    method LogInfo(s: String); locked;
    method LogLive(s: String); locked;
    method Enter(aImportant: Boolean := false; aScript: String; params args: array of Object);locked;
    method &Exit(aImportant: Boolean := false; aScript: String; aFailMode: FailMode; aResult: Object);locked;
    property InIgnore: Boolean read get_InIgnore    write set_InIgnore;
  end;

  BaseXmlLogger = public abstract class(ILogger, IDisposable)
  assembly
    method FindFailNodes(var aWork: XElement; aInput: sequence of XElement);
    fXmlData: System.Xml.Linq.XElement;
    class method Filter(s: String): String;
  public
    constructor;
    method Dispose; virtual; 
    method Write; virtual;
    method LogError(s: String); locked;
    property InIgnore: Boolean;
    method LogMessage(s: String);locked;
    method LogWarning(s: String);locked;
    method LogHint(s: String);locked;
    method LogDebug(s: String);locked;
    method LogInfo(s: String); locked;
    method LogLive(s: String); empty;
    method Enter(aImportant: Boolean := false; aScript: String; params args: array of Object);locked;
    method &Exit(aImportant: Boolean := false; aScript: String; aFailMode: FailMode; aResult: Object);locked;
    class method MyToString(s: Object): String;
  end;


  XmlLogger = public class(BaseXmlLogger, IDisposable)
  private
    fXSLT, fTargetXML, fTargetHTML: String;
  public
    constructor(aTargetXML, aTargetHTML, aXSLT: String);
    method &Write; override;
    method Dispose; override;
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

constructor XmlLogger(aTargetXML, aTargetHTML, aXSLT: String);
begin
  fTargetXML := aTargetXML;
  fTargetHTML := aTargetHTML;
  fXSLT := aXSLT;
  if not String.IsNullOrEmpty(aXSLT) then begin
    if not File.Exists(aXSLT) then
      raise new Exception('File not found:' +aXSLT);
  end;
end;

method XmlLogger.Dispose;
begin
  inherited;
  
end;

method XmlLogger.&Write;
begin
  inherited;

  if not String.IsNullOrEmpty(fTargetXML) then 
    fXmlData.Document.Save(fTargetXML);
  if not String.IsNullOrEmpty(fTargetHTML) then begin

    {var myXslTrans := new XslCompiledTransform();
    if not String.IsNullOrEmpty(fXSLT) then
      myXslTrans.Load(fXSLT)
    else begin
      using sr := new XmlTextReader(typeOf(XmlLogger).Assembly.GetManifestResourceStream('RemObjects.Train.Resources.Train2HTML.xslt')) do begin
        myXslTrans.Load(sr);
      end;
    end;
    var lOutput := new XDocument;
    using sw := lOutput.CreateWriter do
      myXslTrans.Transform(fXmlData.Document.CreateReader, sw);
    if lOutput.Declaration = nil then begin
      lOutput.Declaration := new XDeclaration('1.0', 'utf-8', 'yes');
    end;
    lOutput.Save(fTargetHTML);}

    using lReader := fXmlData.CreateReader() do begin
      using lXPathDoc := new XPathDocument(lReader) do begin
        {$HIDE W28}
        // XslTransform may be deprecated, but it works. XslCompiledTransform as used above generates bad HTML.DO NOT UPDATE
        using lTransform := new XslTransform() do begin
          
          if not String.IsNullOrEmpty(fXSLT) then begin
            using lXslt := new XmlTextReader(fXSLT) do
              lTransform.Load(lXslt);
          end
          else begin
            using lXslt := new XmlTextReader(typeOf(XmlLogger).Assembly.GetManifestResourceStream('RemObjects.Train.Resources.Train2HTML.xslt')) do
              lTransform.Load(lXslt);
          end;

          using lWriter := new XmlTextWriter(fTargetHTML, nil) do
            lTransform.Transform(lXPathDoc, nil, lWriter);

        end;
        {$SHOW W28}
      end;
    end;

  end;
end;

method BaseXmlLogger.LogError(s: String);
begin
  fXmlData.Add(new XElement(if InIgnore then 'ignoredError' else 'error', Filter(s)));
end;

method BaseXmlLogger.LogMessage(s: String);
begin
  if LoggerSettings. ShowMessage then
    fXmlData.Add(new XElement('message', Filter(s)));
end;

method BaseXmlLogger.LogWarning(s: String);
begin
  if LoggerSettings. ShowWarning then
    fXmlData.Add(new XElement('warning', Filter(s)));
end;

method BaseXmlLogger.LogHint(s: String);
begin
  if LoggerSettings. ShowHint then
    fXmlData.Add(new XElement('hint', Filter(s)));
end;

method BaseXmlLogger.LogDebug(s: String);
begin
  if LoggerSettings. ShowDebug then
    fXmlData.Add(new XElement('debug', Filter(s)));
end;

method BaseXmlLogger.Enter(aImportant: Boolean := false; aScript: String; params args: array of Object);
begin
  if not aImportant and not LoggerSettings.ShowDebug then exit;
  var lArgsString := if args = nil then '' else String.Join(', ', args.Select(a-> if a is EcmaScriptObject then EcmaScriptObject(a).Root.JSONStringify(EcmaScriptObject(a).Root.ExecutionContext, nil, a):ToString else if assigned(a) then a.ToString() else 'null').ToArray);
  var lNode := new XElement('action', new XAttribute('name', Filter(aScript)), new XAttribute('args', Filter(lArgsString)));
  self.fXmlData.Add(lNode);
  fXmlData := lNode;
end;

method BaseXmlLogger.&Exit(aImportant: Boolean := false; aScript: String; aFailMode: FailMode; aResult: Object);
begin
  if not aImportant and not LoggerSettings.ShowDebug then exit;
  if aFailMode <> FailMode.Unknown then
  fXmlData.Add(new XAttribute('result', case aFailMode of
    FailMode.No: '1';
    FailMode.Recovered: '2';
  else '0';
  end));
  if (aResult <> nil) and (aResult <> Undefined.Instance) then
    fXmlData.Add(new XElement('return', Filter(MyToString(aResult))));
  fXmlData := fXmlData.Parent;
end;

method BaseXmlLogger.FindFailNodes(var aWork: XElement; aInput: sequence of  XElement);
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

method BaseXmlLogger.LogInfo(s: String);
begin
  LogMessage(s);
end;

class method BaseXmlLogger.Filter(s: String): String;
begin
  if s = nil then exit '';
  if s.IndexOfAny([#0,#1, #2,#3,#4,#5,#6,#7,#8,#11,#12,#14,#15,#16,#17,#18,#19,#20,#21,#22,#23,#34,#25,#26,#27,#28,#29,#30,#31]) < 0 then exit s;
  var sb := new StringBuilder;
  for i: Integer := 0 to length(s) -1 do begin
    if s[i] not in [#0 .. #8, #11, #12, #14..#31] then
      sb.Append(s[i]);
  end;

  exit sb.ToString;
end;

constructor BaseXmlLogger;
begin
  var lDoc := new XDocument();
  fXmlData := new XElement('log');
  lDoc.Add(fXmlData);
end;

method BaseXmlLogger.Dispose;
begin
end;

class method BaseXmlLogger.MyToString(s: Object): String;
begin
  if s = nil then exit '';
  if s is array of Object then 
    exit String.Join(', ', array of Object(s).Select(a->MyToString(a)).ToArray);
  if s is EcmaScriptObject then  
    exit coalesce(EcmaScriptObject(s).Root.JSONStringify(EcmaScriptObject(s).Root.ExecutionContext, nil, s):ToString, '');
  exit s.ToString;
end;

method BaseXmlLogger.&Write;
begin
  var lFailElement: XElement := nil;
  FindFailNodes(var lFailElement, fXmlData.Document.Root.Elements);
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

method MultiLogger.LogLive(s: String);
begin
  Loggers.ForEach(a -> a.LogLive(s) );
end;

method MultiLogger.Enter(aImportant: Boolean := false; aScript: String; params args: array of Object);
begin
  Loggers.ForEach(a->a.Enter(aImportant, aScript, args));
end;

method MultiLogger.&Exit(aImportant: Boolean := false; aScript: String; aFailMode: FailMode; aResult: Object);
begin
  Loggers.ForEach(a->a.Exit(aImportant,aScript , aFailMode, aResult));
end;

method MultiLogger.Dispose;
begin
  Loggers.ForEach(a->IDisposable(a):Dispose);
end;

method MultiLogger.LogInfo(s: String);
begin
  Loggers.ForEach(a->a.LogInfo(s));
end;

method MultiLogger.&Write;
begin
  Loggers.ForEach(a->a.Write);
end;

method MultiLogger.get_InIgnore: Boolean;
begin
  if Loggers.Count = 0 then exit false;
  exit Loggers[0].InIgnore;
end;

method MultiLogger.set_InIgnore(value: Boolean);
begin
  for each el in Loggers do
    el.InIgnore := value;
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
