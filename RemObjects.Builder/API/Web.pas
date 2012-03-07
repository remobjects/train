namespace RemObjects.Builder.API;

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
    class method HttpGetUrl(aServices: IApiRegistrationServices; aUrl: string): string;
    [WrapAs('http.downloadUrl', SkipDryRun := true)]
    class method HttpDownloadUrl(aServices: IApiRegistrationServices; aUrl: string; aTarget: String := nil): string;
  end;

implementation

method WebRegister.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterValue('http', new RemObjects.Script.EcmaScript.EcmaScriptObject(aServices.Globals)
    .AddValue('getUrl', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, typeof(WebRegister), 'HttpGetUrl'))
    .AddValue('downloadUrl', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, typeof(WebRegister), 'HttpDownloadUrl')));
end;

class method WebRegister.HttpGetUrl(aServices: IApiRegistrationServices; aUrl: string): string;
begin
  var lReq := System.Net.HttpWebRequest.Create(aUrl);
  using res := lReq.GetResponse() do begin
    using srrs := new System.IO.StreamReader(res.GetResponseStream) do
      exit srrs.ReadToEnd;
  end;
end;

class method WebRegister.HttpDownloadUrl(aServices: IApiRegistrationServices; aUrl: string; aTarget: String := nil): string;
begin
  var lReq := System.Net.HttpWebRequest.Create(aUrl);
  aTarget := aServices.ResolveWithBase(aTarget);
  using res := lReq.GetResponse() do begin
    var lfn := res.Headers["Content-Disposition"];
    if not string.IsNullOrEmpty(lFN) then begin
      if lReq.RequestUri.AbsolutePath.Contains('/') then
        lFn := lReq.RequestUri.AbsolutePath.Substring(lReq.RequestUri.AbsolutePath.IndexOf('/')+1);
    end;
    if string.IsNullOrWhiteSpace(lFN) then lFN := 'download.bin';
    aTarget := System.IO.Path.Combine(aTarget, lFN);
    using fs := new System.IO.FileStream(aTarget, System.IO.FileMode.Create, System.IO.FileAccess.Write) do 
      using fs2 := res.GetResponseStream() do fs.CopyTo(fs);
  end;
  exit aTarget;
end;

end.
