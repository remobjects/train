namespace RemObjects.Train.API;

interface

uses
  System.Collections.Generic,
  RemObjects.Script.EcmaScript,
  System.Linq,
  System.Text;

type
  [PluginRegistration]
  ZipRegistration = public class(IPluginRegistration)
  private
  protected
  public
    method &Register(aServices: IApiRegistrationServices);
    [WrapAs('zip.compress', SkipDryRun := true)]
    class method ZipCompress(aServices: IApiRegistrationServices; ec: ExecutionContext; zip: String; aInputFolder: String; aFileMasks: String; aRecurse: Boolean := true);

    [WrapAs('zip.list', SkipDryRun := true, Important := false)]
    class method ZipList(aServices: IApiRegistrationServices; ec: ExecutionContext; zip: String): array of ZipEntryData;

    [WrapAs('zip.extractFile', SkipDryRun := true)]
    class method ZipExtractFile(aServices: IApiRegistrationServices; ec: ExecutionContext; zip, aDestinationFile: String; aEntry: ZipEntryData);
    [WrapAs('zip.extractFiles', SkipDryRun := true)]
    class method ZipExtractFiles(aServices: IApiRegistrationServices; ec: ExecutionContext; zip, aDestinationPath: String; aEntry: array of ZipEntryData; aFlatten: Boolean := false);
  end;

  ZipEntryData = public class
  private
  public
    property name: String;
    property size: Int64;
    property compressedSize: Int64;
  end;

implementation

method ZipRegistration.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterObjectValue('zip')
    .AddValue('compress', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(self), 'ZipCompress'))
    .AddValue('list', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(self), 'ZipList'))
    .AddValue('extractFile', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(self), 'ZipExtractFile'))
    .AddValue('extractFiles', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(self), 'ZipExtractFiles'))
    ;
end;

class method ZipRegistration.ZipCompress(aServices: IApiRegistrationServices; ec: ExecutionContext; zip: String; aInputFolder: String; aFileMasks: String; aRecurse: Boolean);
begin
  zip := aServices.ResolveWithBase(ec,zip);
  //if System.IO.File.Exists(zip) then System.IO.File.Delete(zip);
  if String.IsNullOrEmpty(aFileMasks) then aFileMasks := '*';
  aFileMasks := aFileMasks.Replace(',', ';');
  aInputFolder := aServices.ResolveWithBase(ec,aInputFolder);
  if not aInputFolder.EndsWith(System.IO.Path.DirectorySeparatorChar) then 
    aInputFolder := aInputFolder + System.IO.Path.DirectorySeparatorChar;
  var lZip := new Ionic.Zip.ZipFile();
  for each mask in aFileMasks.Split([';'], StringSplitOptions.RemoveEmptyEntries) do 
  for each el in System.IO.Directory.EnumerateFiles(aInputFolder, mask, if aRecurse then System.IO.SearchOption.AllDirectories else System.IO.SearchOption.TopDirectoryOnly) do begin
    var lFal := el;
    if lFal.StartsWith(aInputFolder) then
      lFal := lFal.Substring(aInputFolder.Length).Replace('\', '/');
    var lDir := lFal;
    
    if lDir.IndexOfAny(['/', '\']) < 0 then lDir := '' else
      lDir := lDir.Substring(0, lDir.LastIndexOfAny(['/', '\'])+1).Replace('\', '/');
    if (length(lDir) > 0) and (lZip[lDir] = nil) then 
      lZip.AddDirectoryByName(lDir);
    lZip.AddFile(el, lDir);
  end;
  lZip.Save(zip);
end;

class method ZipRegistration.ZipList(aServices: IApiRegistrationServices; ec: ExecutionContext; zip: String): array of ZipEntryData;
begin
  using zr := new Ionic.Zip.ZipFile(aServices.ResolveWithBase(ec,zip)) do begin
    exit zr.Entries.Select(a->new ZipEntryData(name := a.FileName, compressedSize := a.CompressedSize, size := a.UncompressedSize)).ToArray;
  end;
end;

class method ZipRegistration.ZipExtractFile(aServices: IApiRegistrationServices; ec: ExecutionContext; zip: String; aDestinationFile: String; aEntry: ZipEntryData);
begin
  using zr := new Ionic.Zip.ZipFile(aServices.ResolveWithBase(ec,zip)) do begin
    using sr:= new System.IO.FileStream(aServices.ResolveWithBase(ec,aDestinationFile), System.IO.FileMode.Create, System.IO.FileAccess.Write) do
      zr[aEntry.name].Extract(sr);
  end;
end;

class method ZipRegistration.ZipExtractFiles(aServices: IApiRegistrationServices;ec: ExecutionContext;  zip: String; aDestinationPath: String; aEntry: array of ZipEntryData; aFlatten: Boolean := false);
begin
  using zr := new Ionic.Zip.ZipFile(aServices.ResolveWithBase(ec,zip)) do begin
    zr.FlattenFoldersOnExtract := aFlatten;
    if length(aEntry) = 0 then 
      zr.ExtractAll(aServices.ResolveWithBase(ec,aDestinationPath), Ionic.Zip.ExtractExistingFileAction.OverwriteSilently)
    else begin
      var x := aServices.ResolveWithBase(ec,aDestinationPath);
      for each el in aEntry do begin
        zr[el.name].Extract(x);
      end;
    end;
  end;
end;

end.
