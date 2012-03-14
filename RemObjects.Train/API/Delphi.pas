namespace RemObjects.Train.API;

interface

uses 
  RemObjects.Train,
  RemObjects.Script.EcmaScript, 
  RemObjects.Script.EcmaScript.Internal, 
  System.Text,
  System.Xml.Linq,
  System.IO,
  System.Runtime.InteropServices;

type
  [PluginRegistration]
  DelphiPlugin = public class(IPluginRegistration)
  private
  public
    method &Register(aServices: IApiRegistrationServices);

    [WrapAs('delphi.build', SkipDryRun := false)]
    class method DelphiBuild(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: DelphiOptions);
  end;
  DelphiOptions = public class
  private
  public
    property dcc: String; // overrides any version
    property version: String;
    property platform: String;
    property aliases: String;
    property conditionalDefines: array of String;
    property destinationFolder: String;
    property dcuDestinationFolder: String;
    property includeSearchPath: String;
    property unitSearchPath:String;
    property otherParameters: String;
  end;  // Delphi_Path


implementation

method DelphiPlugin.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterObjectValue('delphi')
    .AddValue('build', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(DelphiPlugin), 'DelphiBuild'))
;
end;



class method DelphiPlugin.DelphiBuild(aServices: IApiRegistrationServices;ec: ExecutionContext; aProject: String; aOptions: DelphiOptions);
begin
  var lRootPath: String;
  aProject := aServices.ResolveWithBase(ec, aProject);
  aServices.Logger.LogMessage('Building: '+aProject);
  var lVer := aOptions.version.Trim();
  if lVer.StartsWith('d') or lVer.StartsWith('D') then lVer := lVer.Substring(1);
  if not String.IsNullOrEmpty(aOptions.dcc) then
    lRootPath:= aOptions.dcc
  else begin
    case lVer of
      '6': lRootPath := Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\Delphi\6.0', 'RootDir', '') as String;
      '7': lRootPath := Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\Delphi\7.0', 'RootDir', '') as String;
      '8': lRootPath := Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\BDS\2.0', 'RootDir', '') as String;
      '2005', '9': lRootPath := Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\BDS\3.0', 'RootDir', '') as String;
      '2006, 10': lRootPath := Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\BDS\4.0', 'RootDir', '') as String;
      '2007, 11': lRootPath := Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\BDS\5.0', 'RootDir', '') as String;
      '2009, 13': lRootPath := Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\BDS\6.0', 'RootDir', '') as String;
      '2010, 14': lRootPath := Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\BDS\7.0', 'RootDir', '') as String;
      'XE', '2011', '15': lRootPath := Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\BDS\8.0', 'RootDir', '') as String;
      'XE2', '2012', '16': lRootPath := Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\BDS\9.0', 'RootDir', '') as String;
    else
      raise new Exception('Supported version 6,7,8,9,10,11,13,14,15,16 (2005,2006,2007,2008,2009,2010, 2011, XE, 2012, XE2)');
    end;
    if aOptions:platform = 'osx' then
    lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dccosx.exe') else
    if aOptions:platform = '64' then
    lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dcc64.exe') else
    if String.IsNullOrEmpty(aOptions:platform) or (aOptions:platform = '32') then 
    lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dcc32.exe');
  end;
  if not File.Exists(lRootPath) then raise new Exception('Delphi dcc32 not found: '+lRootPath);
  if aServices.Engine.DryRun then exit;
  var sb := new StringBuilder;
  sb.AppendFormat('"{0}"', aProject);

  if aOptions <> nil then begin
    if not String.IsNullOrEmpty(aOptions.aliases) then
      sb.AppendFormat(' "-A{0}"', aOptions.aliases);

    for each el in aOptions.conditionalDefines do
      sb.AppendFormat(' "-D{0}"', el);

    if not String.IsNullOrEmpty(aOptions.dcuDestinationFolder) then 
      sb.AppendFormat(' "-NO{0}" "-N0{0}"', aServices.ResolveWithBase(ec,aOptions.destinationFolder));

    if not String.IsNullOrEmpty(aOptions.destinationFolder) then 
      sb.AppendFormat(' "-LE{0}" "-LN{0}" "-E{0}"', aServices.ResolveWithBase(ec,aOptions.destinationFolder));

    if not String.IsNullOrEmpty(aOptions.includeSearchPath) then
      sb.AppendFormat(' "-I{0}"', aOptions.includeSearchPath);

    if not String.IsNullOrEmpty(aOptions.unitSearchPath) then
      sb.AppendFormat(' "-U{0}"', aOptions.unitSearchPath);


    sb.Append(aOptions.otherParameters);

  
  end;
  var lTmp := new DelayedLogger();
  var lOutput := new StringBuilder;
  aServices.Logger.LogMessage('Running: {0} {1}', lRootPath, sb.ToString);
  var n := Shell.ExecuteProcess(lRootPath, sb.ToString, nil,false ,
  a-> begin
    if not String.IsNullOrEmpty(a) then begin
      lTmp.LogError(a);
      locking lOutput do lOutput.AppendLine(a);
    end;
   end ,a-> begin
    if not String.IsNullOrEmpty(a) then begin
      if a.StartsWith('[DCC Error]') or a.StartsWith('[DCC Fatal Error]') or a.Contains(' Error:') or a.Contains(' Fatal: ') then
        lTmp.LogError(a);
      locking lOutput do lOutput.AppendLine(a);
    end;
   end, nil, nil);

  if n <> 0 then
    lTmp.LogMessage(lOutput.ToString)
  else
    lTmp.LogInfo(lOutput.ToString);

  lTmp.Replay(aServices.Logger);

  if n <> 0 then raise new Exception('Delphi failed');
end;
end.
