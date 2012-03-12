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
  MSBuildPlugin = public class(IPluginRegistration)
  private
  public
    method &Register(aServices: IApiRegistrationServices);

    class method CheckSettings(aServices: IApiRegistrationServices);

    [WrapAs('msbuild.clean', SkipDryRun := false)]
    class method MSBuildClean(aServices: IApiRegistrationServices; aProject: string; aOptions: MSBuildOptions);
    [WrapAs('msbuild.build', SkipDryRun := false)]
    class method MSBuildBuild(aServices: IApiRegistrationServices; aProject: string; aOptions: MSBuildOptions);
    [WrapAs('msbuild.rebuild', SkipDryRun := false)]
    class method MSBuildRebuild(aServices: IApiRegistrationServices; aProject: string; aOptions: MSBuildOptions);
  end;
  MSBuildOptions = public class
  private
  public
    property configuration: string;
    property platform: string;
    property destinationPath: string;
    property extraArgs: string;
  end;  // MSBuild_Path

implementation

method MSBuildPlugin.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterObjectValue('msbuild')
    .AddValue('clean', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, typeof(MSBuildPlugin), 'MSBuildClean'))
    .AddValue('build', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, typeof(MSBuildPlugin), 'MSBuildBuild'))
    .AddValue('rebuild', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, typeof(MSBuildPlugin), 'MSBuildRebuild'))
;
end;

class method MSBuildPlugin.CheckSettings(aServices: IApiRegistrationServices);
begin
  if not File.Exists(coalesce(aServices.Environment['MSBuild_Path']:ToString, '')) then
    raise new eXception('MSBuild_Path is not set in the environment path!');
end;

class method MSBuildPlugin.MSBuildClean(aServices: IApiRegistrationServices; aProject: string; aOptions: MSBuildOptions);
begin
  CheckSettings(aServices);
  if aServices.Engine.DryRun then exit;
  var sb := new StringBuilder;
  sb.Append('/nologo "'+aProject+'"');
  sb.Append(' /target:Clean');
  if aOptions <> nil then begin
    if not string.IsNullOrEmpty(aOptions.configuration) then
      sb.Append(' "/property:Configuration='+aOptions.configuration+'"');
    if not string.IsNullOrEmpty(aOptions.platform) then
      sb.Append(' "/property:Platform='+aOptions.configuration+'"');
    if not String.IsNullOrEmpty(aOptions.destinationPath) then
      sb.Append(' "/property:OutputPath='+aOptions.destinationPath+'"');
    sb.Append(aOptions.extraArgs);
  end;

  var lOutput:= new StringBuilder;
  Shell.ExecuteProcess(string(aServices.Environment['MSBuild_Path']), sb.ToString, nil,false,
  a-> locking loutput do lOutput.Append(a),a-> locking Loutput do lOutput.Append(a), nil, nil);

  aServices.Logger.LogMessage(lOutput.ToSTring);
end;

class method MSBuildPlugin.MSBuildBuild(aServices: IApiRegistrationServices; aProject: string; aOptions: MSBuildOptions);
begin
  CheckSettings(aServices);
  if aServices.Engine.DryRun then exit;
  var sb := new StringBuilder;
  sb.Append('/nologo "'+aProject+'"');
  sb.Append(' /target:Build');
  if aOptions <> nil then begin
    if not string.IsNullOrEmpty(aOptions.configuration) then
      sb.Append(' "/property:Configuration='+aOptions.configuration+'"');
    if not string.IsNullOrEmpty(aOptions.platform) then
      sb.Append(' "/property:Platform='+aOptions.configuration+'"');
    if not String.IsNullOrEmpty(aOptions.destinationPath) then
      sb.Append(' "/property:OutputPath='+aOptions.destinationPath+'"');
    sb.Append(aOptions.extraArgs);
  end;
 var lOutput:= new StringBuilder;
  Shell.ExecuteProcess(string(aServices.Environment['MSBuild_Path']), sb.ToString, nil,false ,
  a-> locking loutput do lOutput.Append(a),a-> locking Loutput do lOutput.Append(a), nil, nil);

  aServices.Logger.LogMessage(lOutput.ToSTring);
end;

class method MSBuildPlugin.MSBuildRebuild(aServices: IApiRegistrationServices; aProject: string; aOptions: MSBuildOptions);
begin
  CheckSettings(aServices);
  if aServices.Engine.DryRun then exit;
  var sb := new StringBuilder;
  sb.Append('/nologo "'+aProject+'"');
  sb.Append(' /target:Rebuild');
  if aOptions <> nil then begin
    if not string.IsNullOrEmpty(aOptions.configuration) then
      sb.Append(' "/property:Configuration='+aOptions.configuration+'"');
    if not string.IsNullOrEmpty(aOptions.platform) then
      sb.Append(' "/property:Platform='+aOptions.configuration+'"');
    if not String.IsNullOrEmpty(aOptions.destinationPath) then
      sb.Append(' "/property:OutputPath='+aOptions.destinationPath+'"');
    sb.Append(aOptions.extraArgs);
  end;
 var lOutput:= new StringBuilder;
  Shell.ExecuteProcess(string(aServices.Environment['MSBuild_Path']), sb.ToString, nil,false ,
  a-> locking loutput do lOutput.Append(a),a-> locking Loutput do lOutput.Append(a), nil, nil);

  aServices.Logger.LogMessage(lOutput.ToSTring);
end;

end.
