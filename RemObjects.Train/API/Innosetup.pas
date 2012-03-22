namespace RemObjects.Train.API;

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
    class method InnoBuild(aServices: IApiRegistrationServices; aFilename: String; aOptions: InnoSetupOptions);
  end;

  InnoSetupOptions = public class
  public
    property destinationFolder: String;
    property extraArgs: String;
    property defines: array of String;
  end;

implementation

method InnoSetupPlugin.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterObjectValue('inno')
    .AddValue('build', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(InnoSetupPlugin), 'InnoBuild'));
end;

class method InnoSetupPlugin.InnoBuild(aServices: IApiRegistrationServices; aFilename: String; aOptions: InnoSetupOptions);
begin
  var lPath := String(aServices.Environment['InnoSetup']);
  if String.IsNullOrEmpty(lPath) then
    lPath := String(Microsoft.Win32.Registry.GetValue('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 5_is1', 'InstallLocation', ''));
  if String.IsNullOrEmpty(lPath) then raise new Exception('"InnoSetup" env var is set');
  lPath := System.IO.Path.Combine(lPath, 'ISCC.exe');
  if not System.IO.File.Exists(lPath) then raise new Exception(lPath+' could not be found');
  if aServices.Engine.DryRun then exit;
  
  var sb := new StringBuilder;
  sb.AppendFormat('"{0}"', aFilename);
  if not String.IsNullOrEmpty(aOptions:destinationFolder) then
    sb.AppendFormat(' /O"{0}"', aOptions.destinationFolder);


 if aOptions <> nil then begin
    for each el in aOptions.defines do
      sb.AppendFormat(' /d"{0}"', el);
    
    sb.Append(aOptions.extraArgs);
 end;

 var lOutput:= new StringBuilder;
  var n:= Shell.ExecuteProcess(lPath, sb.ToString, nil,false ,
  a-> locking lOutput do lOutput.Append(a),a-> locking lOutput do lOutput.Append(a), nil, nil);


  aServices.Logger.LogMessage(lOutput.ToString);
  if n <> 0 then raise new Exception('InnoSetup failed');
end;

end.
