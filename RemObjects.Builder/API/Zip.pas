namespace RemObjects.Builder.API;

interface

uses
  System.Collections.Generic,
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
    class method ZipCompress(aServices: IApiRegistrationServices; zip: string; aInputFolder: string; aFileMasks: string; aRecurse: Boolean := true);

    [WrapAs('zip.list', SkipDryRun := true)]
    class method ZipList(aServices: IApiRegistrationServices; zip: string): array of ZipEntryData;

    [WrapAs('zip.extractFile', SkipDryRun := true)]
    class method ZipExtractFile(aServices: IApiRegistrationServices; zip, aDestinationFile: string; aEntry: ZipEntryData);
    [WrapAs('zip.extractFiles', SkipDryRun := true)]
    class method ZipExtractFiles(aServices: IApiRegistrationServices; zip, aDestinationPath: string; aEntry: array of ZipEntryData; aFlatten: Boolean := false);
  end;

  ZipEntryData = public class
  private
  public
    property name: string;
    property size: Int64;
    property compressedSize: Int64;
  end;

implementation

method ZipRegistration.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterObjectValue('zip')
    .AddValue('compress', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, typeof(self), 'ZipCompress'))
    .AddValue('list', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, typeof(self), 'ZipList'))
    .AddValue('extractFile', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, typeof(self), 'ZipExtractFile'))
    .AddValue('extractFiles', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, typeof(self), 'ZipExtractFiles'))
    ;
end;

class method ZipRegistration.ZipCompress(aServices: IApiRegistrationServices; zip: string; aInputFolder: string; aFileMasks: string; aRecurse: Boolean);
begin
  zip := aServices.ResolveWithBase(zip);
  if System.IO.File.Exists(zip) then System.IO.File.Delete(zip);
  if string.IsNullOrEmpty(aFileMasks) then aFileMasks := '*';
  aInputFolder := aServices.ResolveWithBase(aInputFolder);
  if not aInputFolder.EndsWith(System.IO.Path.DirectorySeparatorChar) then 
    aInputFolder := aInputFolder + System.IO.Path.DirectorySeparatorChar;
  var lZip := new Ionic.Zip.ZipFile();
  for each el in System.IO.Directory.EnumerateFiles(aInputFolder, aFileMasks, if aRecurse then System.IO.SearchOption.AllDirectories else System.IO.SearchOption.TopDirectoryOnly) do begin
    var lFal := el;
    if lFal.StartsWith(aInputFolder) then
      lFal := lFal.Substring(aInputFolder.Length).Replace('\', '/');
    var lDir := lFal;
    
    if lDir.IndexOfAny(['/', '\']) < 0 then lDir := '' else
      lDir := lDir.Substring(0, lDir.LastIndexOfAny(['/', '\'])+1).Replace('\', '/');
    if (Length(lDir) > 0) and (lZip[lDir] = nil) then 
      lZip.AddDirectoryByName(lDir);
    lZip.AddFile(el, lDir);
  end;
  lZip.Save(zip);
end;

class method ZipRegistration.ZipList(aServices: IApiRegistrationServices; zip: string): array of ZipEntryData;
begin
  using zr := new Ionic.Zip.ZipFile(aSErvices.ResolveWithBase(zip)) do begin
    exit zr.Entries.Select(a->new ZipEntryData(name := a.FileName, compressedSize := a.CompressedSize, size := a.UncompressedSize)).ToArray;
  end;
end;

class method ZipRegistration.ZipExtractFile(aServices: IApiRegistrationServices; zip: string; aDestinationFile: string; aEntry: ZipEntryData);
begin
  using zr := new Ionic.Zip.ZipFile(aServices.ResolveWithBase(zip)) do begin
    using sr:= new System.IO.FileStream(aServices.ResolveWithBase(aDestinationFile), System.IO.FileMode.Create, System.IO.FileAccess.Write) do
      zr[aEntry.name].Extract(sr);
  end;
end;

class method ZipRegistration.ZipExtractFiles(aServices: IApiRegistrationServices; zip: string; aDestinationPath: string; aEntry: array of ZipEntryData; aFlatten: Boolean := false);
begin
  using zr := new Ionic.Zip.ZipFile(aServices.ResolveWithBase(zip)) do begin
    zr.FlattenFoldersOnExtract := aFlatten;
    if length(aEntry) = 0 then 
      zr.ExtractAll(aServices.ResolveWithBase(aDestinationPath), Ionic.Zip.ExtractExistingFileAction.OverwriteSilently)
    else begin
      var x := aServices.ResolveWithBase(aDestinationPath);
      for each el in aEntry do begin
        zr[el.name].Extract(x);
      end;
    end;
  end;
end;

end.
