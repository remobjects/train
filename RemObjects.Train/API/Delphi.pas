namespace RemObjects.Train.API;

interface

uses 
  RemObjects.Train,
  RemObjects.Script.EcmaScript, 
  RemObjects.Script.EcmaScript.Internal, 
  System.Collections.Generic,
  System.Text,
  System.Text.RegularExpressions,
  System.Xml.Linq,
  System.IO,
  System.Runtime.InteropServices;

type
  [PluginRegistration]
  DelphiPlugin = public class(IPluginRegistration)
  private const
    DELPHI_6    = 6;
    DELPHI_7    = 7;
    DELPHI_8    = 8;
    DELPHI_2005 = 9;
    DELPHI_2006 = 10;
    DELPHI_2007 = 11;
    DELPHI_2009 = 12;
    DELPHI_2010 = 14;
    DELPHI_XE   = 15;
    DELPHI_XE2  = 16;
    DELPHI_XE3  = 17;
    DELPHI_XE4  = 18;
    DELPHI_XE5  = 19;
    DELPHI_XE6  = 20;
    DELPHI_XE7  = 21;
  private
    class method UpdateResource(aRes: String; aIcon: String; aVersion: VersionInfo;ec: ExecutionContext);
    class method ParseVersion(aVal: String): array of Integer;
    class method DelphiVersion(aVersion: String): Integer;
    class method DelphiVersionName(aVersion: Integer): String;
  public
    method &Register(aServices: IApiRegistrationServices);

    [WrapAs('delphi.getBasePath', skipDryRun := false)]
    class method DelphiGetBaseBath(aVersion: Integer): String;
    [WrapAs('delphi.build', SkipDryRun := false)]
    class method DelphiBuild(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: DelphiOptions);
    class method RebuildMultiPath(aServices: IApiRegistrationServices; ec: ExecutionContext;aDelphi, aInput, aPlatform: String): String;
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

    property updateIcon: String;
    property updateVersionInfo: VersionInfo;
  end;  // Delphi_Path

  VersionInfo = public class
  private
  public
    constructor ();
    property codePage: UInt16;
    property resLang: UInt16;
    property isDll: Boolean;
    property version: String;
    property fileVersion: String;
    property company: String;
    property description: String;
    property legalCopyright: String;
    property legalTrademarks: String;
    property productName: String;
    property title: String;
    property extraFields: EcmaScriptObject;
  end;

implementation

method DelphiPlugin.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterObjectValue('delphi')
    .AddValue('build', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(DelphiPlugin), 'DelphiBuild',nil, false))
    .AddValue('getBasePath', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(DelphiPlugin), 'DelphiGetBaseBath'))
;
end;



