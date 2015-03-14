namespace RemObjects.Train.API;

interface

uses
  System.Collections.Generic,
  RemObjects.Script.EcmaScript,
  System.Linq,
  System.IO,
  System.IO.Compression,
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
    class method ZipExtractFiles(aServices: IApiRegistrationServices; ec: ExecutionContext; zip, aDestinationPath: String; aEntry: array of ZipEntryData := nil; aFlatten: Boolean := false);
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
    .AddValue('compress', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'ZipCompress'))
    .AddValue('list', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'ZipList'))
    .AddValue('extractFile', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'ZipExtractFile'))
    .AddValue('extractFiles', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(self), 'ZipExtractFiles'))
    ;
end;

class method ZipRegistration.ZipCompress(aServices: IApiRegistrationServices; ec: ExecutionContext; zip: String; aInputFolder: String; aFileMasks: String; aRecurse: Boolean);
begin
  
  zip := aServices.ResolveWithBase(ec,zip);
  if System.IO.File.Exists(zip) then System.IO.File.Delete(zip);
  if String.IsNullOrEmpty(aFileMasks) then aFileMasks := '*';
  aFileMasks := aFileMasks.Replace(',', ';');
  aInputFolder := aServices.ResolveWithBase(ec,aInputFolder);
  if not aInputFolder.EndsWith(System.IO.Path.DirectorySeparatorChar) then 
    aInputFolder := aInputFolder + System.IO.Path.DirectorySeparatorChar;
  using sz := ZipStorer.Create(zip, '') do begin
    for each mask in aFileMasks.Split([';'], StringSplitOptions.RemoveEmptyEntries) do begin
      var lRealInputFolder := aInputFolder;
      var lRealMask := mask;
      var lIdx := lRealMask.LastIndexOfAny(['/', '\']);
      if lIdx <> -1 then begin
        lRealInputFolder := Path.Combine(lRealInputFolder, lRealMask.Substring(0, lIdx));
        lRealMask := lRealMask.Substring(lIdx+1);
      end;

      for each el in System.IO.Directory.EnumerateFiles(lRealInputFolder, lRealMask, if aRecurse then System.IO.SearchOption.AllDirectories else System.IO.SearchOption.TopDirectoryOnly) do begin
        sz.AddFile(ZipStorer.Compression.Deflate, el, el.Substring(aInputFolder.Length), '', $81ED);
      end;
    end;
  end;
end;

class method ZipRegistration.ZipList(aServices: IApiRegistrationServices; ec: ExecutionContext; zip: String): array of ZipEntryData;
begin
  using zs := ZipStorer.Open(aServices.ResolveWithBase(ec,zip), FileAccess.Read) do begin
    exit zs.ReadCentralDir.Select(a->new ZipEntryData(
      name := a.FilenameInZip, 
      compressedSize := a.CompressedSize, 
      size := a.FileSize)).ToArray;
  end;
end;

class method ZipRegistration.ZipExtractFile(aServices: IApiRegistrationServices; ec: ExecutionContext; zip: String; aDestinationFile: String; aEntry: ZipEntryData);
begin
  aDestinationFile := aServices.ResolveWithBase(ec, aDestinationFile);
  using zs := ZipStorer.Open(aServices.ResolveWithBase(ec,zip), FileAccess.Read) do begin
    var lEntry := zs.ReadCentralDir().FirstOrDefault(a -> a.FilenameInZip = aEntry:name);
    if lEntry.FilenameInZip = nil then raise new ArgumentException('No such file in zip: '+aEntry:name);
    if aDestinationFile.EndsWith('/') or aDestinationFile.EndsWith('\') then
      aDestinationFile := Path.Combine(aDestinationFile, Path.GetFileName(aEntry.name));
    if not zs.ExtractFile(lEntry, aDestinationFile) then
      raise new InvalidOperationException('Error extracting '+lEntry.FilenameInZip);
  end;
end;

class method ZipRegistration.ZipExtractFiles(aServices: IApiRegistrationServices;ec: ExecutionContext;  zip: String; aDestinationPath: String; aEntry: array of ZipEntryData; aFlatten: Boolean := false);
begin
  aDestinationPath := aServices.ResolveWithBase(ec, aDestinationPath);
  using zs := ZipStorer.Open(aServices.ResolveWithBase(ec,zip), FileAccess.Read) do begin
    for each el in zs.ReadCentralDir do begin
      if not ((length(aEntry) = 0) or (aEntry.Any(a->a.name = el.FilenameInZip)) ) then continue;
      var lTargetFN: String;
      var lInputFN := el.FilenameInZip.Replace('/', Path.DirectorySeparatorChar);
      if aFlatten then
        lTargetFN := Path.Combine(aDestinationPath, Path.GetFileName(lInputFN))
      else begin
        lTargetFN := Path.Combine(aDestinationPath, lInputFN);
        if not zs.ExtractFile(el, lTargetFN) then
          raise new InvalidOperationException('Error extracting '+el.FilenameInZip);
      end;
    end;
  end;
end;

end.
