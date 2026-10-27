namespace GacTests;

uses
  System,
  System.Reflection,
  System.Runtime.InteropServices,
  RemObjects.Train.API;

type
  Program = static class
  public

    class method Main(aArguments: array of String): Int32;
    begin
      if not RuntimeInformation.IsOSPlatform(OSPlatform.Windows) then begin
        Console.WriteLine('SKIP: Fusion/GAC integration requires Windows with .NET Framework 4.');
        exit 0;
      end;

      try
        if (length(aArguments) <> 1) or not (aArguments[0] in ['cache', 'list']) then
          raise new ArgumentException('Run with cache or list, each in a fresh process.');

        if aArguments[0] = 'cache' then begin
          // Exercise the install/uninstall entry point without modifying the GAC.
          var lCalled := false;
          var lCallback: Action<IAssemblyCache> := aCache -> begin
            if not assigned(aCache) then
              raise new Exception('CreateAssemblyCache returned no cache.');
            lCalled := true;
          end;
          var lMethod := typeOf(MSWinGacUtil).GetMethod('WithCache', BindingFlags.Static or BindingFlags.NonPublic);
          lMethod.Invoke(nil, [lCallback]);
          if not lCalled then
            raise new Exception('The cache callback was not invoked.');
        end;

        var lCount := 0;
        for each lName in MSWinGacUtil.List(nil) do begin
          if length(lName) = 0 then
            raise new Exception('GAC enumeration returned an empty assembly name.');
          inc(lCount);
        end;
        if lCount = 0 then
          raise new Exception('Expected Framework assemblies in the GAC.');

        // A nonempty filter also exercises CreateAssemblyNameObject. Repeated
        // calls verify that the retained Fusion handle remains usable.
        for i: Integer := 0 to 2 do
          for each lName in MSWinGacUtil.List('Train.Gac.Probe.'+Guid.NewGuid.ToString('N')) do
            raise new Exception('Unexpected match for a unique assembly name: '+lName);

        Console.WriteLine('PASS: '+aArguments[0]+' cold start and GAC enumeration ('+RuntimeInformation.ProcessArchitecture.ToString+', '+lCount.ToString+' assemblies).');
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
