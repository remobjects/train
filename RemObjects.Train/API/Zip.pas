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
  try
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
  except
    on E: System.DllNotFoundException do begin
      if RemObjects.Elements.RTL.Environment.OS ≠ RemObjects.Elements.RTL.OperatingSystem.macOS then
        raise;

      var lArgs := new List<String>;

      zip := aServices.ResolveWithBase(ec, zip);
      if File.Exists(zip) then
        File.Delete(zip);

      if String.IsNullOrEmpty(aFileMasks) then
        aFileMasks := '*'
      else
        aFileMasks := aFileMasks.Replace(',', ';');

      aInputFolder := aServices.ResolveWithBase(ec, aInputFolder);
      if not aInputFolder.EndsWith(Path.DirectorySeparatorChar) then
        aInputFolder := aInputFolder+Path.DirectorySeparatorChar;

      if aRecurse then
        lArgs.Add('-r'); // recurse only if requested

      //lArgs.Add('-q'); // -q quiet
      lArgs.Add('-X'); // -X strip extra attrs
      lArgs.Add('-9'); // -9 max compression
      lArgs.Add('-D'); // -D no separate dir entries
      lArgs.Add('-y'); // -y store symlinks as symlinks

      lArgs.Add(zip);

      // Convert masks to be relative to aInputFolder (zip’s CWD). Accept masks like "subdir/*.dll;*.txt"
      lArgs.Add(".");
      var maskList := aFileMasks.Split([';'], StringSplitOptions.RemoveEmptyEntries);
      for each mask in maskList do begin
        lArgs.Add("-i");
        lArgs.Add(mask); // zip patterns are interpreted relative to WorkingDirectory
      end;

      // If the output archive would live inside the input folder, exclude it
      var zipIsInsideInput := false;
      try
        var inputFull := Path.GetFullPath(aInputFolder);
        var zipFull := Path.GetFullPath(zip);
        zipIsInsideInput := zipFull.StartsWith(inputFull, StringComparison.OrdinalIgnoreCase);
        if zipIsInsideInput then begin
          // build relative path from input folder to the zip; add -x <relative>
          var rel := zipFull.Substring(inputFull.Length).Replace('\','/');
          if rel.StartsWith('/') then rel := rel.Substring(1);
          lArgs.Add('-x');
          lArgs.Add(rel);
        end;
      except
        // best-effort; ignore if this fails
      end;

      // Launch /usr/bin/zip with WorkingDirectory = aInputFolder
      //var psi := new System.Diagnostics.ProcessStartInfo('/usr/bin/zip');
      //psi.UseShellExecute := false;
      //psi.RedirectStandardError := true;
      //psi.RedirectStandardOutput := true;
      //psi.WorkingDirectory := aInputFolder;

      writeLn("ZIP!!!");
      writeLn(RemObjects.Elements.RTL.Process.StringForCommand("/usr/bin/zip") Parameters(lArgs));
      if RemObjects.Elements.RTL.Process.Run("/usr/bin/zip", lArgs, nil, aInputFolder, aStdOut -> begin
        writeLn("   "+aStdOut);
      end, aStdErr -> begin
        writeLn("E: "+aStdErr);
      end) ≠ 0 then
        raise new Exception($"zip failed.");
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
    if not System.IO.Directory.Exists(Path.GetDirectoryName(aDestinationFile)) then
      Directory.CreateDirectory(Path.GetDirectoryName(aDestinationFile));
    if File.Exists(aDestinationFile) then
      File.Delete(aDestinationFile);
    if not zs.ExtractFile(lEntry, aDestinationFile) then
      raise new InvalidOperationException('Error extracting '+lEntry.FilenameInZip+' to '+aDestinationFile);
  end;
end;

class method ZipRegistration.ZipExtractFiles(aServices: IApiRegistrationServices;ec: ExecutionContext; zip: String; aDestinationPath: String; aEntry: array of ZipEntryData; aFlatten: Boolean := false);
begin
  try
    aDestinationPath := aServices.ResolveWithBase(ec, aDestinationPath);
    Directory.CreateDirectory(aDestinationPath);
    using zs := ZipStorer.Open(aServices.ResolveWithBase(ec,zip), FileAccess.Read) do begin
      for each el in zs.ReadCentralDir do begin
        if not ((length(aEntry) = 0) or (aEntry.Any(a->a.name = el.FilenameInZip)) ) then continue;
        var lTargetFN: String;
        var lInputFN := el.FilenameInZip.Replace('/', Path.DirectorySeparatorChar);
        if aFlatten then
          lTargetFN := Path.Combine(aDestinationPath, Path.GetFileName(lInputFN))
        else begin
          lTargetFN := Path.Combine(aDestinationPath, lInputFN);
          if File.Exists(lTargetFN) then
            File.Delete(lTargetFN);
          if not zs.ExtractFile(el, lTargetFN) then
            raise new InvalidOperationException('Error extracting '+el.FilenameInZip+' to '+lTargetFN);
        end;
      end;
    end;
  except
    on E: System.DllNotFoundException do begin
      if RemObjects.Elements.RTL.Environment.OS ≠ RemObjects.Elements.RTL.OperatingSystem.macOS then
        raise;

      var lLArgs := new List<String>;
      lLArgs.Add("-o");
      lLArgs.Add(aServices.ResolveWithBase(ec, zip));
      lLArgs.Add("-d");
      lLArgs.Add(aServices.ResolveWithBase(ec, aDestinationPath));
      if RemObjects.Elements.RTL.Process.Run("/usr/bin/unzip", lLArgs, nil, nil, aStdOut -> begin
        //writeLn("   "+aStdOut);
      end, aStdErr -> begin
        writeLn("E: "+aStdErr);
      end) ≠ 0 then
        raise new Exception($"Unzip failed.");
    end;
  end;
end;

end.