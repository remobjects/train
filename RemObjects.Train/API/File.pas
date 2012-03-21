namespace RemObjects.Train.API;

interface

uses
  RemObjects.Script.EcmaScript,
  System.Collections.Generic,
  RemObjects.Train,
  System.Linq,
  System.Text;

type
  
  [PluginRegistration]
  FilePlugin = public class(IPluginRegistration)
  private
  public
    method &Register(aServices: IApiRegistrationServices);


    class method Find(aPath: String): sequence of String;

    [WrapAs('file.copy', SkipDryRun := true)]
    class method File_Copy(aServices: IApiRegistrationServices; ec: ExecutionContext;aLeft, aRight: String; aRecurse: Boolean := false);
    [WrapAs('file.move', SkipDryRun := true)]
    class method File_Move(aServices: IApiRegistrationServices; ec: ExecutionContext;aLeft, aRight: String);
    [WrapAs('folder.move', SkipDryRun := true)]
    class method Folder_Move(aServices: IApiRegistrationServices; ec: ExecutionContext;aLeft, aRight: String);
    [WrapAs('file.list', SkipDryRun := true)]
    class method File_List(aServices: IApiRegistrationServices; ec: ExecutionContext;aPathAndMask: String; aRecurse: Boolean := false): array of String;
    [WrapAs('file.remove', SkipDryRun := true)]
    class method File_Delete(aServices: IApiRegistrationServices; ec: ExecutionContext;AFN: String);
    [WrapAs('file.read', SkipDryRun := true)]
    class method File_Read(aServices: IApiRegistrationServices; ec: ExecutionContext;AFN: String): String;
    [WrapAs('file.write', SkipDryRun := true)]
    class method File_Write(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN, aData: String);
    [WrapAs('file.append', SkipDryRun := true)]
    class method File_Append(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN, aData: String);
    [WrapAs('file.exists', Important := false)]
    class method File_Exists(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN: String): Boolean;
    [WrapAs('folder.list', SkipDryRun := true, Important := false)]
    class method Folder_List(aServices: IApiRegistrationServices; ec: ExecutionContext;aPathAndMask: String; aRecurse: Boolean): array of String;
    [WrapAs('folder.exists', Important := false)]
    class method Folder_Exists(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN: String): Boolean;
    [WrapAs('folder.create', SkipDryRun := true)]
    class method Folder_Create(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN: String);
    [WrapAs('folder.remove', SkipDryRun := true)]
    class method Folder_Delete(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN: String; aRecurse: Boolean := true);
    [WrapAs('path.combine', SkipDryRun := true, Important := false)]
    class method Path_Combine(aServices: IApiRegistrationServices; ec: ExecutionContext;params args: array of String): String;
    [WrapAs('path.resolve', SkipDryRun := true, Important := false)]
    class method Path_Resolve(aServices: IApiRegistrationServices; ec: ExecutionContext;aPath: String; aBase: String := nil): String;
    [WrapAs('path.getFileName', SkipDryRun := true, Important := false)]
    class method Path_GetFilename(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN: String): String;
    [WrapAs('path.getFileNameWithoutExtension', SkipDryRun := true, Important := false)]
    class method Path_GetFileWithoutExtension(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN: String): String;
    [WrapAs('path.getFileNameExtension', SkipDryRun := true, Important := false)]
    class method Path_GetFilenameExtension(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN: String): String;
    [WrapAs('path.getFolderName', SkipDryRun := true, Important := false)]
    class method Path_GetFoldername(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN: String): String;
  end;

implementation


