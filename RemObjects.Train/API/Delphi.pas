namespace RemObjects.Train.API;

interface

uses
  RemObjects.Train,
  RemObjects.Script.EcmaScript,
  RemObjects.Script.EcmaScript.Internal,
  System.Collections.Generic,
  System.Linq,
  System.Text,
  System.Text.RegularExpressions,
  System.Xml.Linq,
  System.IO,
  System.Runtime.InteropServices;

type
  [PluginRegistration]
  DelphiPlugin = public class(IPluginRegistration)
  private const
    DELPHI_6    = 6;   // compiler 14.0
    DELPHI_7    = 7;   // compiler 15.0
    DELPHI_8    = 8;   // compiler 16.0
    DELPHI_2005 = 9;   // compiler 17.0 = Rad Studio 3.0
    DELPHI_2006 = 10;  // compiler 18.0 = Rad Studio 4.0
    DELPHI_2007 = 11;  // compiler 18.5 = Rad Studio 5.0
    DELPHI_2009 = 12;  // compiler 20.0 = Rad Studio 6.0
    DELPHI_2010 = 14;  // compiler 21.0 = Rad Studio 7.0
    DELPHI_XE   = 15;  // compiler 22.0 = Rad Studio 8.0
    DELPHI_XE2  = 16;  // compiler 23.0 = Rad Studio 9.0
    DELPHI_XE3  = 17;  // compiler 24.0 = Rad Studio 10.0
    DELPHI_XE4  = 18;  // compiler 25.0 = Rad Studio 11.0
    DELPHI_XE5  = 19;  // compiler 26.0 = Rad Studio 12.0
    DELPHI_XE6  = 20;  // compiler 27.0 = Rad Studio 14.0
    /*
    DELPHI_XE7  = 21;  // compiler 28.0 = Rad Studio 15.0
    DELPHI_XE8  = 22;  // compiler 29.0 = Rad Studio 16.0
    DELPHI_XE9  = 23;  // compiler 30.0 = Rad Studio 17.0 = Delphi 10.0
    DELPHI_XE10 = 24;  // compiler 31.0 = Rad Studio 18.0 = Delphi 10.1
    DELPHI_XE11 = 25;  // compiler 32.0 = Rad Studio 19.0 = Delphi 10.2
    DELPHI_XE12 = 26;  // compiler 33.0 = Rad Studio 20.0 = Delphi 10.3
    DELPHI_XE13 = 27;  // compiler 34.0 = Rad Studio 21.0 = Delphi 10.4
    DELPHI_XE14 = 28;  // compiler 35.0 = Rad Studio 22.0 = Delphi 11.x
    */
    DELPHI_XE15 = 29;  // compiler 36.0 = Rad Studio 23.0 = Delphi 12.x
    DELPHI_XE16 = 37;  // compiler 37.0 = Rad Studio 37.0 = Delphi 13.x
    DELPHI_LAST_KNOWN_XE_VERSION = 99;
    DELPHI_MAX_SUPPORT_VERSION = DELPHI_LAST_KNOWN_XE_VERSION;
  private class var
    DELPHI_SKIP_VERSIONS: List<Integer> := new List<Integer>([13]);
  private
    class method UpdateResource(aRes: String; aIcon: String; aVersion: VersionInfo;ec: ExecutionContext);
    class method ParseVersion(aVal: String): array of Integer;
    /// D## -> ##
    /// XE -> DELPHI_XE -> 15
    /// XE## -> ## + DELPHI_XE2 - 2 -> ## + 14
    /// 2005 -> DELPHI_2005 -> 9
    /// 2006 -> DELPHI_2006 -> 10
    /// 2007 -> DELPHI_2007 -> 11
    /// 2009 -> DELPHI_2009 -> 12
    /// 2010 -> DELPHI_2010 -> 14
    /// 6..29 -> 6..29
    /// 37..99 -> 37..99
    class method DelphiVersion(aVersion: String): Integer;
    class method DelphiVersionName(aVersion: Integer): String;
  public
    method &Register(aServices: IApiRegistrationServices);

    [WrapAs('delphi.getBasePath', skipDryRun := false)]
    class method DelphiGetBasePath(aVersion: Integer): String;
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
    .AddValue('getBasePath', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(DelphiPlugin), 'DelphiGetBasePath'))
;
end;



