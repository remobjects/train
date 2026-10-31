namespace RemObjects.Train;

uses
  System,
  System.IO,
  System.Linq,
  System.Text,
  System.Security.Cryptography,
  System.Xml.Linq,
  System.Text.RegularExpressions,
  RemObjects.Script.EcmaScript,
  RemObjects.Train.API;

type
  PipelineCache = public static class
  private

    class method Hash(aFile: String): String;
    begin
      using lHash := SHA256.Create do
        using lStream := File.OpenRead(aFile) do
          result := BitConverter.ToString(lHash.ComputeHash(lStream)).Replace('-', '').ToLowerInvariant;
    end;

    class method Files(aFolder: String): sequence of String;
    begin
      result := Directory.GetFiles(aFolder, '*', SearchOption.AllDirectories).Where(f ->
        not f.Substring(aFolder.Length).Replace('\', '/').Split('/').Any(p -> (p.ToLowerInvariant in ['.git', '.vs']) or
          ((aFolder.Replace('\', '/').Contains('/Source/')) and (p.ToLowerInvariant in ['bin', 'obj']))) and
        not f.Replace('\', '/').EndsWith('/EBuild/Source/EBuild/Info.inc', StringComparison.OrdinalIgnoreCase) and
        not f.EndsWith('.user') and not f.EndsWith('.cache') and not f.EndsWith('.DS_Store')).OrderBy(f -> f, StringComparer.Ordinal);
    end;

    class method SnapshotPath(aFolder, aRelative: String): String;
    begin
      if Path.IsPathRooted(aRelative) or aRelative.Replace('\', '/').Split('/').Any(p -> p in ['..', '.']) then
        raise new ArgumentException('Invalid library cache path.');
      result := Path.Combine(aFolder, aRelative);
    end;

    class method KeyFolder(aRoot, aKey: String): String;
    begin
      if not Regex.IsMatch(coalesce(aKey, ''), '^[a-f0-9]{64}$') then
        raise new ArgumentException('Invalid library cache key.');
      result := Path.Combine(aRoot, aKey);
    end;

  public

    // Build inputs deliberately exclude the new compiler in the fast profile. The manifest records
    // the actual producer; full builds recompile every library and promote a new immutable snapshot.
    [WrapAs('ci.cacheKey', SkipDryRun := true)]
    class method CacheKey(aServices: IApiRegistrationServices; ec: ExecutionContext; aSalt: String; aInputs: array of String): String;
    begin
      var lText := new StringBuilder(aSalt);
      for each lInput in aInputs do begin
        var lPath := aServices.ResolveWithBase(ec, lInput);
        lText.AppendLine(lInput.Replace('\', '/'));
        if File.Exists(lPath) then
          lText.AppendLine(Hash(lPath))
        else if Directory.Exists(lPath) then begin
          for each lFile in Files(lPath) do begin
            lText.AppendLine(lFile.Substring(lPath.TrimEnd(Path.DirectorySeparatorChar).Length).Replace('\', '/'));
            lText.AppendLine(Hash(lFile));
          end;
        end
        else
          lText.AppendLine('<missing>');
      end;
      using lHash := SHA256.Create do
        result := BitConverter.ToString(lHash.ComputeHash(Encoding.UTF8.GetBytes(lText.ToString))).Replace('-', '').ToLowerInvariant;
    end;

    [WrapAs('ci.cacheRestore', SkipDryRun := true)]
    class method CacheRestore(aServices: IApiRegistrationServices; ec: ExecutionContext; aRoot, aKey, aDestination: String): String;
    begin
      var lRoot := KeyFolder(aServices.ResolveWithBase(ec, aRoot), aKey);
      var lPointer := Path.Combine(lRoot, 'current.txt');
      if not File.Exists(lPointer) then
        exit;
      var lSnapshot: String;
      var lManifest: XElement;
      var lEntries: array of XElement;
      try
      var lProducer := File.ReadAllText(lPointer).Trim;
      if not Regex.IsMatch(lProducer, '^[a-f0-9]{40,64}(-[a-f0-9]{32})?$') then
        exit;
      lSnapshot := Path.Combine(lRoot, lProducer);
      var lManifestPath := Path.Combine(lSnapshot, 'manifest.xml');
      if not File.Exists(lManifestPath) then
        exit;
      lManifest := XElement.Load(lManifestPath);
      if (lManifest.Attribute('key'):Value <> aKey) or (lManifest.Attribute('producer'):Value <> lProducer.Split('-')[0]) then
        exit;
      lEntries := lManifest.Elements('file').ToArray;
      if lEntries.Length = 0 then
        exit;
      // Verify the entire snapshot before touching bootstrap or generated output directories.
      for each lEntry in lEntries do begin
        var lFile := SnapshotPath(Path.Combine(lSnapshot, 'files'), lEntry.Attribute('path').Value);
        if not File.Exists(lFile) or (Hash(lFile) <> lEntry.Attribute('sha256'):Value) then
          exit;
      end;
      except
        on E: Exception do
          exit; // A corrupt or partially removed snapshot must trigger a real build.
      end;
      var lDestination := aServices.ResolveWithBase(ec, aDestination);
      if Directory.Exists(lDestination) then
        Directory.Delete(lDestination, true);
      Directory.CreateDirectory(lDestination);
      for each lEntry in lEntries do begin
        var lRelative := lEntry.Attribute('path').Value;
        var lTarget := SnapshotPath(lDestination, lRelative);
        Directory.CreateDirectory(Path.GetDirectoryName(lTarget));
        File.Copy(SnapshotPath(Path.Combine(lSnapshot, 'files'), lRelative), lTarget);
      end;
      result := lManifest.ToString;
    end;

    [WrapAs('ci.cacheStore', SkipDryRun := true)]
    class method CacheStore(aServices: IApiRegistrationServices; ec: ExecutionContext; aRoot, aKey, aSource, aProducer, aVersion: String);
    begin
      if not Regex.IsMatch(coalesce(aProducer, ''), '^[a-f0-9]{40,64}$') then
        raise new ArgumentException('A full producer commit is required.');
      var lRoot := KeyFolder(aServices.ResolveWithBase(ec, aRoot), aKey);
      Directory.CreateDirectory(lRoot);
      var lSnapshotName := aProducer+'-'+Guid.NewGuid.ToString('N');
      var lSnapshot := Path.Combine(lRoot, lSnapshotName);
      if not Directory.Exists(lSnapshot) then begin
        var lTemp := lSnapshot+'.tmp-'+Guid.NewGuid.ToString('N');
        Directory.CreateDirectory(lTemp);
        try
          var lSource := aServices.ResolveWithBase(ec, aSource).TrimEnd(Path.DirectorySeparatorChar);
          var lManifest := new XElement('library', new XAttribute('key', aKey), new XAttribute('producer', aProducer),
            new XAttribute('version', aVersion));
          for each lFile in Directory.GetFiles(lSource, '*', SearchOption.AllDirectories).OrderBy(f -> f, StringComparer.Ordinal) do begin
            var lRelative := lFile.Substring(lSource.Length+1);
            var lTarget := SnapshotPath(Path.Combine(lTemp, 'files'), lRelative);
            Directory.CreateDirectory(Path.GetDirectoryName(lTarget));
            File.Copy(lFile, lTarget);
            lManifest.Add(new XElement('file', new XAttribute('path', lRelative), new XAttribute('sha256', Hash(lTarget))));
          end;
          if not lManifest.Elements('file').Any then
            raise new Exception('Cannot cache an empty library.');
          lManifest.Save(Path.Combine(lTemp, 'manifest.xml'));
          Directory.Move(lTemp, lSnapshot);
        finally
          if Directory.Exists(lTemp) then
            Directory.Delete(lTemp, true);
        end;
      end;
      var lPointer := Path.Combine(lRoot, 'current.txt');
      var lTempPointer := lPointer+'.'+Guid.NewGuid.ToString('N');
      File.WriteAllText(lTempPointer, lSnapshotName);
      File.Move(lTempPointer, lPointer, true);
    end;

  end;

end.
