// Exercises the registered API with a real Train process; no mocked script engine or production writes.
namespace PipelineApiTests;
uses System, System.Diagnostics, System.IO, System.Text.RegularExpressions;
type
  Program = static class
  public
    class method Main(aArgs: array of String);
    begin
      if length(aArgs) < 2 then
        raise new Exception('Pass Train.dll and Fixtures.train.');
      var lAssembly := System.Reflection.Assembly.LoadFrom(Path.Combine(Path.GetDirectoryName(aArgs[0]), 'RemObjects.Script.dll'));
      var lEngineType := lAssembly.GetType('RemObjects.Script.EcmaScriptComponent');
      using lEngine := Activator.CreateInstance(lEngineType) as IDisposable do begin
        var lCompiler := lEngineType.GetField('fCompiler', System.Reflection.BindingFlags.Instance or System.Reflection.BindingFlags.NonPublic).GetValue(lEngine);
        for i: Integer := 2 to aArgs.Length-1 do begin
          lCompiler.GetType.GetMethod('Parse', [typeOf(String), typeOf(String)]).Invoke(lCompiler, [aArgs[i], File.ReadAllText(aArgs[i])]);
          Console.WriteLine('PASS: Train parser '+Path.GetFileName(aArgs[i]));
        end;
      end;
      var lFolder := Path.Combine(Path.GetTempPath, 'train-pipeline-'+Guid.NewGuid.ToString('N'));
      Directory.CreateDirectory(lFolder);
      try
        var lScript := Path.Combine(lFolder, 'Fixture.train');
        File.Copy(aArgs[1], lScript);
        Run(aArgs[0], lScript, lFolder, false);
        File.WriteAllText(lScript, 'ci.artifactReady("Dry.zip", "compiler");');
        Run(aArgs[0], lScript, lFolder, true);
        Console.WriteLine('PASS: Train cache cold/warm/invalidation/corruption/provenance, safe markers and dry-run suppression');
      finally
        Directory.Delete(lFolder, true);
      end;
    end;
    class method Run(aTrain, aScript, aFolder: String; aDry: Boolean);
    begin
      using lProcess := new Process do begin
        lProcess.StartInfo.FileName := Environment.ProcessPath;
        lProcess.StartInfo.WorkingDirectory := aFolder;
        lProcess.StartInfo.UseShellExecute := false;
        lProcess.StartInfo.RedirectStandardOutput := true;
        lProcess.StartInfo.RedirectStandardError := true;
        lProcess.StartInfo.ArgumentList.Add(aTrain);
        lProcess.StartInfo.ArgumentList.Add(aScript);
        if aDry then lProcess.StartInfo.ArgumentList.Add('--dryrun');
        lProcess.Start;
        var lErrors := lProcess.StandardError.ReadToEndAsync;
        var lOutput := lProcess.StandardOutput.ReadToEnd;
        lProcess.WaitForExit;
        lOutput := lOutput+lErrors.Result;
        if (lProcess.ExitCode <> 0) or
           (not aDry and not lOutput.Contains('PIPELINE_TESTS_PASSED')) or
           (Regex.Matches(lOutput, '::CI2:ARTIFACT\|').Count <> (if aDry then 0 else 1)) then
          raise new Exception(lOutput);
      end;
    end;
  end;
end.
