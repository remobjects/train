namespace RemObjects.Train.API;

interface

uses
  RemObjects.Train,
  System.Threading,
  System.Text,
  RemObjects.Script.EcmaScript;
type

  [PluginRegistration]
  PEVerifyPlugin = public class(IPluginRegistration)
  private
  protected
  public
    method &Register(aServices: IApiRegistrationServices);
    [WrapAs('peverify.verifyFile')]
    class method VerifyFile(aServices: IApiRegistrationServices;  ec: ExecutionContext; aFilename, aErrorIgnoreCodes: String);
    [WrapAs('peverify.verifyFolder')]
    class method VerifyFolder(aServices: IApiRegistrationServices;  ec: ExecutionContext; aFoldername, aSearchPattern: String; aVerifyOptions: array of PEVerifyOption);
  end;

  PEVerifyOption = public class
  public
    property Filename: String;
    property ErrorIgnoreCodes: String;
  end;

implementation

uses
  System.Collections.Generic,
  System.IO;

method PEVerifyPlugin.&Register(aServices: IApiRegistrationServices);
begin
   aServices.RegisterObjectValue('peverify') 
    .AddValue('verifyFile', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(PEVerifyPlugin), 'VerifyFile'))
    .AddValue('verifyFolder', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(PEVerifyPlugin), 'VerifyFolder'));
end;

class method PEVerifyPlugin.VerifyFile(aServices: IApiRegistrationServices; ec: ExecutionContext; aFilename, aErrorIgnoreCodes: String);
begin
  aFilename := aServices.ResolveWithBase(ec, aFilename);
  var lPath := String(aServices.Environment['PEVerify']);
  if String.IsNullOrEmpty(lPath) then raise new Exception('"PEVerify" env var is not set');
  lPath := System.IO.Path.Combine(lPath, 'PEVerify.exe');
  if not System.IO.File.Exists(lPath) then raise new Exception(lPath + ' could not be found');
  var errorignore := iif(String.IsNullOrEmpty(aErrorIgnoreCodes), String.Empty, ' /ignore=' + aErrorIgnoreCodes);
  var n:= Shell.ExecuteProcess(lPath, aFilename.Quote() + ' /hresult /nologo' + errorignore, nil, false, 
    a-> aServices.Logger.LogError(a), nil, nil, nil);
  if n <> 0 then raise new Exception('PEVerify failed');
end;

class method PEVerifyPlugin.VerifyFolder(aServices: IApiRegistrationServices; ec: ExecutionContext; aFoldername, aSearchPattern: String; aVerifyOptions: array of PEVerifyOption);
begin
  var aOptionsList := new List<PEVerifyOption>(aVerifyOptions);
  aFoldername := aServices.ResolveWithBase(ec, aFoldername); 
  var files := Directory.GetFiles(aFoldername, aSearchPattern);
  for each f in files do 
  begin
    var errorignore := String.Empty;
    var fn := Path.GetFileName(f);
    var op := aOptionsList.Find(fo -> fo.Filename = fn);
    if assigned(op) then errorignore := op.ErrorIgnoreCodes;
    VerifyFile(aServices, ec, f, errorignore);
  end;
end;

end.
