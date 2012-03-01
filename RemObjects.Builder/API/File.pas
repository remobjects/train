namespace RemObjects.Builder.API;

interface

uses
  RemObjects.Script.EcmaScript,
  System.Collections.Generic,
  System.Text;

type
  FileTools = public class
  private
    fservices: IApiRegistrationServices;
  protected
  public
    constructor(aServices: IApiRegistrationServices);

    method File_Copy(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method File_List(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method File_Delete(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method File_Read(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method File_Write(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method File_Append(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method File_Exists(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method Folder_List(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method Folder_Exists(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method Folder_Create(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method Folder_Delete(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method Path_Combine(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method Path_Resolve(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method Path_GetFilename(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method Path_GetFileWithoutExtension(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method Path_GetFilenameExtension(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
    method Path_GetFoldername(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
  end;

  [PluginRegistration]
  FilePlugin = public class(IPluginRegistration)
  private
  public
    method &Register(aServices: IApiRegistrationServices);
  end;

implementation

constructor FileTools(aServices: IApiRegistrationServices);
begin
  fservices := aServices;
end;

method FileTools.File_Copy(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  fServices.Logger.Enter('file.copy', args); try 
    if fservices.Engine.DryRun then begin
      fservices.Engine.Logger.LogMessage('Dry run.');
      exit '';
    end;
    var lVal := fServices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec));
    if lVal = nil then exit Undefined.Instance;
    var lVal2 := fServices.ResolveWithBase(Utilities.GetArgAsString(args, 1, ec));
    if lVal2 = nil then exit Undefined.Instance;
    if System.IO.Directory.Exists(lVAl2) then
      System.IO.File.Copy(lVal, System.IO.Path.Combine(lVal2, System.IO.Path.GetFileName(lVal)), true)
    else
      System.IO.File.Copy(lVal, lVal2, true);
    
    exit Undefined.Instance;
  finally
    fservices.Logger.exit('file.copy');
  end;
end;

method FileTools.File_Delete(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  fServices.Logger.Enter('file.delete', args); try 
    if fservices.Engine.DryRun then begin
      fservices.Engine.Logger.LogMessage('Dry run.');
      exit '';
    end;
    var lVal := fServices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec));
    if lVal = nil then exit Undefined.Instance;
    System.IO.File.Delete(lVal);
    exit Undefined.Instance;
  finally
    fservices.Logger.exit('file.delete');
  end;

end;

method FileTools.File_Read(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  fServices.Logger.Enter('file.read', args); try 
    if fservices.Engine.DryRun then begin
      fservices.Engine.Logger.LogMessage('Dry run.');
      exit '';
    end;
    var lVal := fServices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec));
    if lVal = nil then exit Undefined.Instance;
    exit System.IO.File.ReadAllText(lVal);
  finally
    fservices.Logger.exit('file.read');
  end;
end;

method FileTools.File_Write(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  fServices.Logger.Enter('file.write', args); try 
    if fservices.Engine.DryRun then begin
      fservices.Engine.Logger.LogMessage('Dry run.');
      exit '';
    end;
    var lVal := fServices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec));
    if lVal = nil then exit Undefined.Instance;
    System.IO.File.WriteAllText(lVal, Utilities.GetArgAsString(args, 1, ec));
    exit Undefined.Instance;
  finally
    fservices.Logger.exit('file.write');
  end;
end;

method FileTools.File_Append(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  fServices.Logger.Enter('file.append', args); try 
    if fservices.Engine.DryRun then begin
      fservices.Engine.Logger.LogMessage('Dry run.');
      exit '';
    end;
    var lVal := fServices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec));
    if lVal = nil then exit Undefined.Instance;
    System.IO.File.AppendAllText(lVal, Utilities.GetArgAsString(args, 1, ec));
    exit Undefined.Instance;
  finally
    fservices.Logger.exit('file.append');
  end;
end;

method FileTools.File_Exists(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  var lVal := fServices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec));
  if lVal = nil then exit Undefined.Instance;
  exit System.IO.File.Exists(lVal);
end;

method FileTools.Folder_Exists(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  var lVal := fServices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec));
  if lVal = nil then exit Undefined.Instance;
  exit System.IO.Directory.Exists(lVal);
end;

method FileTools.Folder_Create(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  fServices.Logger.Enter('folder.create', args); try 
    if fservices.Engine.DryRun then begin
      fservices.Engine.Logger.LogMessage('Dry run.');
      exit '';
    end;
    var lVal := fServices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec));
    if lVal = nil then exit Undefined.Instance;
    System.IO.Directory.CreateDirectory(lVal);
  finally
    fservices.Logger.exit('folder.create');
  end;
end;

method FileTools.Folder_Delete(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  fServices.Logger.Enter('folder.delete', args); try 
    if fservices.Engine.DryRun then begin
      fservices.Engine.Logger.LogMessage('Dry run.');
      exit '';
    end;
    var lVal := fServices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec));
    if lVal = nil then exit Undefined.Instance;
    System.IO.Directory.Delete(lVal, Utilities.GetArgAsBoolean(args, 1, ec));
  finally
    fservices.Logger.exit('folder.delete');
  end;
end;

method FileTools.Path_Combine(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  if length(args) = 0 then exit Undefined.Instance;
  var lCurrent :=  fServices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec));
  for i: Integer := 1 to length(args) -1 do
    lCurrent := System.IO.Path.Combine(lCurrent, Utilities.GetArgAsString(args, i, ec));
  exit lCurrent;
end;

method FileTools.Path_Resolve(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  var lVal := fServices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec));
  if lVal = nil then exit Undefined.Instance;

  var lVal2 := Utilities.GetArgAsString(args, 1, ec);
  if not String.IsNullOrEmpty(lVal2) then lVal := System.IO.Path.Combine(lVal2, lVal);

  exit System.IO.Path.GetFullPath(lVal);
end;

method FileTools.Path_GetFilename(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  var lVal := Utilities.GetArgAsString(args, 0, ec);
  if lVal = nil then exit Undefined.Instance;
  exit System.IO.Path.GetFileName(lVal);
end;

method FileTools.Path_GetFileWithoutExtension(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  var lVal := Utilities.GetArgAsString(args, 0, ec);
  if lVal = nil then exit Undefined.Instance;
  exit System.IO.Path.GetFileNameWithoutExtension(lVal);
end;

method FileTools.Path_GetFilenameExtension(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  var lVal := Utilities.GetArgAsString(args, 0, ec);
  if lVal = nil then exit Undefined.Instance;
  exit System.IO.Path.GetExtension(lVal);
end;

method FileTools.Path_GetFoldername(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  var lVal := fServices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec));
  if lVal = nil then exit Undefined.Instance;
  exit System.IO.Path.GetDirectoryName(lVal);
end;

method FileTools.File_List(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  var lVal := fServices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec));
  if lVal = nil then exit Undefined.Instance;
  var lRes := new EcmaScriptArrayObject(0, fservices.Globals);
  for each el in System.IO.Directory.GetFiles(System.IO.Path.GetDirectoryName(lVal), System.IO.Path.GetFileName(lVal), 
    if Utilities.GetArgAsBoolean(args, 1, ec) then System.IO.SearchOption.AllDirectories else System.IO.SearchOption.TopDirectoryOnly) do
    lRes.AddValue(el);
  exit lRes;
end;

method FileTools.Folder_List(ec: RemObjects.Script.EcmaScript.ExecutionContext; aSelf: Object; args: array of Object): Object;
begin
  var lVal := fServices.ResolveWithBase(Utilities.GetArgAsString(args, 0, ec));
  if lVal = nil then exit Undefined.Instance;
  var lRes := new EcmaScriptArrayObject(0, fservices.Globals);
  for each el in System.IO.Directory.GetDirectories(lVal, '*',
    if Utilities.GetArgAsBoolean(args, 1, ec) then System.IO.SearchOption.AllDirectories else System.IO.SearchOption.TopDirectoryOnly) do
    lRes.AddValue(el);
  exit lRes;
end;

method FilePlugin.&Register(aServices: IApiRegistrationServices);
begin
  var lFile := new FileTools(aServices);
  aServices.RegisterValue('file', 
    new EcmaScriptObject(aServices.Globals)
    .AddValue('copy', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lFile.File_Copy))
    .AddValue('list', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lFile.File_List))
    .AddValue('delete', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lFile.File_Delete))
    .AddValue('read', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lFile.File_Read))
    .AddValue('write', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lFile.File_Write))
    .AddValue('append', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lFile.File_Append))
    .AddValue('exists', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lFile.File_Exists))
  );

  aServices.RegisterValue('folder', 
    new EcmaScriptObject(aServices.Globals)
    .AddValue('list', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lFile.Folder_List))
    .AddValue('exists', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lFile.Folder_Exists))
    .AddValue('create', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lFile.Folder_Create))
    .AddValue('delete', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lFile.Folder_Delete))
  );

  aServices.RegisterValue('path', 
    new EcmaScriptObject(aServices.Globals)
    .AddValue('directorySeperator', System.IO.Path.DirectorySeparatorChar.ToString())
    .AddValue('combine', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lFile.Path_Combine))
    .AddValue('resolve', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lFile.Path_Resolve))
    .AddValue('getFilename', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lFile.Path_GetFilename))
    .AddValue('getFilenameWithoutExtension', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lFile.Path_GetFileWithoutExtension))
    .AddValue('getFilenameExtension', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lFile.Path_GetFilenameExtension))
    .AddValue('getFoldername', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, @lFile.Path_GetFoldername))
  );
end;

end.