method FilePlugin.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterValue('file', 
    new EcmaScriptObject(aServices.Globals)
    .AddValue('copy', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'File_Copy'))
    .AddValue('move', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'File_Move'))
    .AddValue('list', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'File_List'))
    .AddValue('remove', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'File_Delete'))
    .AddValue('read', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'File_Read'))
    .AddValue('write', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'File_Write'))
    .AddValue('append', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'File_Append'))
    .AddValue('exists', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'File_Exists'))
  );

  aServices.RegisterValue('folder', 
    new EcmaScriptObject(aServices.Globals)
    .AddValue('list', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Folder_List'))
    .AddValue('exists', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Folder_Exists'))
    .AddValue('move', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Folder_Move'))
    .AddValue('create', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Folder_Create'))
    .AddValue('remove', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Folder_Delete'))
  );

  aServices.RegisterValue('path', 
    new EcmaScriptObject(aServices.Globals)
    .AddValue('directorySeperator', System.IO.Path.DirectorySeparatorChar.ToString())
    .AddValue('combine', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Path_Combine'))
    .AddValue('resolve', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Path_Resolve'))
    .AddValue('getFileName', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Path_GetFilename'))
    .AddValue('getFileNameWithoutExtension', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Path_GetFileWithoutExtension'))
    .AddValue('getFileNameExtension', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Path_GetFilenameExtension'))
    .AddValue('getFolderName', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(FilePlugin), 'Path_GetFoldername'))
  );
end;

class method FilePlugin.File_Move(aServices: IApiRegistrationServices; ec: ExecutionContext;aLeft, aRight: String);
begin
  var lVal := aServices.ResolveWithBase(ec, aLeft);
  var lVal2 := aServices.ResolveWithBase(ec, aRight);

  
  if (lVal.IndexOfAny(['*', '?']) >= 0)  then begin
    
    var lMask := '';
    var lDir := lVal;
    lDir := System.IO.Path.GetDirectoryName(lVal);
    lMask := System.IO.Path.GetFileName(lVal);
    if lMask = '' then lMask := '*';

    var lZero: Boolean := true;
    var lFiles:= new StringBuilder;
    for each mask in lMask.Split([';'], StringSplitOptions.RemoveEmptyEntries) do 
    for each el in System.IO.Directory.GetFiles(lDir, mask, System.IO.SearchOption.TopDirectoryOnly) do begin
      lZero := false;
      var lTargetFN := el.Substring(lDir.Length+1);
      lTargetFN := System.IO.Path.Combine(lVal2,lTargetFN);
      var lTargetDir := System.IO.Path.GetDirectoryName(lTargetFN);
      if not System.IO.Directory.Exists(lTargetDir) then System.IO.Directory.CreateDirectory(lTargetDir);
      System.IO.File.Move(el, lTargetFN);
      lFiles .AppendLine(String.Format('Moved {0} to {1}', el,  lTargetFN));
    end;
    aServices.Logger.LogInfo(lFiles.ToString);
    if lZero then raise new Exception('Zero files moved!');
    exit;
  end;

  if System.IO.Directory.Exists(lVal) then
    System.IO.Directory.Move(lVal, lVal2)
  else
  if System.IO.Directory.Exists(lVal2) then
    System.IO.File.Move(lVal, System.IO.Path.Combine(lVal2, System.IO.Path.GetFileName(lVal)))
  else
    System.IO.File.Move(lVal, lVal2);
  aServices.Logger.LogInfo(String.Format('Moved {0} to {1}', lVal,  lVal2));
end;

class method FilePlugin.File_Copy(aServices: IApiRegistrationServices; ec: ExecutionContext;aLeft, aRight: String; aRecurse: Boolean := false);
begin
  var lVal := aServices.ResolveWithBase(ec, aLeft);
  var lVal2 := aServices.ResolveWithBase(ec, aRight);
  if (lVal.IndexOfAny(['*', '?']) >= 0) or System.IO.Directory.Exists(lVal2) or System.IO.Directory.Exists(lVal) then begin
    if (lVal.IndexOfAny(['*', '?']) < 0) and System.IO.Directory.Exists(lVal) then lVal := System.IO.Path.Combine(lVal, '*');
    var lMask := '';
    var lDir := lVal;
    lDir := System.IO.Path.GetDirectoryName(lVal);
    lMask := System.IO.Path.GetFileName(lVal);
    if lMask = '' then lMask := '*';

    var lZero: Boolean := true;
    var lFiles := new System.Text.StringBuilder;
    for each mask in lMask.Split([';'], StringSplitOptions.RemoveEmptyEntries) do 
    for each el in System.IO.Directory.GetFiles(lDir, mask, 
      if aRecurse then System.IO.SearchOption.AllDirectories else System.IO.SearchOption.TopDirectoryOnly) do begin
      lZero := false;
      var lTargetFN := el.Substring(lDir.Length+1);
      lTargetFN := System.IO.Path.Combine(lVal2,lTargetFN);
      var lTargetDir := System.IO.Path.GetDirectoryName(lTargetFN);
      if not System.IO.Directory.Exists(lTargetDir) then System.IO.Directory.CreateDirectory(lTargetDir);
      System.IO.File.Copy(el, lTargetFN, true);
      lFiles .AppendLine(String.Format('Copied {0} to {1}', el,  lTargetFN));
    end;
    
    aServices.Logger.LogInfo(lFiles.ToString);
    if lZero then raise new Exception('Zero files copied!');
    exit;
  end;

  if System.IO.Directory.Exists(lVal2) then
    System.IO.File.Copy(lVal, System.IO.Path.Combine(lVal2, System.IO.Path.GetFileName(lVal)), true)
  else
    System.IO.File.Copy(lVal, lVal2, true);
  aServices.Logger.LogInfo(String.Format('Copied {0} to {1}', lVal,  lVal2));
end;

class method FilePlugin.File_Delete(aServices: IApiRegistrationServices; ec: ExecutionContext;AFN: String);
begin
  var lVal := aServices.ResolveWithBase(ec, AFN);
  if lVal = nil then exit;
  for each el in Find(lVal) do 
    System.IO.File.Delete(el);
end;

class method FilePlugin.File_Read(aServices: IApiRegistrationServices; ec: ExecutionContext;AFN: String): String;
begin
  var lVal := aServices.ResolveWithBase(ec, AFN);
  if lVal = nil then;
  exit System.IO.File.ReadAllText(lVal);
end;

class method FilePlugin.File_Write(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN, aData: String);
begin
  var lVal := aServices.ResolveWithBase(ec, aFN);
  System.IO.File.WriteAllText(lVal, aData);
end;

class method FilePlugin.File_Append(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN, aData:String);
begin
  var lVal := aServices.ResolveWithBase(ec, aFN);
  System.IO.File.AppendAllText(lVal, aData);
end;

class method FilePlugin.File_Exists(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN: String): Boolean;
begin
  var lVal := aServices.ResolveWithBase(ec, aFN);
  if lVal = nil then exit false;
  if aServices.Engine.DryRun then exit true;
  exit System.IO.File.Exists(lVal);
end;

class method FilePlugin.Folder_Exists(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN: String): Boolean;
begin
  var lVal := aServices.ResolveWithBase(ec, aFN);
  if lVal = nil then exit false;
  if aServices.Engine.DryRun then exit true;
  exit System.IO.Directory.Exists(lVal);
end;

class method FilePlugin.Folder_Create(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN: String);
begin
  var lVal := aServices.ResolveWithBase(ec, aFN);
  System.IO.Directory.CreateDirectory(lVal);
end;

class method FilePlugin.Folder_Delete(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN: String; aRecurse: Boolean := true);
begin
  var lVal := aServices.ResolveWithBase(ec, aFN);
  if System.IO.Directory.Exists(lVal) then 
  System.IO.Directory.Delete(lVal, aRecurse);
end;

class method FilePlugin.Path_Combine(aServices: IApiRegistrationServices; ec: ExecutionContext;params args: array of String): String;
begin
  if length(args) = 0 then exit nil;
  var lCurrent :=  args.FirstOrDefault;
  for i: Integer := 1 to length(args) -1 do
    lCurrent := System.IO.Path.Combine(lCurrent, args[i]);
  exit lCurrent;
end;

class method FilePlugin.Path_Resolve(aServices: IApiRegistrationServices; ec: ExecutionContext;aPath: String; aBase: String := nil): String;
begin

  if not String.IsNullOrEmpty(aBase) then begin

    aBase := aServices.ResolveWithBase(ec, aBase);
    aPath := System.IO.Path.Combine(aBase, aPath);
  end else
    aPath := aServices.ResolveWithBase(ec, aPath);
  exit System.IO.Path.GetFullPath(aPath);
end;

class method FilePlugin.Path_GetFilename(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN: String): String;
begin
  exit System.IO.Path.GetFileName(aFN);
end;

class method FilePlugin.Path_GetFileWithoutExtension(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN: String): String;
begin
  exit System.IO.Path.GetFileNameWithoutExtension(aFN);
end;

class method FilePlugin.Path_GetFilenameExtension(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN: String): String;
begin
  exit System.IO.Path.GetExtension(aFN);
end;

class method FilePlugin.Path_GetFoldername(aServices: IApiRegistrationServices; ec: ExecutionContext;aFN: String): String;
begin
  var lVal := aServices.ResolveWithBase(ec, aFN);
  exit System.IO.Path.GetDirectoryName(lVal);
end;

class method FilePlugin.File_List(aServices: IApiRegistrationServices; ec: ExecutionContext;aPathAndMask: String; aRecurse: Boolean): array of String;
begin
  var lVal := aServices.ResolveWithBase(ec, aPathAndMask);
  var res := new List<String>;
  for each el in System.IO.Directory.GetFiles(System.IO.Path.GetDirectoryName(lVal), System.IO.Path.GetFileName(lVal), 
    if aRecurse then System.IO.SearchOption.AllDirectories else System.IO.SearchOption.TopDirectoryOnly) do
    res.Add(el);
  exit res.ToArray;

end;

class method FilePlugin.Folder_List(aServices: IApiRegistrationServices; ec: ExecutionContext;aPathAndMask: String; aRecurse: Boolean): array of String;
begin
  var lVal := aServices.ResolveWithBase(ec, aPathAndMask);
  var res := new List<String>;
  for each el in System.IO.Directory.GetDirectories(lVal, '*',
    if aRecurse then System.IO.SearchOption.AllDirectories else System.IO.SearchOption.TopDirectoryOnly) do
    res.Add(el);
  exit res.ToArray;
end;

class method FilePlugin.Find(aPath: String): sequence of  String;
begin
  if aPath.IndexOfAny(['*', '?']) >= 0 then begin
    exit System.IO.Directory.EnumerateFiles(System.IO.Path.GetDirectoryName(aPath), System.IO.Path.GetFileName(aPath), System.IO.SearchOption.TopDirectoryOnly);
  end else exit  [aPath];
end;

class method FilePlugin.Folder_Move(aServices: IApiRegistrationServices; ec: ExecutionContext; aLeft: String; aRight: String);
begin
  var lVal := aServices.ResolveWithBase(ec, aLeft);
  var lVal2 := aServices.ResolveWithBase(ec, aRight);
  System.IO.Directory.Move(lVal, lVal2);
  aServices.Logger.LogMessage('Moved {0} to {1}', lVal, lVal2);
end;

end.