class method DelphiPlugin.DelphiBuild(aServices: IApiRegistrationServices;ec: ExecutionContext; aProject: String; aOptions: DelphiOptions);
begin
  var lRootPath: String;
  aProject := aServices.ResolveWithBase(ec, aProject, true);
  aServices.Logger.LogMessage('Building: '+aProject);

  var iver := 0;
  var sver := 'Unknown';

  if String.IsNullOrEmpty(aOptions.dcc) then
  begin
    iver := DelphiVersion(coalesce(aOptions.delphi:Trim(), ''));
    sver := DelphiVersionName(iver);
  end;

  if not String.IsNullOrEmpty(aOptions.dcc) then
    lRootPath:= aOptions.dcc
  else begin
    lRootPath := DelphiGetBasePath(iver);
    if lRootPath = nil then raise new Exception('Cannot find Delphi registry key for '+sver);

    if aOptions:platform:ToLower in ['android','android32', 'aarm'] then
      lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dccaarm.exe')
    else if aOptions:platform:ToLower in ['android64', 'aarm64'] then
      lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dccaarm64.exe')
    else if aOptions:platform:ToLower in ['ios32', 'iossimulator'] then
      lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dccios32.exe')
    else if aOptions:platform:ToLower in ['iosarm', 'iosdevice', 'iosdevice32'] then
      lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dcciosarm.exe')
    else if aOptions:platform:ToLower in ['iosarm64', 'iosdevice64'] then
      lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dcciosarm64.exe')
    else if aOptions:platform:ToLower in ['iossimarm64'] then
      lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dcciossimarm64.exe')
    else if aOptions:platform:ToLower in ['linux', 'linux64'] then
      lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dcclinux64.exe')
    else if aOptions:platform:ToLower in ['macosx', 'osx', 'osx32'] then
      lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dccosx.exe')
    else if aOptions:platform:ToLower in ['macosx64', 'osx64'] then
      lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dccosx64.exe')
    else if aOptions:platform:ToLower in ['osxarm64'] then
      lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dccosxarm64.exe')
    else if aOptions:platform:ToLower in ['64', 'x64', 'win64'] then
      lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dcc64.exe')
    else if String.IsNullOrEmpty(aOptions:platform) or (aOptions:platform:ToLower in ['32', 'x86', 'win32']) then
      lRootPath := Path.Combine(Path.Combine(lRootPath, 'Bin'), 'dcc32.exe')
    else
      raise new Exception('Unsupported platform ("win32", "win64", "osx32", "osx64", '+
                                                '"iossimulator", "iosdevice32", "iosdevice64", "iossimarm64", '+
                                                '"linux64", "android", "android64", "osxarm64")');
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
    if iver > DELPHI_7 then
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

  var lenvironment := new Environment();
  lenvironment.LoadSystem;
  lenvironment.Item['Path'] := lDelphi+';'+lenvironment.Item['Path'];
  var lenv: array of KeyValuePair<String,String> := lenvironment.Select(a->new KeyValuePair<String,String>(a.Key,a.Value.ToString)).ToArray;

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
   end, lenv, nil);

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

class method DelphiPlugin.DelphiGetBasePath(aVersion: Integer): String;
begin
  var reghive: String;
  case aVersion of
    DELPHI_6    : reghive := 'Borland\Delphi\6';
    DELPHI_7    : reghive := 'Borland\Delphi\7';
    DELPHI_8    : reghive := 'Borland\BDS\2';
    DELPHI_2005 : reghive := 'Borland\BDS\3';
    DELPHI_2006 : reghive := 'Borland\BDS\4';
    DELPHI_2007 : reghive := 'Borland\BDS\5';
    DELPHI_2009 : reghive := 'CodeGear\BDS\6';
    DELPHI_2010 : reghive := 'CodeGear\BDS\7';
    DELPHI_XE   : reghive := 'Embarcadero\BDS\8';
    DELPHI_XE2  : reghive := 'Embarcadero\BDS\9';
    DELPHI_XE3  : reghive := 'Embarcadero\BDS\10';
    DELPHI_XE4  : reghive := 'Embarcadero\BDS\11';
    DELPHI_XE5  : reghive := 'Embarcadero\BDS\12';
    DELPHI_XE6..DELPHI_XE15  : reghive := $'Embarcadero\BDS\{aVersion-6}';
    DELPHI_XE16..DELPHI_MAX_SUPPORT_VERSION: reghive := $'Embarcadero\BDS\{aVersion}';
  else
    raise new Exception($'Invalid "delphi" flag; Supported version 6..12, 14..29, 37..{DELPHI_MAX_SUPPORT_VERSION}');
  end;

  exit  coalesce(Microsoft.Win32.Registry.GetValue('HKEY_CURRENT_USER\Software\'+reghive+'.0', 'RootDir', '') as String,
                 Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\Software\'+reghive+'.0', 'RootDir', '') as String);
end;

class method DelphiPlugin.DelphiVersion(aVersion: String): Integer;
begin
  var lversion :=  aVersion.ToLowerInvariant;
  if lversion.StartsWith('d') then lversion := lversion.Substring(1);
  if lversion.StartsWith('xe') then begin
    if lversion = 'xe' then exit DELPHI_XE;
    lversion := lversion.Substring(2);
    if Integer.TryParse(lversion, out result) then begin
      // Delphi XE2..Delphi 12
      var dx := DELPHI_XE2 - 2;
      if (result + dx) in [DELPHI_XE2..DELPHI_XE15] then exit result + dx;
      // Delphi 13..Delphi ###
      if result in [DELPHI_XE16..DELPHI_MAX_SUPPORT_VERSION] then exit result;
    end;
  end
  else begin
    if Integer.TryParse(lversion, out result) then begin
      if result in [2005..2007] then exit result-2005+DELPHI_2005;
      if result = 2009 then exit DELPHI_2009;
      if result = 2010 then exit DELPHI_2010;
      // 6..12, 14..29
      if (result in [DELPHI_6..DELPHI_XE15]) and (not DELPHI_SKIP_VERSIONS.Contains(result)) then exit;
      // 37..99
      if result in [DELPHI_XE16..DELPHI_MAX_SUPPORT_VERSION] then exit;
    end;
  end;

  raise new Exception($'Invalid "delphi" version; Supported version 6..12, 14..29, 37..99 (also supported 2005..2007, 2009, 2010, XE..XE{DELPHI_LAST_KNOWN_XE_VERSION})');
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
    DELPHI_XE2..DELPHI_XE15: exit $'Delphi XE{aVersion-14}';
    DELPHI_XE16..DELPHI_MAX_SUPPORT_VERSION: exit $'Delphi XE{aVersion-21}';
  else
    raise new Exception($'Unsupported Delphi version; Supported = 6..12, 14..29, 37..{DELPHI_LAST_KNOWN_XE_VERSION}');
  end;
end;

constructor VersionInfo();
begin
  codePage := 1252;
  resLang := 1033;
end;

end.