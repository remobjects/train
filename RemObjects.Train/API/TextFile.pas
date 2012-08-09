namespace RemObjects.Train.API;

interface

uses
  RemObjects.Train,
  RemObjects.Script.EcmaScript, 
  RemObjects.Script.EcmaScript.Internal, 
  System.Text,
  System.IO;

type
  
  [PluginRegistration]
  TextFilePlugIn = public class(IPluginRegistration)
  private
  protected
  public
    method &Register(aServices: IApiRegistrationServices);
    [WrapAs('textFile.write')]
    class method WriteTextFile(aServices: IApiRegistrationServices;  ec: ExecutionContext; aFilename, aText: String);
    [WrapAs('textFile.read')]
    class method ReadTextFile(aServices: IApiRegistrationServices;  ec: ExecutionContext; aFilename: String): String;
  end;

implementation

method TextFilePlugIn.&Register(aServices: IApiRegistrationServices);
begin
  var rov := aServices.RegisterObjectValue('textFile');
  rov.AddValue('write', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(TextFilePlugIn), 'WriteTextFile'));
  rov.AddValue('read', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(TextFilePlugIn), 'ReadTextFile'));
end;

class method TextFilePlugIn.WriteTextFile(aServices: IApiRegistrationServices; ec: ExecutionContext; aFilename: String; aText: String);
begin
  aFilename := aServices.ResolveWithBase(ec, aFilename);
  File.WriteAllText(aFilename, aText);
end;

class method TextFilePlugIn.ReadTextFile(aServices: IApiRegistrationServices; ec: ExecutionContext; aFilename: String): String;
begin
  aFilename := aServices.ResolveWithBase(ec, aFilename);
  result := File.ReadAllText(aFilename);
end;

end.
