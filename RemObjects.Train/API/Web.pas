namespace RemObjects.Train.API;

interface

uses
  System,
  System.IO,
  System.Net.Http;

type
  [PluginRegistration]
  WebRegister = public class(IPluginRegistration)
  private
    class var fHttpClient := new HttpClient(); readonly;
  protected
  public
    method &Register(aServices: IApiRegistrationServices);
    [WrapAs('http.getUrl', SkipDryRun := true)]
    class method HttpGetUrl(aServices: IApiRegistrationServices; aUrl: String): String;
    [WrapAs('http.downloadUrl', SkipDryRun := true)]
    class method HttpDownloadUrl(aServices: IApiRegistrationServices; ec: RemObjects.Script.EcmaScript.ExecutionContext; aUrl: String; aTarget: String := nil): String;
  end;

implementation

method WebRegister.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterValue('http', new RemObjects.Script.EcmaScript.EcmaScriptObject(aServices.Globals)
    .AddValue('getUrl', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(WebRegister), 'HttpGetUrl'))
    .AddValue('downloadUrl', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(WebRegister), 'HttpDownloadUrl')));
end;

class method WebRegister.HttpGetUrl(aServices: IApiRegistrationServices; aUrl: String): String;
begin
  exit fHttpClient.GetStringAsync(aUrl).GetAwaiter().GetResult();
end;

class method WebRegister.HttpDownloadUrl(aServices: IApiRegistrationServices; ec: RemObjects.Script.EcmaScript.ExecutionContext; aUrl: String; aTarget: String := nil): String;
begin
  aTarget := aServices.ResolveWithBase(ec, aTarget);
  using lResponse := fHttpClient.GetAsync(aUrl).GetAwaiter().GetResult() do begin
    lResponse.EnsureSuccessStatusCode();

    var lFileName: String;
    if assigned(lResponse.Content.Headers.ContentDisposition) then begin
      lFileName := lResponse.Content.Headers.ContentDisposition.FileNameStar;
      if String.IsNullOrWhiteSpace(lFileName) then
        lFileName := lResponse.Content.Headers.ContentDisposition.FileName;
    end;

    if String.IsNullOrWhiteSpace(lFileName) then
      lFileName := Path.GetFileName(lResponse.RequestMessage.RequestUri.LocalPath);
    if String.IsNullOrWhiteSpace(lFileName) then
      lFileName := 'download.bin'
    else
      lFileName := lFileName.Replace('"', '').Replace('''', '');

    aTarget := Path.Combine(aTarget, lFileName);
    using lTargetStream := new FileStream(aTarget, FileMode.Create, FileAccess.Write) do
      using lSourceStream := lResponse.Content.ReadAsStream() do
        lSourceStream.CopyTo(lTargetStream);
  end;
  exit aTarget;
end;

end.
