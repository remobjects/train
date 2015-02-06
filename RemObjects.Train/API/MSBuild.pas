namespace RemObjects.Train.API;

interface

uses 
  RemObjects.Train,
  System.Threading,
  RemObjects.Script.EcmaScript, 
  RemObjects.Script.EcmaScript.Internal, 
  System.Text,
  System.Text.RegularExpressions,
  System.Xml.Linq,
  System.Linq,
  System.IO,
  System.Runtime.InteropServices;

type
  [PluginRegistration]
  MSBuildPlugin = public class(IPluginRegistration)
  private
    class var fVersionRegex,
    fFileVersionRegex: Regex;
  public
    method &Register(aServices: IApiRegistrationServices);

    class method DetectMSBuild(aServices: IApiRegistrationServices;ec: ExecutionContext; aOptions: MSBuildOptions): String;
    class method getDefaultMSBuild(aServices: IApiRegistrationServices; ec: ExecutionContext; aVersion: String; aRaiseException: Boolean): String;

    [WrapAs('msbuild.custom', SkipDryRun := false)]
    class method MSBuildCustom(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: MSBuildOptions);
    [WrapAs('msbuild.clean', SkipDryRun := false)]
    class method MSBuildClean(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: MSBuildOptions);
    [WrapAs('msbuild.build', SkipDryRun := false)]
    class method MSBuildBuild(aServices: IApiRegistrationServices; ec: ExecutionContext;aProject: String; aOptions: MSBuildOptions);
    [WrapAs('msbuild.rebuild', SkipDryRun := false)]
    class method MSBuildRebuild(aServices: IApiRegistrationServices; ec: ExecutionContext;aProject: String; aOptions: MSBuildOptions);
    [WrapAs('msbuild.updateAssemblyVersion', SkipDryRun := true)]
    class method MSBuildUpdateAssemblyVersion(aServices: IApiRegistrationServices; ec: ExecutionContext; aFile: String; aNewVersion: String; aFileVersion: String := '');
  end;
  [PluginRegistration]
  GacPlugin = public class(IPluginRegistration)
  public
    method &Register(aServices: IApiRegistrationServices);
    [WrapAs('gac.install', SkipDryRun := true)]
    class method GacInstall(aServices: IApiRegistrationServices; ec: ExecutionContext; aFile: String);
    [WrapAs('gac.uninstall', SkipDryRun := true)]
    class method GacUninstall(aServices: IApiRegistrationServices; ec: ExecutionContext; aFile: String);
    [WrapAs('gac.list', SkipDryRun := true)]
    class method GacList(aServices: IApiRegistrationServices; ec: ExecutionContext; aFilter: String): array of String;
  end;


  MSBuildOptions = public class
  private
  public
    property configuration: String;
    property platform: String;
    property destinationFolder: String;
    property extraArgs: String;
    property toolsVersion: String;
  end;  // MSBuild

implementation

method GacPlugin.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterObjectValue('gac')
    .AddValue('install', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(GacPlugin), 'GacInstall'))
    .AddValue('uninstall', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(GacPlugin), 'GacUninstall'))
    .AddValue('list', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(GacPlugin), 'GacList'))
;
end;

class method GacPlugin.GacInstall(aServices: IApiRegistrationServices; ec: ExecutionContext; aFile: String);
begin
  if MUtilities.Windows then begin
    MSWinGacUtil.Register(aServices.ResolveWithBase(ec, aFile, false));
  end else
    raise new Exception('GacUtil only implemented for Windows');
end;

class method GacPlugin.GacUninstall(aServices: IApiRegistrationServices; ec: ExecutionContext; aFile: String);
begin
  if MUtilities.Windows then begin
    var list := MSWinGacUtil.List(aFile);
    for l in list do
      MSWinGacUtil.Unregister(l);
  end else
    raise new Exception('GacUtil only implemented for Windows');
end;

class method GacPlugin.GacList(aServices: IApiRegistrationServices; ec: ExecutionContext; aFilter: String): array of String;
begin
  var lFilter := if aFilter = nil then '' else aFilter.ToLowerInvariant;
  if MUtilities.Windows then begin
    var lList := MSWinGacUtil.List('');
    result := lList.Where(a->a.ToLowerInvariant.Contains(lFilter)).ToArray;
  end else
    raise new Exception('GacUtil only implemented for Windows');
end;

