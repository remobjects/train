namespace RegistryTests;

uses
  System,
  System.Diagnostics,
  System.IO,
  System.Runtime.InteropServices,
  Microsoft.Win32;

type
  Program = static class
  private

    class method Check(aCondition: Boolean; aMessage: String);
    begin
      if not aCondition then
        raise new Exception(aMessage);
    end;

    class method RunScript(aTrain: String; aSource: String; aKey: String; aDefaultSeed: String; aExpectedError: String := nil);
    begin
      var lScript := Path.Combine(Path.GetTempPath, 'train-registry-'+Guid.NewGuid.ToString('N')+'.train');
      File.WriteAllText(lScript, 'var TestKey = expand("$(TestKey)"); var DefaultSeed = expand("$(DefaultSeed)");'+Environment.NewLine+aSource);
      try
        using lProcess := new Process do begin
          lProcess.StartInfo.FileName := Environment.ProcessPath;
          lProcess.StartInfo.UseShellExecute := false;
          lProcess.StartInfo.RedirectStandardOutput := true;
          lProcess.StartInfo.RedirectStandardError := true;
          lProcess.StartInfo.ArgumentList.Add(aTrain);
          lProcess.StartInfo.ArgumentList.Add(lScript);
          lProcess.StartInfo.ArgumentList.Add('-vTestKey='+aKey);
          lProcess.StartInfo.ArgumentList.Add('-vDefaultSeed='+aDefaultSeed);
          lProcess.Start;
          var lError := lProcess.StandardError.ReadToEndAsync;
          var lOutput := lProcess.StandardOutput.ReadToEnd;
          lProcess.WaitForExit;
          lOutput := lOutput+lError.Result;
          if assigned(aExpectedError) then begin
            Check(lProcess.ExitCode <> 0, 'Expected failure: '+aExpectedError);
            Check(lOutput.Contains(aExpectedError), 'Missing diagnostic: '+aExpectedError+Environment.NewLine+lOutput);
            Check(not lOutput.Contains('ArgumentNullException'), 'Unexpected null path error: '+lOutput);
          end
          else begin
            Check(lProcess.ExitCode = 0, 'Train failed: '+lOutput);
          end;
        end;
      finally
        File.Delete(lScript);
      end;
    end;

  public

    class method Main(aArguments: array of String): Int32;
    begin
      if not RuntimeInformation.IsOSPlatform(OSPlatform.Windows) then begin
        Console.WriteLine('SKIP: Registry tests require Windows.');
        exit 0;
      end;
      try
        Check(length(aArguments) = 3, 'Arguments: Train.dll PublicApi.train CI2DelphiShared.train');
        var lSubKey := 'SOFTWARE\RemObjects\TrainRegistryTests-'+Guid.NewGuid.ToString('N');
        var lKey := 'HKEY_LOCAL_MACHINE\'+lSubKey;
        using lBase32 := RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry32) do
          using lBase64 := RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry64) do begin
            try
              using lKey32 := lBase32.CreateSubKey(lSubKey) do begin
                lKey32.SetValue('Seed', 'view32');
                lKey32.SetValue('Blank', '');
                lKey32.SetValue('', 'unnamed');
              end;
              using lKey64 := lBase64.CreateSubKey(lSubKey) do
                lKey64.SetValue('Seed', 'view64');
              var lDefaultSeed := Registry.GetValue(lKey, 'Seed', nil) as String;
              RunScript(aArguments[0], File.ReadAllText(aArguments[1]), lKey, lDefaultSeed);
              using lKey32 := lBase32.OpenSubKey(lSubKey) do
                using lKey64 := lBase64.OpenSubKey(lSubKey) do begin
                  Check(Object.Equals(lKey32.GetValue('Written'), 'write32'), 'Wrong 32-bit write destination.');
                  Check(Object.Equals(lKey64.GetValue('Written'), 'write64'), 'Wrong 64-bit write destination.');
                  var lDefault := if lDefaultSeed = 'view32' then lKey32 else lKey64;
                  var lOther := if lDefaultSeed = 'view32' then lKey64 else lKey32;
                  Check(Object.Equals(lDefault.GetValue('DefaultWrite'), 'default'), 'Default write changed views.');
                  Check(Object.Equals(lDefault.GetValue('ZeroWrite'), 'zero'), 'View 0 write changed views.');
                  Check(not assigned(lOther.GetValue('DefaultWrite')), 'Default write touched the other view.');
                end;
              RunScript(aArguments[0], 'reg.getValue(TestKey, "Seed", null, 16);', lKey, lDefaultSeed, 'Registry view must be');
              RunScript(aArguments[0], 'reg.setValue(TestKey, "Seed", "bad", 16);', lKey, lDefaultSeed, 'Registry view must be');
              RunScript(aArguments[0], 'reg.getValue("INVALID\\Key", "Seed", null, 32);', lKey, lDefaultSeed, 'full HKEY_ hive name');

              // Run the actual CI include with an isolated lookup stub. Never
              // read or change the machine's real CI2 configuration.
              var lCi := File.ReadAllText(aArguments[2]);
              var lPrefix := 'reg.getValue = function(k,n,d,v) { if (v !== 32) error("Wrong CI registry view"); return ';
              for each lValue in ['null', '""', '"   "'] do
                RunScript(aArguments[0], lPrefix+lValue+'; };'+Environment.NewLine+lCi, lKey, lDefaultSeed, 'DelphiBasePath is missing or empty in the 32-bit registry view');
              var lFolder := Path.GetTempPath.Replace('\', '\\');
              RunScript(aArguments[0], lPrefix+'"'+lFolder+'train-absent-'+Guid.NewGuid.ToString('N')+'"; };'+Environment.NewLine+lCi, lKey, lDefaultSeed, 'points to a folder that does not exist');
              RunScript(aArguments[0], lPrefix+'"'+lFolder+'"; };'+Environment.NewLine+lCi, lKey, lDefaultSeed);
              Console.WriteLine('PASS: registry API, defaults, validation, and CI Delphi diagnostics ('+RuntimeInformation.ProcessArchitecture.ToString+').');
            finally
              lBase32.DeleteSubKeyTree(lSubKey, false);
              lBase64.DeleteSubKeyTree(lSubKey, false);
            end;
          end;
        exit 0;
      except
        on E: Exception do begin
          Console.Error.WriteLine(E.ToString);
          exit 1;
        end;
      end;
    end;

  end;

end.
