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
    var md := new MD5CryptoServiceProvider();
    var retVal := md.ComputeHash(file);
    var sb := new StringBuilder();
    for i: Int32 := 0 to retVal.Length - 1 do
    begin
      sb.Append(retVal[i].ToString('x2'))
    end;
    exit sb.ToString();
  end;
end;

end.
