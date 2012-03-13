namespace RemObjects.Train.API;

interface

uses
  RemObjects.Script.EcmaScript,
  System.Collections.Generic,
  System.Linq,
  System.Text;

type
  
  [PluginRegistration]
  FilePlugin = public class(IPluginRegistration)
  private
  public
    method &Register(aServices: IApiRegistrationServices);

    [WrapAs('file.copy', SkipDryRun := true)]
    class method File_Copy(aServices: IApiRegistrationServices; aLeft, aRight: String);
    [WrapAs('file.list', SkipDryRun := true)]
    class method File_List(aServices: IApiRegistrationServices; aPathAndMask: String; aRecurse: Boolean): array of String;
    [WrapAs('file.remove', SkipDryRun := true)]
    class method File_Delete(aServices: IApiRegistrationServices; AFN: String);
    [WrapAs('file.read', SkipDryRun := true)]
    class method File_Read(aServices: IApiRegistrationServices; AFN: String): String;
    [WrapAs('file.write', SkipDryRun := true)]
    class method File_Write(aServices: IApiRegistrationServices; aFN, aData: String);
    [WrapAs('file.append', SkipDryRun := true)]
    class method File_Append(aServices: IApiRegistrationServices; aFN, aData: String);
    [WrapAs('file.exists', Important := false)]
    class method File_Exists(aServices: IApiRegistrationServices; aFN: String): Boolean;
    [WrapAs('folder.list', SkipDryRun := true, Important := false)]
    class method Folder_List(aServices: IApiRegistrationServices; aPathAndMask: String; aRecurse: Boolean): array of String;
    [WrapAs('folder.exists', Important := false)]
    class method Folder_Exists(aServices: IApiRegistrationServices; aFN: String): Boolean;
    [WrapAs('folder.create', SkipDryRun := true)]
    class method Folder_Create(aServices: IApiRegistrationServices; aFN: String);
    [WrapAs('folder.remove', SkipDryRun := true)]
    class method Folder_Delete(aServices: IApiRegistrationServices; aFN: String; aRecurse: Boolean := true);
    [WrapAs('path.combine', SkipDryRun := true, Important := false)]
    class method Path_Combine(aServices: IApiRegistrationServices; params args: array of String): String;
    [WrapAs('path.resolve', SkipDryRun := true, Important := false)]
    class method Path_Resolve(aServices: IApiRegistrationServices; aPath: String; aBase: String := nil): String;
    [WrapAs('path.getFilename', SkipDryRun := true, Important := false)]
    class method Path_GetFilename(aServices: IApiRegistrationServices; aFN: String): String;
    [WrapAs('path.getFilenameWithoutExtension', SkipDryRun := true, Important := false)]
    class method Path_GetFileWithoutExtension(aServices: IApiRegistrationServices; aFN: String): String;
    [WrapAs('path.getFilenameExtension', SkipDryRun := true, Important := false)]
    class method Path_GetFilenameExtension(aServices: IApiRegistrationServices; aFN: String): String;
    [WrapAs('path.getFoldername', SkipDryRun := true, Important := false)]
    class method Path_GetFoldername(aServices: IApiRegistrationServices; aFN: String): String;
  end;

implementation


