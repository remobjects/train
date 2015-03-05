namespace RemObjects.Train.API;

interface

uses
  RemObjects.Train,
  System.Threading,
  System.Text,
  RemObjects.Script.EcmaScript.Internal,
  System.IO,
  RemObjects.Script.EcmaScript,
  System.Security.Cryptography,
  Amazon.S3.*;

type

  [PluginRegistration]
  S3PlugIn = public class(IPluginRegistration)
  private
  protected
  public
    method &Register(aServices: IApiRegistrationServices);
    [WrapAs('S3.listFiles', SkipDryRun := true, wantSelf := true)]
    class method ListFiles(aServices: IApiRegistrationServices;  ec: ExecutionContext; aSelf: S3Engine; aPrefix, aSuffix: String): array of String;
    [WrapAs('S3.downloadFile', SkipDryRun := true, wantSelf := true)]
    class method DownloadFile(aServices: IApiRegistrationServices;  ec: ExecutionContext; aSelf: S3Engine; aKey, aLocalTarget: String);
    [WrapAs('S3.readFile', SkipDryRun := true, wantSelf := true)]
    class method ReadFile(aServices: IApiRegistrationServices;  ec: ExecutionContext; aSelf: S3Engine; aFilename: String): String;
    [WrapAs('S3.downloadFiles', SkipDryRun := true, wantSelf := true)]
    class method DownloadFiles(aServices: IApiRegistrationServices;  ec: ExecutionContext; aSelf: S3Engine; aPrefix, aLocalTargetDir: String; aRecurse: Boolean);
    [WrapAs('S3.uploadFile', SkipDryRun := true, wantSelf := true)]
    class method UploadFile(aServices: IApiRegistrationServices;  ec: ExecutionContext; aSelf: S3Engine; aLocalFile, aKey: String);
    [WrapAs('S3.writeFile', SkipDryRun := true, wantSelf := true)]
    class method WriteFile(aServices: IApiRegistrationServices;  ec: ExecutionContext; aSelf: S3Engine; aFileToSave, aKey: String);
    [WrapAs('S3.uploadFiles', SkipDryRun := true, wantSelf := true)]
    class method UploadFiles(aServices: IApiRegistrationServices;  ec: ExecutionContext;aSelf: S3Engine;  aLocalFolderAndFilters, aPrefix: String; aRecurse: Boolean);

    [WrapAs('s3.bucket', wantSelf := true)]
    class method GetBucket(aServices: IApiRegistrationServices;  ec: ExecutionContext;aSelf: S3Engine): String;
    [WrapAs('s3.bucket', wantSelf := true)]
    class method SetBucket(aServices: IApiRegistrationServices;  ec: ExecutionContext;aSelf: S3Engine; val: String);

    [WrapAs('s3.serviceURL', wantSelf := true)]
    class method GetServiceURL(aServices: IApiRegistrationServices;  ec: ExecutionContext;aSelf: S3Engine): String;
    [WrapAs('s3.serviceURL', wantSelf := true)]
    class method SetServiceURL(aServices: IApiRegistrationServices;  ec: ExecutionContext;aSelf: S3Engine; val: String);

    [WrapAs('s3.accessKeyID', wantSelf := true)]
    class method GetAccessKeyID(aServices: IApiRegistrationServices;  ec: ExecutionContext;aSelf: S3Engine): String;
    [WrapAs('s3.accessKeyID', wantSelf := true, SecretArguments := [0])]
    class method SetAccessKeyID(aServices: IApiRegistrationServices;  ec: ExecutionContext;aSelf: S3Engine; val: String);

    [WrapAs('s3.secretAccessKey', wantSelf := true)]
    class method GetSecretAccessKey(aServices: IApiRegistrationServices;  ec: ExecutionContext;aSelf: S3Engine): String;
    [WrapAs('s3.secretAccessKey', wantSelf := true, SecretArguments := [0])]
    class method SetSecretAccessKey(aServices: IApiRegistrationServices;  ec: ExecutionContext;aSelf: S3Engine; val: String);

    [WrapAs('s3.regionEndpoint', wantSelf := true)]
    class method GetRegionEndpoint(aServices: IApiRegistrationServices;  ec: ExecutionContext;aSelf: S3Engine): String;
    [WrapAs('s3.regionEndpoint', wantSelf := true)]
    class method SetRegionEndpoint(aServices: IApiRegistrationServices;  ec: ExecutionContext;aSelf: S3Engine; val: String);
  end;
  S3Engine = public class
  private
  public
    property Client: AmazonS3Client;
  end;

implementation

