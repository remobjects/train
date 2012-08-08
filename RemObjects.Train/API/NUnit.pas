namespace RemObjects.Train.API;

interface

uses
  RemObjects.Train,
  System.Threading,
  System.Text,
  RemObjects.Script.EcmaScript, 
  RemObjects.Script.EcmaScript.Internal;
type

  [PluginRegistration]
  NUnitPlugin = public class(IPluginRegistration)
  private
  protected
  public
    method &Register(aServices: IApiRegistrationServices);
    [WrapAs('nunit.run')]
    class method NUnitRun(aServices: IApiRegistrationServices;  ec: ExecutionContext; aFilename: String);
  end;


implementation

uses
  System.IO;

method NUnitPlugin.&Register(aServices: IApiRegistrationServices);
begin
   aServices.RegisterObjectValue('nunit')
    .AddValue('run', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(NUnitPlugin), 'NUnitRun'));
end;

class method NUnitPlugin.NUnitRun(aServices: IApiRegistrationServices;  ec: ExecutionContext; aFilename: String);
begin
  aFilename := aServices.ResolveWithBase(ec, aFilename);
  aServices.Logger.LogMessage('Running Unit Tests in this file : ' + aFilename);
  var lPath := String(aServices.Environment['NUnit']);
  if String.IsNullOrEmpty(lPath) then raise new Exception('"NUnit" env var is not set');
  lPath := System.IO.Path.Combine(lPath, 'nunit-console.exe');
  if not System.IO.File.Exists(lPath) then raise new Exception(lPath + ' could not be found');
  var n:= Shell.ExecuteProcess(lPath, aFilename, nil, false, 
    a-> aServices.Logger.LogError(a),
    a-> aServices.Logger.LogMessage(a), nil, nil);
  if n <> 0 then raise new Exception('Units test(s) failed');
end;

end.
