namespace RemObjects.Train.API;

interface

uses
  RemObjects.Train,
  System.Threading,
  System.Text,
  System.IO,
  System.Security.Cryptography,
  RemObjects.Script.EcmaScript;

type

  [PluginRegistration]
  MD5PlugIn = public class(IPluginRegistration)
  private
  protected
  public
    method &Register(aServices: IApiRegistrationServices);
    [WrapAs('md5.createFromFile')]
    class method GetMd5HashFromFile(aServices: IApiRegistrationServices;  ec: ExecutionContext; aFilename: String): String;
  end;

implementation

method MD5PlugIn.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterObjectValue('md5').AddValue('createFromFile', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(MD5PlugIn), 'GetMd5HashFromFile'));
end;

class method MD5PlugIn.GetMd5HashFromFile(aServices: IApiRegistrationServices;  ec: ExecutionContext; aFilename: String): String;
begin
  aFilename := aServices.ResolveWithBase(ec, aFilename);
  using file := new FileStream(aFilename, FileMode.Open) do
  begin
    using lMD5 := MD5.Create() do begin
      var lHash := lMD5.ComputeHash(file);
      var lResult := new StringBuilder();
      for i: Int32 := 0 to lHash.Length - 1 do begin
        lResult.Append(lHash[i].ToString('x2'));
      end;
      exit lResult.ToString();
    end;
  end;
end;

end.
