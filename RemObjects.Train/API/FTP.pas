namespace RemObjects.Train.API;

interface

uses
  RemObjects.Train,
  RemObjects.Script.EcmaScript,
  RemObjects.Script.EcmaScript.Internal,
  FluentFTP,
  System.Net,
  System.IO,
  System;

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
  var lServer := aServer;
  if not lServer.Contains('://') then
    lServer := 'ftp://' + lServer;

  var lUri := new Uri(lServer);
  var lRemotePath := aRemote.Replace('\', '/').TrimStart('/');
  var lBasePath := lUri.AbsolutePath.TrimEnd('/');
  if not String.IsNullOrEmpty(lBasePath) then
    lRemotePath := lBasePath + '/' + lRemotePath
  else
    lRemotePath := '/' + lRemotePath;

  using lClient := new FtpClient() do begin
    lClient.Host := lUri.Host;
    lClient.Port := if lUri.IsDefaultPort then 21 else lUri.Port;
    lClient.Credentials := new NetworkCredential(aUsername, aPassword);
    lClient.Connect();
    if lClient.UploadFile(aFileName, lRemotePath, FtpRemoteExists.Overwrite, true, FtpVerify.None) = FtpStatus.Failed then
      raise new IOException('FTP upload failed for ' + lRemotePath);
  end;
end;

end.