class method DelphiPlugin.DelphiBuild(aServices: IApiRegistrationServices;ec: ExecutionContext; aProject: String; aOptions: DelphiOptions);
begin
  var lRootPath: String;
  aProject := aServices.ResolveWithBase(ec, aProject, true);
  aServices.Logger.LogMessage('Building: '+aProject);

  var iVer := DelphiVersion(coalesce(aOptions.delphi:Trim(), ''));
  var sVer := DelphiVersionName(iVer);

  if not String.IsNullOrEmpty(aOptions.dcc) then
    lRootPath:= aOptions.dcc
  else begin
    lRootPath := DelphiGetBaseBath(iVer);
    if lRootPath = nil then raise new Exception('Cannot find Delphi registry key for Delphi '+sVer);
    
    if aOptions:platform:ToLower in ['ios32', 'iossimulator'] then
      lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dccios32.exe') 
    else if aOptions:platform:ToLower in ['iosarm', 'iosdevice'] then
      lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dcciosarm.exe') 
    else if aOptions:platform:ToLower in ['macosx', 'osx', 'osx32'] then
      lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dccosx.exe') 
    else if aOptions:platform:ToLower in ['64', 'x64', 'win64'] then
      lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dcc64.exe') 
    else if String.IsNullOrEmpty(aOptions:platform) or (aOptions:platform:ToLower in ['32', 'x86', 'win32']) then 
      lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dcc32.exe')
    else
      raise new Exception('Unsupported platform ("win32", "win64", "osx32", "iossimulator","iosdevice")');
  end;
  if not File.Exists(lRootPath) then raise new Exception('Delphi dcc not found: '+lRootPath+' '+aOptions:platform);
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
    if iVer > DELPHI_7 then
      sb.AppendFormat(' -NO"{0}" -N0"{0}"', aServices.ResolveWithBase(ec,aOptions.dcuDestinationFolder,true))
    else
      sb.AppendFormat(' -N"{0}"', aServices.ResolveWithBase(ec,aOptions.dcuDestinationFolder, true));

  if not String.IsNullOrEmpty(aOptions.destinationFolder) then
    sb.AppendFormat(' -LE"{0}" -LN"{0}" -E"{0}"', aServices.ResolveWithBase(ec,aOptions.destinationFolder,True));

  if not String.IsNullOrEmpty(aOptions.includeSearchPath) then
    sb.AppendFormat(' -I"{0}"', RebuildMultiPath(aServices,ec,lDelphi,aOptions.includeSearchPath,aOptions:platform));

  if not String.IsNullOrEmpty(aOptions.unitSearchPath) then
    sb.AppendFormat(' -U"{0}"', RebuildMultiPath(aServices,ec,lDelphi,aOptions.unitSearchPath,aOptions:platform));

  if not String.IsNullOrEmpty(aOptions.otherParameters) then
    sb.Append(' '+aOptions.otherParameters);

  if not String.IsNullOrEmpty(aOptions.updateIcon) or (aOptions.updateVersionInfo <> nil) then begin
    var lRes := Path.ChangeExtension(aProject, '.res');
    UpdateResource(lRes, aServices.ResolveWithBase(ec, aOptions.updateIcon, true), aOptions.updateVersionInfo, ec);
  end;

  
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

class method DelphiPlugin.RebuildMultiPath(aServices: IApiRegistrationServices; ec: ExecutionContext; aDelphi, aInput, aPlatform: String): String;
begin
  var lItems := aInput.Split([';'], StringSplitOptions.RemoveEmptyEntries);
  for i: Integer := 0 to lItems.Length -1 do begin
    if not String.IsNullOrEmpty(aPlatform) then lItems[i] := Regex.Replace(lItems[i], '\$\(Platform\)', aPlatform, RegexOptions.IgnoreCase);
    lItems[i] := Regex.Replace(lItems[i], '\$\(BDSLIB\)', '$(BDS)\Lib', RegexOptions.IgnoreCase);
    lItems[i] := Regex.Replace(lItems[i], '\$\(BDS\)', aDelphi, RegexOptions.IgnoreCase);
    lItems[i] := Regex.Replace(lItems[i], '\$\(DELPHI\)', aDelphi, RegexOptions.IgnoreCase);
    lItems[i] := aServices.ResolveWithBase(ec, lItems[i], true);
  end;
  exit String.Join(';', lItems);
end;