method S3PlugIn.&Register(aServices: IApiRegistrationServices);
begin
  //aServices.RegisterValue('S3', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(Self), 'Include'));
  var   lProto := new EcmaScriptObject(aServices.Globals);
  lProto.Prototype := aServices.Globals.ObjectPrototype;
  lProto.AddValue('listFiles', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(S3PlugIn), 'ListFiles'));
  lProto.AddValue('downloadFile', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(S3PlugIn), 'DownloadFile'));
  lProto.AddValue('readFile', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(S3PlugIn), 'ReadFile'));
  lProto.AddValue('downloadFiles', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(S3PlugIn), 'DownloadFiles'));
  lProto.AddValue('uploadFile', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(S3PlugIn), 'UploadFile'));
  lProto.AddValue('writeFile', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(S3PlugIn), 'WriteFile'));
  lProto.AddValue('uploadFiles', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(S3PlugIn), 'UploadFiles'));
  lProto.DefineOwnProperty('bucket', 
    new PropertyValue(PropertyAttributes.All, 
    RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(S3PlugIn), 'GetBucket'),
    RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(S3PlugIn), 'SetBucket')));
  lProto.DefineOwnProperty('serviceURL', 
    new PropertyValue(PropertyAttributes.All, 
    RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(S3PlugIn), 'GetServiceURL'),
    RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(S3PlugIn), 'SetServiceURL')));
  lProto.DefineOwnProperty('accessKeyID', 
    new PropertyValue(PropertyAttributes.All, 
    RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(S3PlugIn), 'GetAccessKeyID'),
    RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(S3PlugIn), 'SetAccessKeyID')));
  lProto.DefineOwnProperty('secretAccessKey', 
    new PropertyValue(PropertyAttributes.All, 
    RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(S3PlugIn), 'GetSecretAccessKey'),
    RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(S3PlugIn), 'SetSecretAccessKey')));
  lProto.DefineOwnProperty('regionEndpoint', 
    new PropertyValue(PropertyAttributes.All, 
    RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(S3PlugIn), 'GetRegionEndpoint'),
    RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(S3PlugIn), 'SetRegionEndpoint')));

  var lObj := new EcmaScriptFunctionObject(aServices.Globals, 'S3', (aCaller, aSElf, aArgs) ->
    begin
      exit new WrapperObject(aCaller.Global, lProto, Val := new S3Engine);                                                                    
    end, 1, &Class := 'S3');
  aServices.Globals.Values.Add('S3', PropertyValue.NotEnum(lObj));

  lObj.Values['prototype'] := PropertyValue.NotAllFlags(lProto);
  lProto.Values['constructor'] := PropertyValue.NotEnum(lProto);
end;



class method S3PlugIn.ListFiles(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: S3Engine; aPrefix: String; aSuffix: String): array of String;
begin

end;

class method S3PlugIn.DownloadFile(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: S3Engine; aKey: String; aLocalTarget: String);
begin

end;

class method S3PlugIn.ReadFile(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: S3Engine; aFilename: String): String;
begin

end;

class method S3PlugIn.DownloadFiles(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: S3Engine; aPrefix: String; aLocalTargetDir: String; aRecurse: Boolean);
begin

end;

class method S3PlugIn.UploadFile(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: S3Engine; aLocalFile: String; aKey: String);
begin

end;

class method S3PlugIn.WriteFile(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: S3Engine; aFileToSave: String; aKey: String);
begin

end;

class method S3PlugIn.UploadFiles(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: S3Engine; aLocalFolderAndFilters: String; aPrefix: String; aRecurse: Boolean);
begin

end;

class method S3PlugIn.GetBucket(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: S3Engine): String;
begin

end;

class method S3PlugIn.SetBucket(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: S3Engine; val: String);
begin

end;

class method S3PlugIn.GetServiceURL(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: S3Engine): String;
begin

end;

class method S3PlugIn.SetServiceURL(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: S3Engine; val: String);
begin

end;

class method S3PlugIn.GetAccessKeyID(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: S3Engine): String;
begin

end;

class method S3PlugIn.SetAccessKeyID(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: S3Engine; val: String);
begin

end;

class method S3PlugIn.GetSecretAccessKey(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: S3Engine): String;
begin

end;

class method S3PlugIn.SetSecretAccessKey(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: S3Engine; val: String);
begin

end;

class method S3PlugIn.GetRegionEndpoint(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: S3Engine): String;
begin

end;

class method S3PlugIn.SetRegionEndpoint(aServices: IApiRegistrationServices; ec: ExecutionContext; aSelf: S3Engine; val: String);
begin

end;


end.