method MSBuildPlugin.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterObjectValue('msbuild')
    .AddValue('custom', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(MSBuildPlugin), 'MSBuildCustom'))
    .AddValue('clean', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(MSBuildPlugin), 'MSBuildClean'))
    .AddValue('build', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(MSBuildPlugin), 'MSBuildBuild'))
    .AddValue('rebuild', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(MSBuildPlugin), 'MSBuildRebuild'))
    .AddValue('updateAssemblyVersion', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(MSBuildPlugin), 'MSBuildUpdateAssemblyVersion'))
;

end;

class method MSBuildPlugin.MSBuildClean(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: MSBuildOptions);
begin
  aProject := aServices.ResolveWithBase(ec, aProject);
  //aServices.Logger.LogMessage('Building: '+aProject);
  var lbuild := DetectMSBuild(aServices, ec, aOptions);

  if aServices.Engine.DryRun then exit;
  var sb := new StringBuilder;
  sb.Append('/nologo "'+aProject+'"');
  sb.Append(' /target:Clean');
  if aOptions <> nil then begin
    if not String.IsNullOrEmpty(aOptions.configuration) then
      sb.Append(' "/property:Configuration='+aOptions.configuration+'"');
    if not String.IsNullOrEmpty(aOptions.platform) then
      sb.Append(' "/property:Platform='+aOptions.platform+'"');
    if not String.IsNullOrEmpty(aOptions.destinationFolder) then
      sb.Append(' "/property:OutputPath='+aServices.ResolveWithBase(ec,aOptions.destinationFolder)+'"');
    sb.Append(' '+aOptions.extraArgs);
  end;

  var lTmp := new DelayedLogger();
  aServices.Logger.LogMessage('Running: {0} {1}', lbuild, sb.ToString);
  var lOutput := new StringBuilder;
  var n := Shell.ExecuteProcess(lbuild, sb.ToString, nil,false ,
  a-> begin
    if not String.IsNullOrEmpty(a) then begin
      lTmp.LogError(a);
      locking lOutput do lOutput.AppendLine(a);
    end;
   end ,a-> begin
    if not String.IsNullOrEmpty(a) then begin
      if a.Contains(': error ') then
        lTmp.LogError(a);
      locking lOutput do lOutput.AppendLine(a);
    end;
   end, nil, nil);

  if n <> 0 then
    lTmp.LogMessage(lOutput.ToString)
  else
    lTmp.LogInfo(lOutput.ToString);

  lTmp.Replay(aServices.Logger);

  if n <> 0 then raise new Exception('MSBuild failed');
end;

class method MSBuildPlugin.MSBuildBuild(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: MSBuildOptions);
begin
  aProject := aServices.ResolveWithBase(ec, aProject);
  //aServices.Logger.LogMessage('Building: '+aProject);
  var lbuild := DetectMSBuild(aServices, ec, aOptions);
  if aServices.Engine.DryRun then exit;
  var sb := new StringBuilder;
  sb.Append('/nologo "'+aProject+'"');
  sb.Append(' /target:Build');
  if aOptions <> nil then begin
    if not String.IsNullOrEmpty(aOptions.configuration) then
      sb.Append(' "/property:Configuration='+aOptions.configuration+'"');
    if not String.IsNullOrEmpty(aOptions.platform) then
      sb.Append(' "/property:Platform='+aOptions.platform+'"');
    if not String.IsNullOrEmpty(aOptions.destinationFolder) then
      sb.Append(' "/property:OutputPath='+aServices.ResolveWithBase(ec,aOptions.destinationFolder)+'"');
    sb.Append(' '+aOptions.extraArgs);
  end;
  var lTmp := new DelayedLogger();
  aServices.Logger.LogMessage('Running: {0} {1}', lbuild, sb.ToString);
  var lOutput := new StringBuilder;
  var n := Shell.ExecuteProcess(lbuild, sb.ToString, nil,false ,
  a-> begin
    if not String.IsNullOrEmpty(a) then begin
      lTmp.LogError(a);
      locking lOutput do lOutput.AppendLine(a);
    end;
   end ,a-> begin
    if not String.IsNullOrEmpty(a) then begin
      if a.Contains(': error ') then
        lTmp.LogError(a);
      locking lOutput do lOutput.AppendLine(a);
    end;
   end, nil, nil);

  if n <> 0 then
    lTmp.LogMessage(lOutput.ToString)
  else
    lTmp.LogInfo(lOutput.ToString);

  lTmp.Replay(aServices.Logger);

  if n <> 0 then raise new Exception('MSBuild failed');
end;

