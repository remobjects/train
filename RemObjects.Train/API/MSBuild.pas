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
  MSBuildPlugin = public class(IPluginRegistration)
  private
  public
    method &Register(aServices: IApiRegistrationServices);

    class method CheckSettings(aServices: IApiRegistrationServices);

    [WrapAs('msbuild.clean', SkipDryRun := false)]
    class method MSBuildClean(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: MSBuildOptions);
    [WrapAs('msbuild.build', SkipDryRun := false)]
    class method MSBuildBuild(aServices: IApiRegistrationServices; ec: ExecutionContext;aProject: String; aOptions: MSBuildOptions);
    [WrapAs('msbuild.rebuild', SkipDryRun := false)]
    class method MSBuildRebuild(aServices: IApiRegistrationServices; ec: ExecutionContext;aProject: String; aOptions: MSBuildOptions);
  end;
  MSBuildOptions = public class
  private
  public
    property configuration: String;
    property platform: String;
    property destinationPath: String;
    property extraArgs: String;
  end;  // MSBuild_Path

implementation

method MSBuildPlugin.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterObjectValue('msbuild')
    .AddValue('clean', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(MSBuildPlugin), 'MSBuildClean'))
    .AddValue('build', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(MSBuildPlugin), 'MSBuildBuild'))
    .AddValue('rebuild', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(MSBuildPlugin), 'MSBuildRebuild'))
;
end;

class method MSBuildPlugin.CheckSettings(aServices: IApiRegistrationServices);
begin
  if not File.Exists(coalesce(aServices.Environment['MSBuild_Path']:ToString, '')) then
    raise new Exception('MSBuild_Path is not set in the environment path!');
end;

class method MSBuildPlugin.MSBuildClean(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: MSBuildOptions);
begin
  aProject := aServices.ResolveWithBase(ec, aProject);
  aServices.Logger.LogMessage('Building: '+aProject);
  CheckSettings(aServices);

  if aServices.Engine.DryRun then exit;
  var sb := new StringBuilder;
  sb.Append('/nologo "'+aProject+'"');
  sb.Append(' /target:Clean');
  if aOptions <> nil then begin
    if not String.IsNullOrEmpty(aOptions.configuration) then
      sb.Append(' "/property:Configuration='+aOptions.configuration+'"');
    if not String.IsNullOrEmpty(aOptions.platform) then
      sb.Append(' "/property:Platform='+aOptions.configuration+'"');
    if not String.IsNullOrEmpty(aOptions.destinationPath) then
      sb.Append(' "/property:OutputPath='+aOptions.destinationPath+'"');
    sb.Append(aOptions.extraArgs);
  end;

  var lTmp := new DelayedLogger();
  var n := Shell.ExecuteProcess(String(aServices.Environment['MSBuild_Path']), sb.ToString, nil,false ,
  a-> begin
    if not String.IsNullOrEmpty(a) then
    lTmp.LogError(a)
   end ,a-> begin
    if not String.IsNullOrEmpty(a) then begin
      if a.StartsWith('MSBUILD : error') then
        lTmp.LogError(a)
      else
       lTmp.LogMessage(a)
    end;
   end, nil, nil);

  lTmp.Replay(aServices.Logger);
  if n <> 0 then raise new Exception('MSBuild failed');
end;

class method MSBuildPlugin.MSBuildBuild(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: MSBuildOptions);
begin
  aProject := aServices.ResolveWithBase(ec, aProject);
  aServices.Logger.LogMessage('Building: '+aProject);
  CheckSettings(aServices);
  if aServices.Engine.DryRun then exit;
  var sb := new StringBuilder;
  sb.Append('/nologo "'+aProject+'"');
  sb.Append(' /target:Build');
  if aOptions <> nil then begin
    if not String.IsNullOrEmpty(aOptions.configuration) then
      sb.Append(' "/property:Configuration='+aOptions.configuration+'"');
    if not String.IsNullOrEmpty(aOptions.platform) then
      sb.Append(' "/property:Platform='+aOptions.configuration+'"');
    if not String.IsNullOrEmpty(aOptions.destinationPath) then
      sb.Append(' "/property:OutputPath='+aOptions.destinationPath+'"');
    sb.Append(aOptions.extraArgs);
  end;
  var lTmp := new DelayedLogger();
  var n := Shell.ExecuteProcess(String(aServices.Environment['MSBuild_Path']), sb.ToString, nil,false ,
  a-> begin
    if not String.IsNullOrEmpty(a) then
    lTmp.LogError(a)
   end ,a-> begin
    if not String.IsNullOrEmpty(a) then begin
      if a.StartsWith('MSBUILD : error') then
        lTmp.LogError(a)
      else
       lTmp.LogMessage(a)
    end;
   end, nil, nil);

  lTmp.Replay(aServices.Logger);
  if n <> 0 then raise new Exception('MSBuild failed');
end;

class method MSBuildPlugin.MSBuildRebuild(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOptions: MSBuildOptions);
begin
  aProject := aServices.ResolveWithBase(ec, aProject);
  aServices.Logger.LogMessage('Building: '+aProject);
  CheckSettings(aServices);

  if aServices.Engine.DryRun then exit;
  var sb := new StringBuilder;
  sb.Append('/nologo "'+aProject+'"');
  sb.Append(' /target:Rebuild');
  if aOptions <> nil then begin
    if not String.IsNullOrEmpty(aOptions.configuration) then
      sb.Append(' "/property:Configuration='+aOptions.configuration+'"');
    if not String.IsNullOrEmpty(aOptions.platform) then
      sb.Append(' "/property:Platform='+aOptions.configuration+'"');
    if not String.IsNullOrEmpty(aOptions.destinationPath) then
      sb.Append(' "/property:OutputPath='+aOptions.destinationPath+'"');
    sb.Append(aOptions.extraArgs);
  end;
  var lTmp := new DelayedLogger();
  var n := Shell.ExecuteProcess(String(aServices.Environment['MSBuild_Path']), sb.ToString, nil,false ,
  a-> begin
    if not String.IsNullOrEmpty(a) then
    lTmp.LogError(a)
   end ,a-> begin
    if not String.IsNullOrEmpty(a) then begin
      if a.StartsWith('MSBUILD : error') then
        lTmp.LogError(a)
      else
       lTmp.LogMessage(a)
    end;
   end, nil, nil);

  lTmp.Replay(aServices.Logger);
  if n <> 0 then raise new Exception('MSBuild failed');
end;

end.
