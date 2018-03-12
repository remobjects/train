namespace RemObjects.Train.API;

uses
  RemObjects.Train,
  System.Threading,
  RemObjects.Script.EcmaScript,
  RemObjects.Script.EcmaScript.Internal,
  System.Text,
  System.Text.RegularExpressions,
  System.Xml.Linq,
  System.Linq,
  System.IO,
  System.Runtime.InteropServices;

type
  [PluginRegistration]
  EBuildPlugin = public class(IPluginRegistration)
  public

    method Register(aServices: IApiRegistrationServices);
    begin
      //fServices := aServices;
      var lEBuildObject := aServices.RegisterObjectValue('ebuild');
      lEBuildObject.AddValue('runCustomEBuild', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(EBuildPlugin), 'runCustomEBuild'));
      lEBuildObject.AddValue('runEBuild', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(EBuildPlugin), 'runEBuild'));

      lEBuildObject.AddValue('build', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(EBuildPlugin), 'build'));
      lEBuildObject.AddValue('rebuild', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(EBuildPlugin), 'rebuild'));
      lEBuildObject.AddValue('clean', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(EBuildPlugin), 'clean'));
    end;

    [WrapAs('ebuild.runCustomEBuild', SkipDryRun := false)]
    class method runCustomEBuild(aServices: IApiRegistrationServices; ec: ExecutionContext; aEBuildExe: String; aProject: String; aOtherParameters: String): Boolean;
    begin
      result := doRunCustomEBuild(aServices, ec, aEBuildExe, aProject, aOtherParameters);
    end;

    [WrapAs('ebuild.runEBuild', SkipDryRun := false)]
    class method runEBuild(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOtherParameters: String): Boolean;
    begin
      var lEBuildExe := FindEBuildExe();
      if not assigned(lEBuildExe) then
        raise new Exception("EBuild.exe culd not be located.");
      result := doRunCustomEBuild(aServices, ec, lEBuildExe, aProject, aOtherParameters);
    end;

    [WrapAs('ebuild.build', SkipDryRun := false)]
    class method build(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOtherParameters: String): Boolean;
    begin
      result := runEBuild(aServices, ec, aProject, ("--build "+coalesce(aOtherParameters, "")).Trim);
    end;

    [WrapAs('ebuild.rebuild', SkipDryRun := false)]
    class method rebuild(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOtherParameters: String): Boolean;
    begin
      result := runEBuild(aServices, ec, aProject, ("--rebuild --no-cache "+coalesce(aOtherParameters, "")).Trim);
    end;

    [WrapAs('ebuild.clean', SkipDryRun := false)]
    class method clean(aServices: IApiRegistrationServices; ec: ExecutionContext; aProject: String; aOtherParameters: String): Boolean;
    begin
      result := runEBuild(aServices, ec, aProject, ("--clean "+coalesce(aOtherParameters, "")).Trim);
    end;

  private

    // cloned from EBuild itself, which we don't want to reference in  Ttain
    class method FindEBuildExe: nullable String;
    begin

      if (RemObjects.Elements.RTL.Environment.OS = RemObjects.Elements.RTL.OperatingSystem.macOS) /*or (Environment.OS = OperatingSystem.Linux)*/ then begin

        var lPath := "/usr/local/bin/ebuild";
        if File.Exists(lPath) then begin
          var lEBuildScript := File.ReadAllText(lPath).Trim(); //mono "/Users/mh/Code/Elements/Bin/EBuild.exe" "$@"
          if lEBuildScript.StartsWith('mono "') and lEBuildScript.EndsWith('" "$@"') then begin
            lPath := lEBuildScript.Substring(6, length(lEBuildScript)-12);
            if File.Exists(lPath) then
              exit lPath;
          end;
        end;

      end
      else if defined("ECHOES") and (RemObjects.Elements.RTL.Environment.OS = RemObjects.Elements.RTL.OperatingSystem.Windows) then begin
        var lKey := Microsoft.Win32.Registry.LocalMachine.OpenSubKey("Software\Wow6432Node\RemObjects\Elements");
        if assigned(lKey) then begin
          if assigned(lKey.GetValue("InstallDir"):ToString) then begin
            var lPath := Path.Combine(lKey.GetValue("InstallDir"):ToString, "Bin", "EBuild.exe");
            if assigned(lPath) and File.Exists(lPath) then
              exit lPath;
          end;
          var lPath := lKey.GetValue("EBuild"):ToString;
          if assigned(lPath) and File.Exists(lPath) then
            exit lPath;
        end;
        lKey := Microsoft.Win32.Registry.LocalMachine.OpenSubKey("Software\RemObjects\Elements");
        if (lKey <> nil) then begin
          if assigned(lKey.GetValue("InstallDir"):ToString) then begin
            var lPath := Path.Combine(lKey.GetValue("InstallDir"):ToString, "Bin", "EBuild.exe");
            if assigned(lPath) and File.Exists(lPath) then
              exit lPath;
          end;
          var lPath := lKey.GetValue("EBuild"):ToString;
          if assigned(lPath) and File.Exists(lPath) then
            exit lPath;
        end;
      end;

    end;

    class method doRunCustomEBuild(aServices: IApiRegistrationServices; ec: ExecutionContext; aEBuildExe: String; aProject: String; aOtherParameters: String): Boolean;
    begin
      var lSuccess := true;
      var lLogger := new DelayedLogger();
      aServices.Engine.Logger.Enter(true,'ebuild', (aProject+" "+aOtherParameters).Trim);
      try

        if aServices.Engine.DryRun then begin
          aServices.Engine.Logger.LogMessage('Dry run.');
          exit true;
        end;

        var sb := new System.Text.StringBuilder;
        var lExitCode := Shell.ExecuteProcess(aEBuildExe, '"'+aProject+'" '+aOtherParameters, aServices.Engine.WorkDir, false , a-> begin
                                                                                                    if assigned(a) then begin
                                                                                                      locking sb do sb.AppendLine(a);
                                                                                                      lLogger.LogError(a);
                                                                                                      if aServices.Engine.LiveOutput then
                                                                                                        aServices.Engine.Logger.LogLive("(stderr) "+a);
                                                                                                    end;
                                                                                                  end,
                                                                                              a-> begin
                                                                                                    if assigned(a) then begin
                                                                                                      locking sb do sb.AppendLine(a);
                                                                                                      if a:StartsWith("E:") then
                                                                                                        lLogger.LogError("Error: "+a);
                                                                                                      if aServices.Engine.LiveOutput then
                                                                                                        aServices.Engine.Logger.LogLive(a);
                                                                                                    end;
                                                                                                  end, [], nil);

        lLogger.LogInfo(sb.ToString);
        if lExitCode ≠ 0 then begin

          //var lErrors := new System.Text.StringBuilder;
          //for each l in sb.ToString.Split(#10) do begin
            //l := l.Trim();
            //if l.StartsWith("E:") then
              //lErrors.AppendLine("Error: "+l.Substring(2).Trim());
          //end;

          lSuccess := false;
          //aServices.Engine.Logger.LogError(lErrors.ToString);
          //locking sb do aServices.Engine.Logger.LogMessage('Output: '#13#10+sb.ToString);
          raise new Exception("EBuild failed with exit code "+lExitCode);
        end;

        //locking sb do aServices.Engine.Logger.LogInfo('Output: '#13#10+sb.ToString);
      //except
        //on e: Exception do begin
          //aServices.Engine.Logger.LogError('Error calling Process.Execute: '+e.Message);
          //writeLn(e.ToString());
          //raise new AbortException;
        //end;
      finally
        lLogger.Replay(aServices.Logger);
        aServices.Engine.Logger.Exit(true,String.Format('ebuild({0})', aProject), if not lSuccess then RemObjects.Train.FailMode.Yes else RemObjects.Train.FailMode.No);
      end;

    end;

  end;

end.