class method MSBuildPlugin.MSBuildRebuild(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: MSBuildOptions);
begin
  aProject := aServices.ResolveWithBase(ec, aProject);
  //aServices.Logger.LogMessage('Building: '+aProject);
  var lbuild := DetectMSBuild(aServices, ec, aOptions);

  if aServices.Engine.DryRun then exit;
  var sb := new StringBuilder;
  sb.Append('/nologo "'+aProject+'"');
  sb.Append(' /target:Rebuild');
  if aOptions <> nil then begin
    if not String.IsNullOrEmpty(aOptions.configuration) then
      sb.Append(' "/property:Configuration='+aOptions.configuration+'"');
    if not String.IsNullOrEmpty(aOptions.platform) then
      sb.Append(' "/property:Platform='+aOptions.platform+'"');
    if not String.IsNullOrEmpty(aOptions.destinationFolder) then
      sb.Append(' "/property:OutputPath='+aServices.ResolveWithBase(ec,aOptions.destinationFolder)+'"');
    sb.Append(' '+aOptions.extraArgs);
  end;

  var lTmp := new DelayedLogger();
  aServices.Logger.LogMessage('Running: {0} {1}', lbuild, sb.ToString);
  var lOutput := new StringBuilder;
  var n := Shell.ExecuteProcess(lbuild, sb.ToString, nil,false ,
  a-> begin
    if not String.IsNullOrEmpty(a) then begin
      lTmp.LogError(a);
      locking lOutput do lOutput.AppendLine(a);
    end;
   end ,a-> begin
    if not String.IsNullOrEmpty(a) then begin
      if a.Contains(': error ') then
        lTmp.LogError(a);
      locking lOutput do lOutput.AppendLine(a);
    end;
   end, nil, nil);

  if n <> 0 then
    lTmp.LogMessage(lOutput.ToString)
  else
    lTmp.LogInfo(lOutput.ToString);

  lTmp.Replay(aServices.Logger);

  if n <> 0 then raise new Exception('MSBuild failed');
end;

class method MSBuildPlugin.MSBuildUpdateAssemblyVersion(aServices: IApiRegistrationServices; ec: ExecutionContext; 
  aFile: String; aNewVersion: String; aFileVersion: String);
begin
  for each el in aFile.Split([';', ','], StringSplitOptions.RemoveEmptyEntries).Select(a->aServices.ResolveWithBase(ec, a)) do begin
    var lFile := File.ReadAllText(el);
    var lOrg := lFile;
    var lFoundAsmVer := false;
    var lFoundAsmFileVer := false;
    
    if fVersionRegex = nil then begin
      fVersionRegex := new Regex('(?<=\:\s*AssemblyVersion\(["''])(?<version>.*?)(?=["'']\))', RegexOptions.IgnoreCase);
      fFileVersionRegex := new Regex('(?<=\:\s*AssemblyFileVersion\(["''])(?<version>.*?)(?=["'']\))', RegexOptions.IgnoreCase);
    end;
    lFile := fVersionRegex.Replace(lFile, method (aMatch: Match): String begin
        lFoundAsmVer := true;
        exit aNewVersion;
      end);
    lFile := fFileVersionRegex.Replace(lFile, method (aMatch: Match): String begin
        lFoundAsmFileVer := true;
        if String.IsNullOrEmpty(aFileVersion) then exit aNewVersion;
        exit aFileVersion;
      end);
      
    if not lFoundAsmVer then begin
      if Path.GetExtension(el).ToLower = '.swift' then
        lFile := lFile+#13#10'[assembly: AssemblyVersion("'+aNewVersion+'")]'#13#10
      else
        lFile := lFile+#13#10'@assembly:AssemblyVersion("'+aNewVersion+'")'#13#10;
    end;

    if not lFoundAsmFileVer and not String.IsNullOrEmpty(aFileVersion) then begin
      if Path.GetExtension(el).ToLower = '.swift' then
        lFile := lFile+#13#10'@assembly:AssemblyVersion("'+aFileVersion+'")'#13#10
      else
        lFile := lFile+#13#10'[assembly: AssemblyVersion("'+aFileVersion+'")]'#13#10;
    end;

    if lOrg <> lFile then 
      File.WriteAllText(el, lFile, Encoding.UTF8);
  end;
end;

