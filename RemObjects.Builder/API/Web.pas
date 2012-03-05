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
  end;

implementation

method WebRegister.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterValue('http', new RemObjects.Script.EcmaScript.EcmaScriptObject(aServices.Globals)
    .AddValue('getUrl', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, (ec, s, args) -> 
      begin
        var lReq := System.Net.HttpWebRequest.Create(RemObjects.Script.EcmaScript.Utilities.GetArgAsString(args, 0, ec));
        using res := lReq.GetResponse() do begin
          using srrs := new System.IO.StreamReader(res.GetResponseStream) do
            exit srrs.ReadToEnd;
        end;
      end))
    .AddValue('downloadUrl', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, (ec, s, args) -> 
      begin
        var lReq := System.Net.HttpWebRequest.Create(RemObjects.Script.EcmaScript.Utilities.GetArgAsString(args, 0, ec));
        var lTarget := aServices.ResolveWithBase(RemObjects.Script.EcmaScript.Utilities.GetArgAsString(args, 1, ec));
        using res := lReq.GetResponse() do begin
          var lfn := res.Headers["Content-Disposition"];
          if not string.IsNullOrEmpty(lFN) then begin
            if lReq.RequestUri.AbsolutePath.Contains('/') then
              lFn := lReq.RequestUri.AbsolutePath.Substring(lReq.RequestUri.AbsolutePath.IndexOf('/')+1);
          end;
          if string.IsNullOrWhiteSpace(lFN) then lFN := 'download.bin';
          lTarget := System.IO.Path.Combine(lTarget, lFN);
          using fs := new System.IO.FileStream(lTarget, System.IO.FileMode.Create, System.IO.FileAccess.Write) do 
            using fs2 := res.GetResponseStream() do fs.CopyTo(fs);
        end;
        exit lTarget;
      end))
  );
end;

end.
