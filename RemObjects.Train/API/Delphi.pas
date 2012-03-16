namespace RemObjects.Train.API;

interface

uses 
  RemObjects.Train,
  RemObjects.Script.EcmaScript, 
  RemObjects.Script.EcmaScript.Internal, 
  System.Text,
  System.Text.RegularExpressions,
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
    class method RebuildMultiPath(aServices: IApiRegistrationServices; ec: ExecutionContext;aDelphi, aInput: String): String;
  end;
  DelphiOptions = public class
  private
  public
    property dcc: String; // overrides any version
    property delphi: String;
    property platform: String;
    property aliases: String;
    property conditionalDefines: array of String;
    property destinationFolder: String;
    property dcuDestinationFolder: String;
    property includeSearchPath: String;
    property unitSearchPath:String;
    property namespaces: String;
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
  var lVer := aOptions.delphi:Trim();
  if lVer.StartsWith('d') or lVer.StartsWith('D') then lVer := lVer.Substring(1);
  if not String.IsNullOrEmpty(aOptions.dcc) then
    lRootPath:= aOptions.dcc
  else begin
    case lVer of
      '6': lRootPath := coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\Delphi\6.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Borland\Delphi\6.0', 'RootDir', '') as String);
      '7': lRootPath := coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\Delphi\7.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Borland\Delphi\7.0', 'RootDir', '') as String);
      '8': lRootPath := coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\BDS\2.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Borland\BDS\2.0', 'RootDir', '') as String);
      '2005', '9': lRootPath := coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\BDS\3.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Borland\BDS\3.0', 'RootDir', '') as String);
      '2006', '10': lRootPath := coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\BDS\4.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Borland\BDS\4.0', 'RootDir', '') as String);
      '2007', '11': lRootPath := coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\BDS\5.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Borland\BDS\5.0', 'RootDir', '') as String);
      '2009', '12': lRootPath := coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\CodeGear\BDS\6.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\CodeGear\BDS\6.0', 'RootDir', '') as String);
      '2010', '14': lRootPath := coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\CodeGear\BDS\7.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\CodeGear\BDS\7.0', 'RootDir', '') as String);
      'XE', '2011', '15': lRootPath := coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Embarcadero\BDS\8.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Embarcadero\BDS\8.0', 'RootDir', '') as String);
      'XE2', '2012', '16': lRootPath := coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Embarcadero\BDS\9.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Embarcadero\BDS\9.0', 'RootDir', '') as String);
    else
      raise new Exception('Supported version 6,7,8,9,10,11,13,14,15,16 (2005,2006,2007,2008,2009,2010, 2011, XE, 2012, XE2)');
    end;
    if lRootPath = nil then raise new Exception('Cannot find delphi registry key for version: '+lVer);
    if aOptions:platform = 'osx' then
    lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dccosx.exe') else
    if aOptions:platform = '64' then
    lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dcc64.exe') else
    if String.IsNullOrEmpty(aOptions:platform) or (aOptions:platform = '32') then 
    lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dcc32.exe');
  end;
  if not File.Exists(lRootPath) then raise new Exception('Delphi dcc32 not found: '+lRootPath);
  if aServices.Engine.DryRun then exit;
  var lDelphi := Path.GetDirectoryName(Path.GetDirectoryName(lRootPath));
  var sb := new StringBuilder;
  sb.AppendFormat('"{0}" -Q -B', aProject);

  var lPath := Path.GetDirectoryName(aProject);

  if String.IsNullOrWhiteSpace(aOptions.unitSearchPath) then
    aOptions.unitSearchPath := Path.GetDirectoryName(aProject)
  else
    aOptions.unitSearchPath := aOptions.unitSearchPath +';'+Path.GetDirectoryName(aProject);

  if aOptions = nil then aOptions := new DelphiOptions;
  if not String.IsNullOrEmpty(aOptions.aliases) then
    sb.AppendFormat(' -A"{0}"', aOptions.aliases);

  for each el in aOptions.conditionalDefines do
    sb.AppendFormat(' -D"{0}"', el);

  if not String.IsNullOrEmpty(aOptions.namespaces) then
    sb.AppendFormat(' -NS"{0}"', aOptions.namespaces);

  if not String.IsNullOrEmpty(aOptions.dcuDestinationFolder) then 
    sb.AppendFormat(' -NO"{0}" -N0"{0}"', aServices.ResolveWithBase(ec,aOptions.destinationFolder));

  if not String.IsNullOrEmpty(aOptions.destinationFolder) then 
    sb.AppendFormat(' -LE"{0}" -LN"{0}" -E"{0}"', aServices.ResolveWithBase(ec,aOptions.destinationFolder));

  if not String.IsNullOrEmpty(aOptions.includeSearchPath) then
    sb.AppendFormat(' -I"{0}"', RebuildMultiPath(aServices,ec,lDelphi,aOptions.includeSearchPath));

  if not String.IsNullOrEmpty(aOptions.unitSearchPath) then
    sb.AppendFormat(' -U"{0}"', RebuildMultiPath(aServices,ec,lDelphi,aOptions.unitSearchPath));


  sb.Append(aOptions.otherParameters);

  
  var lTmp := new DelayedLogger();
  var lOutput := new StringBuilder;
  aServices.Logger.LogMessage('Running: {0} {1}', lRootPath, sb.ToString);
  var n := Shell.ExecuteProcess(lRootPath, sb.ToString, lPath,false ,
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

class method DelphiPlugin.RebuildMultiPath(aServices: IApiRegistrationServices; ec: ExecutionContext; aDelphi, aInput: String): String;
begin
  var lItems := aInput.Split([';'], StringSplitOptions.RemoveEmptyEntries);
  for i: Integer := 0 to lItems.Length -1 do begin
    lItems[i] := aServices.ResolveWithBase(ec, lItems[i]);
    lItems[i] := Regex.Replace(lItems[i], '\$\(DELPHI\)', aDelphi, RegexOptions.IgnoreCase);
  end;
  exit String.Join(';', lItems);
end;
end.