class method DelphiPlugin.UpdateResource(aRes: String; aIcon: String; aVersion: VersionInfo;ec: ExecutionContext);
begin
  var lRes := iif(File.Exists(aRes), UnmanagedResourceFile.FromFile(aRes), new UnmanagedResourceFile());

  if not String.IsNullOrEmpty(aIcon) then
    lRes.ReplaceIcons(File.ReadAllBytes(aIcon));

  if aVersion <> nil then begin
    var pev := new Win32VersionInfoResource();
    pev.CodePage := aVersion.codePage;
    pev.ResLang := aVersion.resLang;
    pev.IsDll := aVersion.isDll;
    var lVer := ParseVersion(coalesce(aVersion.version, ''));
    var lFileVer := ParseVersion(coalesce(aVersion.fileVersion,aVersion.version, ''));
    pev.FileVerMaj := lFileVer[0];
    pev.FileVerMin := lFileVer[1];
    pev.FileVerRelease := lFileVer[2];
    pev.FileVerBuild := lFileVer[3];
    pev.ProductVerMaj := lVer[0];
    pev.ProductVerMin := lVer[1];
    pev.ProductVerRelease := lVer[2];
    pev.ProductVerBuild := lVer[3];
    pev.Values.Add(new KeyValuePair<String,String>('ProductVersion', String.Format(System.Globalization.CultureInfo.InvariantCulture, '{0}.{1}.{2}.{3}', pev.ProductVerMaj, pev.ProductVerMin, pev.ProductVerRelease,pev.ProductVerBuild)));
    pev.Values.Add(new KeyValuePair<String,String>('FileVersion', String.Format(System.Globalization.CultureInfo.InvariantCulture, '{0}.{1}.{2}.{3}', pev.FileVerMaj, pev.FileVerMin, pev.FileVerRelease, pev.FileVerBuild)));

    if not String.IsNullOrEmpty(aVersion.company) then    pev.Values.Add(new KeyValuePair<String,String>('CompanyName', aVersion.company));
    if not String.IsNullOrEmpty(aVersion.description) then    pev.Values.Add(new KeyValuePair<String,String>('FileDescription', aVersion.description));
    if not String.IsNullOrEmpty(aVersion.legalCopyright) then    pev.Values.Add(new KeyValuePair<String,String>('LegalCopyright', aVersion.legalCopyright));
    if not String.IsNullOrEmpty(aVersion.legalTrademarks) then    pev.Values.Add(new KeyValuePair<String,String>('LegalTrademarks', aVersion.legalTrademarks));
    if not String.IsNullOrEmpty(aVersion.productName) then    pev.Values.Add(new KeyValuePair<String,String>('ProductName', aVersion.productName));
    if not String.IsNullOrEmpty(aVersion.title) then    pev.Values.Add(new KeyValuePair<String,String>('Title', aVersion.title));
    if assigned(aVersion.extraFields) then       
      for each el in aVersion.extraFields.Values do 
        pev.Values.Add(new KeyValuePair<String,String>(el.Key, Utilities.GetObjAsString(el.Value.Value, ec)));
    lRes.AddVersionInfo(true, 0, pev);
  end;

  lRes.Save(aRes);
end;

class method DelphiPlugin.ParseVersion(aVal: String): array of Integer;
begin
  try
    var lVer := Version.Parse(aVal);
    exit [lVer.Major, lVer.Minor, lVer.Build, lVer.Revision];
  except
      exit [0,0,0,0];
  end;
end;

