namespace MilestoneTests;

uses
  System,
  System.Diagnostics,
  System.IO,
  System.Linq,
  System.Text.RegularExpressions,
  System.Xml.Linq;

type
  Program = static class
  private

    class method Check(aCondition: Boolean; aMessage: String);
    begin
      if not aCondition then
        raise new Exception(aMessage);
    end;

  public

    class method Main(aArguments: array of String): Int32;
    begin
      try
        Check(length(aArguments) = 1, 'Pass the rebuilt Train.dll path.');
        var lFolder := Path.Combine(Path.GetTempPath, 'train-milestones-'+Guid.NewGuid.ToString('N'));
        Directory.CreateDirectory(lFolder);
        try
          var lScript := Path.Combine(lFolder, 'Milestones.train');
          var lXml := Path.Combine(lFolder, 'Milestones.xml');
          File.WriteAllText(lScript, 'ci.milestone("  Downloading prerequisites  "); ci.milestone(""); ci.milestone("   "); ci.milestone(null); ci.milestone("Creating setups");');
          var lExpected := ['::CI2:MILESTONE|Downloading prerequisites', '::CI2:MILESTONE|Creating setups'];
          for each lMode in ['', '--dryrun', '-d'] do begin
            using lProcess := new Process do begin
              lProcess.StartInfo.FileName := Environment.ProcessPath;
              lProcess.StartInfo.UseShellExecute := false;
              lProcess.StartInfo.RedirectStandardOutput := true;
              lProcess.StartInfo.RedirectStandardError := true;
              lProcess.StartInfo.ArgumentList.Add(aArguments[0]);
              lProcess.StartInfo.ArgumentList.Add(lScript);
              lProcess.StartInfo.ArgumentList.Add('-x='+lXml);
              lProcess.StartInfo.ArgumentList.Add('--width=200');
              if length(lMode) > 0 then
                lProcess.StartInfo.ArgumentList.Add(lMode);
              lProcess.Start;
              var lErrors := lProcess.StandardError.ReadToEndAsync;
              var lOutput := lProcess.StandardOutput.ReadToEnd;
              lProcess.WaitForExit;
              lOutput := lOutput+lErrors.Result;
              Check(lProcess.ExitCode = 0, 'Train failed: '+lOutput);
              var lMarkers := Regex.Matches(lOutput, '::CI2:MILESTONE\|[^\r\n]*');
              Check(lMarkers.Count = 2, 'Expected exactly two console markers: '+lOutput);
              for i: Integer := 0 to 1 do
                Check(lMarkers[i].Value.Trim = lExpected[i], 'Unexpected console milestone: '+lMarkers[i].Value);
              var lMessages := XDocument.Load(lXml).Descendants('message').Select(a -> a.Value).Where(a -> a.StartsWith('::CI2:MILESTONE|')).ToArray;
              Check(lMessages.SequenceEqual(lExpected), 'Unexpected XML milestones.');
              Console.WriteLine('PASS: milestone registration, trimming, empty/null suppression, console and XML ('+lMode+').');
            end;
          end;
        finally
          Directory.Delete(lFolder, true);
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
