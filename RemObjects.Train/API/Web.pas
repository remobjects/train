namespace RemObjects.Train.API;

interface

uses
  System.Collections.Generic,
  System.Text;

type
  [PluginRegistration]
  WebRegister = public class(IPluginRegistration)
  private
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
  var lReq := System.Net.HttpWebRequest.Create(aUrl);
  using res := lReq.GetResponse() do begin
    using srrs := new System.IO.StreamReader(res.GetResponseStream) do
      exit srrs.ReadToEnd;
  end;
end;

class method WebRegister.HttpDownloadUrl(aServices: IApiRegistrationServices; ec: RemObjects.Script.EcmaScript.ExecutionContext; aUrl: String; aTarget: String := nil): String;
begin
  var lReq := System.Net.HttpWebRequest.Create(aUrl);
  aTarget := aServices.ResolveWithBase(ec,aTarget);
  using res := lReq.GetResponse() do begin
    var lfn := res.Headers["Content-Disposition"];
    if not String.IsNullOrEmpty(lfn) then begin
      if lReq.RequestUri.AbsolutePath.Contains('/') then
        lfn := lReq.RequestUri.AbsolutePath.Substring(lReq.RequestUri.AbsolutePath.IndexOf('/')+1);
    end;
    if String.IsNullOrWhiteSpace(lfn) then lfn := 'download.bin';
    aTarget := System.IO.Path.Combine(aTarget, lfn);
    using fs := new System.IO.FileStream(aTarget, System.IO.FileMode.Create, System.IO.FileAccess.Write) do
      using fs2 := res.GetResponseStream() do fs2.CopyTo(fs);
  end;
  exit aTarget;
end;

end.