class method DelphiPlugin.DelphiGetBaseBath(aVersion: Integer): String;
begin
  case aVersion of
    DELPHI_6    : exit  coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\Delphi\6.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Borland\Delphi\6.0', 'RootDir', '') as String);
    DELPHI_7    : exit  coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\Delphi\7.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Borland\Delphi\7.0', 'RootDir', '') as String);
    DELPHI_8    : exit  coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\BDS\2.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Borland\BDS\2.0', 'RootDir', '') as String);
    DELPHI_2005 : exit  coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\BDS\3.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Borland\BDS\3.0', 'RootDir', '') as String);
    DELPHI_2006 : exit  coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\BDS\4.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Borland\BDS\4.0', 'RootDir', '') as String);
    DELPHI_2007 : exit  coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Borland\BDS\5.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Borland\BDS\5.0', 'RootDir', '') as String);
    DELPHI_2009 : exit  coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\CodeGear\BDS\6.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\CodeGear\BDS\6.0', 'RootDir', '') as String);
    DELPHI_2010 : exit  coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\CodeGear\BDS\7.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\CodeGear\BDS\7.0', 'RootDir', '') as String);
    DELPHI_XE   : exit  coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Embarcadero\BDS\8.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Embarcadero\BDS\8.0', 'RootDir', '') as String);
    DELPHI_XE2  : exit  coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Embarcadero\BDS\9.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Embarcadero\BDS\9.0', 'RootDir', '') as String);
    DELPHI_XE3  : exit  coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Embarcadero\BDS\10.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Embarcadero\BDS\10.0', 'RootDir', '') as String);
    DELPHI_XE4  : exit  coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Embarcadero\BDS\11.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Embarcadero\BDS\11.0', 'RootDir', '') as String);
    DELPHI_XE5  : exit  coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Embarcadero\BDS\12.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Embarcadero\BDS\12.0', 'RootDir', '') as String);
    DELPHI_XE6  : exit  coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Embarcadero\BDS\14.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Embarcadero\BDS\14.0', 'RootDir', '') as String);
    DELPHI_XE7  : exit  coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\Embarcadero\BDS\15.0', 'RootDir', '') as String, Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\Embarcadero\BDS\15.0', 'RootDir', '') as String);
  else
    raise new Exception('Invalid "delphi" flag; Supported version 6, 7, 8, 9, 10, 11, 12, 14, 15, 16, 17, 18, 19, 20, 21 (2005, 2006, 2007, 2008, 2009, 2010, 2011, XE, XE2, XE3, XE4, XE5, XE6, XE7)');
  end;
end;

class method DelphiPlugin.DelphiVersion(aVersion: String): Integer;
begin
  if aVersion.StartsWith('d') or aVersion.StartsWith('D') then 
    aVersion := aVersion.Substring(1);

  case aVersion of
    '6'         : result := DELPHI_6;
    '7'         : result := DELPHI_7;
    '8'         : result := DELPHI_8;
    '2005',  '9': result := DELPHI_2005;
    '2006', '10': result := DELPHI_2006;
    '2007', '11': result := DELPHI_2007;
    '2009', '12': result := DELPHI_2009;
    '2010', '14': result := DELPHI_2010;
    'XE',   '15': result := DELPHI_XE;
    'XE2',  '16': result := DELPHI_XE2;
    'XE3',  '17': result := DELPHI_XE3;
    'XE4',  '18': result := DELPHI_XE4;
    'XE5',  '19': result := DELPHI_XE5;
    'XE6',  '20': result := DELPHI_XE6;
    'XE7',  '21': result := DELPHI_XE7;
  else
    raise new Exception('Invalid "delphi" version; Supported version 6, 7, 8, 9, 10, 11, 12, 14, 15, 16, 17, 18, 19, 20, 21 (2005, 2006, 2007, 2008, 2009, 2010, 2011, XE, XE2, XE3, XE4, XE5, XE6, XE7)');
  end;
end;

class method DelphiPlugin.DelphiVersionName(aVersion: Integer): String;
begin
  case aVersion of
    DELPHI_6    : exit 'Delphi 6';
    DELPHI_7    : exit 'Delphi 7';
    DELPHI_8    : exit 'Delphi 8';
    DELPHI_2005 : exit 'Delphi 2005';
    DELPHI_2006 : exit 'Delphi 2006';
    DELPHI_2007 : exit 'Delphi 2007';
    DELPHI_2009 : exit 'Delphi 2009';
    DELPHI_2010 : exit 'Delphi 2010';
    DELPHI_XE   : exit 'Delphi XE';
    DELPHI_XE2  : exit 'Delphi XE2';
    DELPHI_XE3  : exit 'Delphi XE3';
    DELPHI_XE4  : exit 'Delphi XE4';
    DELPHI_XE5  : exit 'Delphi XE5';
    DELPHI_XE6  : exit 'Delphi XE6';
    DELPHI_XE7  : exit 'Delphi XE7';
  else
    raise new Exception('Unsupported Delphi version; Supported = 6-21 (excl. 13)');
  end;
end;


constructor VersionInfo();
begin
  codePage := 1252;   
  resLang := 1033;
end;

end.
