namespace RemObjects.Builder.API;

interface

uses
  System.Collections.Generic,
  System.Text;

type
  [PluginRegistration]
  InnoSetupPlugin = public class(IPluginRegistration)
  private
  protected
  public
    method &Register(aServices: IApiRegistrationServices);

    [WrapAs('inno.build')]
    class method InnoBuild(aServices: IApiRegistrationServices; aFilename: string; aOptions: InnoSetupOptions);
  end;

  InnoSetupOptions = public class
  public
    property destinationFolder: string;
    property extraArgs: string;
    property defines: array of string;
  end;

implementation

method InnoSetupPlugin.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterObjectValue('inno')
    .AddValue('build', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, typeof(InnoSetupPlugin), 'InnoBuild'));
end;

class method InnoSetupPlugin.InnoBuild(aServices: IApiRegistrationServices; aFilename: string; aOptions: InnoSetupOptions);
begin
  var lPath := string(aServices.Environment['InnoSetup_Path']);
  if string.IsNullOrEmpty(lPath) then
    lPath := string(Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 5_is1', 'InstallLocation', ''));
  if string.IsNullOrEmpty(lPath) then raise new Exception('"InnoSetup_Path" env var is set');
  lPath := System.IO.Path.Combine(lPAth, 'ISCC.exe');
  if not System.IO.File.Exists(lPath) then raise new Exception(lPath+' could not be found');
  if aServices.Engine.DryRun then exit;
  
  var sb := new StringBuilder;
  sb.AppendFormat('"{0}"', aFilename);
  if not string.IsNullOrEmpty(aOptions:destinationFolder) then
    sb.AppendFormat(' /O"{0}"', aOptions.destinationFolder);


 if aOptions <> nil then begin
    for each el in aOptions.defines do
      sb.AppendFormat(' /d"{0}"', el);
    
    sb.Append(aOptions.extraArgs);
 end;

 var lOutput:= new StringBuilder;
  Shell.ExecuteProcess(lPath, sb.ToString, false,
  a-> locking loutput do lOutput.Append(a),a-> locking Loutput do lOutput.Append(a), nil, nil);


  aServices.Logger.LogMessage(lOutput.ToSTring);

end;

end.
