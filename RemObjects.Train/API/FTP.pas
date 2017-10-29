namespace RemObjects.Train.API;

interface

uses
  RemObjects.Train,
  RemObjects.Script.EcmaScript,
  RemObjects.Script.EcmaScript.Internal,
  System.Text,
  System.Net,
  System.IO;

type

  [PluginRegistration]
  FTPPlugIn = public class(IPluginRegistration)
  private
  protected
  public
    method &Register(aServices: IApiRegistrationServices);
    [WrapAs('ftp.upload', SkipDryRun := true, SecretArguments := [1, 2])]
    class method FtpUpload(aServices: IApiRegistrationServices;ec: RemObjects.Script.EcmaScript.ExecutionContext; aServer, aUsername, aPassword, aFileName, aRemote: String);
  end;

implementation

method FTPPlugIn.&Register(aServices: IApiRegistrationServices);
begin
  var rov := aServices.RegisterObjectValue('ftp');
  rov.AddValue('upload', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FTPPlugIn), 'FtpUpload'));
end;

class method FTPPlugIn.FtpUpload(aServices: IApiRegistrationServices; ec: RemObjects.Script.EcmaScript.ExecutionContext; aServer, aUsername, aPassword, aFileName, aRemote: String);
begin
  aFileName := aServices.ResolveWithBase(ec, aFileName);
  using client := new WebClient() do
  begin
    client.Credentials := new NetworkCredential(aUsername, aPassword);
    using sr := new System.IO.FileStream(aFileName, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.Read) do
    begin
      var ba := new Byte[sr.Length];
      sr.Read(ba, 0, ba.Length - 1);
      client.UploadData(aServer + '/' + aRemote, ba);
    end;
  end;
end;

end.