class method MSBuildPlugin.MSBuildCustom(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: MSBuildOptions);
begin
  aProject := aServices.ResolveWithBase(ec, aProject);
  //aServices.Logger.LogMessage('Building: '+aProject);
  var lbuild := DetectMSBuild(aServices, ec, aOptions);

  if aServices.Engine.DryRun then exit;
  var sb := new StringBuilder;
  sb.Append('/nologo "'+aProject+'"');
  if aOptions <> nil then begin
    if not String.IsNullOrEmpty(aOptions.configuration) then
      sb.Append(' "/property:Configuration='+aOptions.configuration+'"');
    if not String.IsNullOrEmpty(aOptions.platform) then
      sb.Append(' "/property:Platform='+aOptions.platform+'"');
    if not String.IsNullOrEmpty(aOptions.destinationFolder) then
      sb.Append(' "/property:OutputPath='+aServices.ResolveWithBase(ec,aOptions.destinationFolder)+'"');
    sb.Append(' '+aOptions.extraArgs);
  end;

  var lTmp := new DelayedLogger();
  aServices.Logger.LogMessage('Running: {0} {1}', lbuild, sb.ToString);
  var lOutput := new StringBuilder;
  var n := Shell.ExecuteProcess(lbuild, sb.ToString, nil,false ,
  a-> begin
    if not String.IsNullOrEmpty(a) then begin
      lTmp.LogError(a);
      locking lOutput do lOutput.AppendLine(a);
    end;
   end ,a-> begin
    if not String.IsNullOrEmpty(a) then begin
      if a.StartsWith('MSBUILD : error') then
        lTmp.LogError(a);
      locking lOutput do lOutput.AppendLine(a);
    end;
   end, nil, nil);

  if n <> 0 then
    lTmp.LogMessage(lOutput.ToString)
  else
    lTmp.LogInfo(lOutput.ToString);

  lTmp.Replay(aServices.Logger);

  if n <> 0 then raise new Exception('MSBuild failed');

end;

class method MSBuildPlugin.getDefaultMSBuild(aServices: IApiRegistrationServices; ec: ExecutionContext; aVersion: String; aRaiseException: Boolean := true):String;
const
  msbuild20 = '$(windir)/Microsoft.NET/Framework/v2.0.50727/MSBuild.exe';
  msbuild35 = '$(windir)/Microsoft.NET/Framework/v3.5/MSBuild.exe';
  msbuild40 = '$(windir)/Microsoft.NET/Framework/v4.0.30319/MSBuild.exe';

begin  
  result := '';
  var lbuild: String;

  case aVersion of 
    '2','2.0': begin
      lbuild := coalesce(aServices.Environment['MSBuild20']:ToString, '');
      if File.Exists(lbuild) then exit lbuild; 
      lbuild := aServices.Expand(ec, msbuild20);
      if File.Exists(lbuild) then exit lbuild; 
      exit getDefaultMSBuild(aServices, ec,  '3.5', aRaiseException);
    end;
    '3.5': begin
      lbuild := coalesce(aServices.Environment['MSBuild35']:ToString, '');
      if File.Exists(lbuild) then exit lbuild; 
      lbuild := aServices.Expand(ec, msbuild35);
      if File.Exists(lbuild) then exit lbuild; 
      exit getDefaultMSBuild(aServices, ec,  '4.0', aRaiseException);
    end;
    '4','4.0': begin
      lbuild := coalesce(aServices.Environment['MSBuild40']:ToString, '');
      if File.Exists(lbuild) then exit lbuild; 
      lbuild := aServices.Expand(ec, msbuild40);
      if File.Exists(lbuild) then exit lbuild; 
    end; 
  else
    lbuild := coalesce(aServices.Environment['MSBuild']:ToString, '');
    if File.Exists(lbuild) then exit lbuild; 
    
    lbuild :=  getDefaultMSBuild(aServices, ec,  '4.0', false);
    if not String.IsNullOrEmpty(lbuild) then exit lbuild;
    lbuild :=  getDefaultMSBuild(aServices, ec,  '3.5', false);
    if not String.IsNullOrEmpty(lbuild) then exit lbuild;
    lbuild :=  getDefaultMSBuild(aServices, ec,  '2.0', true);
    if not String.IsNullOrEmpty(lbuild) then exit lbuild;
  end;

  if aRaiseException then 
    raise new Exception('MSBuild is not found!');
end;

class method MSBuildPlugin.DetectMSBuild(aServices: IApiRegistrationServices;ec: ExecutionContext;aOptions: MSBuildOptions): String;  
begin
  exit getDefaultMSBuild(aServices, ec, aOptions:toolsVersion, true);
end;

end.
