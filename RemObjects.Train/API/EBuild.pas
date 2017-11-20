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
      aServices.RegisterObjectValue('ebuild').AddValue('runCustomEBuild', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(EBuildPlugin), 'runCustomEBuild'));
    end;

    [WrapAs('ebuild.runCustomEBuild', SkipDryRun := false)]
    class method runCustomEBuild(aServices: IApiRegistrationServices; ec: ExecutionContext; aEBuildExe: String; aProject: String; aOtherParameters: String): Boolean;
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