method FilePlugin.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterValue('file', 
    new EcmaScriptObject(aServices.Globals)
    .AddValue('copy', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'File_Copy'))
    .AddValue('list', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'File_List'))
    .AddValue('remove', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'File_Delete'))
    .AddValue('read', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'File_Read'))
    .AddValue('write', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'File_Write'))
    .AddValue('append', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'File_Append'))
    .AddValue('exists', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'File_Exists'))
  );

  aServices.RegisterValue('folder', 
    new EcmaScriptObject(aServices.Globals)
    .AddValue('list', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Folder_List'))
    .AddValue('exists', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Folder_Exists'))
    .AddValue('create', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Folder_Create'))
    .AddValue('remove', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Folder_Delete'))
  );

  aServices.RegisterValue('path', 
    new EcmaScriptObject(aServices.Globals)
    .AddValue('directorySeperator', System.IO.Path.DirectorySeparatorChar.ToString())
    .AddValue('combine', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Path_Combine'))
    .AddValue('resolve', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Path_Resolve'))
    .AddValue('getFilename', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Path_GetFilename'))
    .AddValue('getFilenameWithoutExtension', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Path_GetFileWithoutExtension'))
    .AddValue('getFilenameExtension', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Path_GetFilenameExtension'))
    .AddValue('getFoldername', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Path_GetFoldername'))
  );
end;



class method FilePlugin.File_Copy(aServices: IApiRegistrationServices; aLeft, aRight: String);
begin
  var lVal := aServices.ResolveWithBase(aLeft);
  var lVal2 := aServices.ResolveWithBase(aRight);
  if System.IO.Directory.Exists(lVal2) then
    System.IO.File.Copy(lVal, System.IO.Path.Combine(lVal2, System.IO.Path.GetFileName(lVal)), true)
  else
    System.IO.File.Copy(lVal, lVal2, true);
end;

class method FilePlugin.File_Delete(aServices: IApiRegistrationServices; AFN: String);
begin
  var lVal := aServices.ResolveWithBase(AFN);
  if lVal = nil then exit;
  System.IO.File.Delete(lVal);
end;

class method FilePlugin.File_Read(aServices: IApiRegistrationServices; AFN: String): String;
begin
  var lVal := aServices.ResolveWithBase(AFN);
  if lVal = nil then;
  exit System.IO.File.ReadAllText(lVal);
end;

class method FilePlugin.File_Write(aServices: IApiRegistrationServices; aFN, aData: String);
begin
  var lVal := aServices.ResolveWithBase(aFN);
  System.IO.File.WriteAllText(lVal, aData);
end;

class method FilePlugin.File_Append(aServices: IApiRegistrationServices; aFN, aData:String);
begin
  var lVal := aServices.ResolveWithBase(aFN);
  System.IO.File.AppendAllText(lVal, aData);
end;

class method FilePlugin.File_Exists(aServices: IApiRegistrationServices; aFN: String): Boolean;
begin
  var lVal := aServices.ResolveWithBase(aFN);
  if lVal = nil then exit false;
  if aServices.Engine.DryRun then exit true;
  exit System.IO.File.Exists(lVal);
end;

class method FilePlugin.Folder_Exists(aServices: IApiRegistrationServices; aFN: String): Boolean;
begin
  var lVal := aServices.ResolveWithBase(aFN);
  if lVal = nil then exit false;
  if aServices.Engine.DryRun then exit true;
  exit System.IO.Directory.Exists(lVal);
end;

class method FilePlugin.Folder_Create(aServices: IApiRegistrationServices; aFN: String);
begin
  var lVal := aServices.ResolveWithBase(aFN);
  System.IO.Directory.CreateDirectory(lVal);
end;

class method FilePlugin.Folder_Delete(aServices: IApiRegistrationServices; aFN: String; aRecurse: Boolean := true);
begin
  var lVal := aServices.ResolveWithBase(aFN);
  if System.IO.Directory.Exists(lVal) then 
  System.IO.Directory.Delete(lVal, aRecurse);
end;

class method FilePlugin.Path_Combine(aServices: IApiRegistrationServices; params args: array of String): String;
begin
  if length(args) = 0 then exit nil;
  var lCurrent :=  args.FirstOrDefault;
  for i: Integer := 1 to length(args) -1 do
    lCurrent := System.IO.Path.Combine(lCurrent, args[i]);
  exit lCurrent;
end;

class method FilePlugin.Path_Resolve(aServices: IApiRegistrationServices; aPath: String; aBase: String := nil): String;
begin

  if not String.IsNullOrEmpty(aBase) then begin

    aBase := aServices.ResolveWithBase(aBase);
    aPath := System.IO.Path.Combine(aBase, aPath);
  end else
    aPath := aServices.ResolveWithBase(aPath);
  exit System.IO.Path.GetFullPath(aPath);
end;

class method FilePlugin.Path_GetFilename(aServices: IApiRegistrationServices; aFN: String): String;
begin
  exit System.IO.Path.GetFileName(aFN);
end;

class method FilePlugin.Path_GetFileWithoutExtension(aServices: IApiRegistrationServices; aFN: String): String;
begin
  exit System.IO.Path.GetFileNameWithoutExtension(aFN);
end;

class method FilePlugin.Path_GetFilenameExtension(aServices: IApiRegistrationServices; aFN: String): String;
begin
  exit System.IO.Path.GetExtension(aFN);
end;

class method FilePlugin.Path_GetFoldername(aServices: IApiRegistrationServices; aFN: String): String;
begin
  var lVal := aServices.ResolveWithBase(aFN);
  exit System.IO.Path.GetDirectoryName(lVal);
end;

class method FilePlugin.File_List(aServices: IApiRegistrationServices; aPathAndMask: String; aRecurse: Boolean): array of String;
begin
  var lVal := aServices.ResolveWithBase(aPathAndMask);
  var res := new List<String>;
  for each el in System.IO.Directory.GetFiles(System.IO.Path.GetDirectoryName(lVal), System.IO.Path.GetFileName(lVal), 
    if aRecurse then System.IO.SearchOption.AllDirectories else System.IO.SearchOption.TopDirectoryOnly) do
    res.Add(el);
  exit res.ToArray;

end;

class method FilePlugin.Folder_List(aServices: IApiRegistrationServices; aPathAndMask: String; aRecurse: Boolean): array of String;
begin
  var lVal := aServices.ResolveWithBase(aPathAndMask);
  var res := new List<String>;
  for each el in System.IO.Directory.GetDirectories(lVal, '*',
    if aRecurse then System.IO.SearchOption.AllDirectories else System.IO.SearchOption.TopDirectoryOnly) do
    res.Add(el);
  exit res.ToArray;
end;

end.
