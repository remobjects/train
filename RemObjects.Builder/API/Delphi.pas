namespace RemObjects.Builder.API;

interface

uses 
  RemObjects.Builder,
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
    class method DelphiBuild(aServices: IApiRegistrationServices; aProject: string; aOptions: DelphiOptions);
  end;
  DelphiOptions = public class
  private
  public
    property version: string;
    property platform: string;
    property aliases: string;
    property conditionalDefines: array of string;
    property destinationFolder: string;
    property dcuDestinationFolder: string;
    property includeSearchPath: string;
    property unitSearchPath:string;
    property otherParameters: string;
  end;  // Delphi_Path


implementation

method DelphiPlugin.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterObjectValue('delphi')
    .AddValue('build', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, typeof(DelphiPlugin), 'DelphiBuild'))
;
end;



class method DelphiPlugin.DelphiBuild(aServices: IApiRegistrationServices; aProject: string; aOptions: DelphiOptions);
begin
  var lRootPath: string;
  var lVer := aOptions.version.Trim();
  if lVer.StartsWith('d') or lVer.StartsWith('D') then lVer := lVer.Substring(1);
  case lVer of
    '6': lRootPath := Microsoft.Win32.Registry.GetValue('HKCU\Software\Borland\Delphi\6.0', 'RootDir', '') as string;
    '7': lRootPath := Microsoft.Win32.Registry.GetValue('HKCU\Software\Borland\Delphi\7.0', 'RootDir', '') as string;
    '8': lRootPath := Microsoft.Win32.Registry.GetValue('HKCU\Software\Borland\BDS\2.0', 'RootDir', '') as string;
    '2005', '9': lRootPath := Microsoft.Win32.Registry.GetValue('HKCU\Software\Borland\BDS\3.0', 'RootDir', '') as string;
    '2006, 10': lRootPath := Microsoft.Win32.Registry.GetValue('HKCU\Software\Borland\BDS\4.0', 'RootDir', '') as string;
    '2007, 11': lRootPath := Microsoft.Win32.Registry.GetValue('HKCU\Software\Borland\BDS\5.0', 'RootDir', '') as string;
    '2009, 13': lRootPath := Microsoft.Win32.Registry.GetValue('HKCU\Software\Borland\BDS\6.0', 'RootDir', '') as string;
    '2010, 14': lRootPath := Microsoft.Win32.Registry.GetValue('HKCU\Software\Borland\BDS\7.0', 'RootDir', '') as string;
    'XE', '2011', '15': lRootPath := Microsoft.Win32.Registry.GetValue('HKCU\Software\Borland\BDS\8.0', 'RootDir', '') as string;
    'XE2', '2012', '16': lRootPath := Microsoft.Win32.Registry.GetValue('HKCU\Software\Borland\BDS\9.0', 'RootDir', '') as string;
  else
    raise new Exception('Supported version 6,7,8,9,10,11,13,14,15,16 (2005,2006,2007,2008,2009,2010, 2011, XE, 2012, XE2)');
  end;
  if aOptions:platform = 'osx' then
  lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dccosx.exe') else
  if aOptions:platform = '64' then
  lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dcc64.exe') else
  if string.IsNullOrEmpty(aOptions:platform) or (aOptions:platform = '32') then 
  lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dcc32.exe');
  if not File.Exists(lRootPath) then raise new Exception('Delphi dcc32 not found: '+lRootPath);
  if aServices.Engine.DryRun then exit;
  var sb := new StringBuilder;
  sb.AppendFormat('"{0}"', aProject);

  if aOptions <> nil then begin
    if not string.IsNullOrEmpty(aOptions.aliases) then
      sb.AppendFormat(' "-A{0}"', aOptions.aliases);

    for each el in aOptions.conditionalDefines do
      sb.AppendFormat(' "-D{0}"', el);

    if not string.IsNullOrEmpty(aOptions.dcuDestinationFolder) then 
      sb.AppendFormat(' "-NO{0}" "-N0{0}"', aOptions.destinationFolder);

    if not string.IsNullOrEmpty(aOptions.destinationFolder) then 
      sb.AppendFormat(' "-LE{0}" "-LN{0}" "-E{0}"', aOptions.destinationFolder);

    if not string.IsNullOrEmpty(aOptions.includeSearchPath) then
      sb.AppendFormat(' "-I{0}"', aOptions.includeSearchPath);

    if not string.IsNullOrEmpty(aOptions.unitSearchPath) then
      sb.AppendFormat(' "-U{0}"', aOptions.unitSearchPath);


    sb.Append(aOptions.otherParameters);

  
  end;
 var lOutput:= new StringBuilder;
  Shell.ExecuteProcess(lRootPath, sb.ToString, nil, false,
  a-> locking loutput do lOutput.Append(a),a-> locking Loutput do lOutput.Append(a), nil, nil);

  aServices.Logger.LogMessage(lOutput.ToSTring);
end;
end.
