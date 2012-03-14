namespace RemObjects.Train;

interface

uses
  System.Collections.Generic,
  System.IO,
  System.Linq, 
  NDesk.Options;


type
  ConsoleApp = class
  public
    class method Main(): Integer;
  end;

  Logger = public class(ILogger)
  private
    fWriteEnter: Boolean;
    fIndent: Integer;
    method CheckEnter;
  public
    method LogDebug(s: System.String);
    method LogWarning(s: System.String);
    method LogMessage(s: System.String);
    method LogHint(s: System.String);
    method LogInfo(s: String);
    method LogError(s: System.String);
    method Enter(aImportant: Boolean := false; aScript: String; params args: array of Object);
    method &Exit(aImportant: Boolean := false; aScript: String; aFailMode: FailMode; params args: array of Object);
  end;

implementation

method Logger.LogDebug(s: System.String);
 begin
  if not LoggerSettings. ShowDebug then exit;
  CheckEnter;
  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.DarkBlue;
  Console.WriteLine(s);
  Console.ForegroundColor := lCol;
end;

method Logger.LogError(s: System.String);
begin
  CheckEnter;
  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.Red;
  Console.WriteLine(s);
  Console.ForegroundColor := lCol;
end;

method Logger.LogHint(s: System.String);
begin
  if not LoggerSettings. ShowHint then exit;
  CheckEnter;
  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.Magenta;
  Console.WriteLine(s);
  Console.ForegroundColor := lCol;
end;

method Logger.LogMessage(s: System.String);
begin
  if not LoggerSettings. ShowMessage then exit;
  CheckEnter;
  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.Gray;
  Console.WriteLine(s);
  Console.ForegroundColor := lCol;
end;

method Logger.LogWarning(s: System.String);
begin
  if not LoggerSettings. ShowWarning then exit;
  CheckEnter;
  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.Yellow;
  Console.WriteLine(s);
  Console.ForegroundColor := lCol;
end;

method Logger.Enter(aImportant: Boolean := false; aScript: String; params args:  array of Object);
begin
  if not aImportant and not LoggerSettings.ShowDebug then exit;
  CheckEnter;
  if (length(args) = 1) and (args[0] is array of Object) then begin
    args := Array of Object(args[0]);
  end;

  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.White;
  var lArgs := String.Join(', ', args).Replace(#13#10, #10).Replace(#10, ' ');
  Console.Write(aScript+'('+lArgs+') { ... ');
                 
  Console.ForegroundColor := lCol;
  fWriteEnter := true;
  inc(fIndent);
end;

method Logger.&Exit(aImportant: Boolean := false;aScript: String; aFailMode: FailMode; params  args:array of  Object);
begin
  if not aImportant and not LoggerSettings.ShowDebug then exit;
  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.White;
  dec(fIndent);
  if fWriteEnter then begin
    fWriteEnter := false;
    Console.WriteLine(#8#8#8#8'}  ');
  end else begin
    CheckEnter;
    Console.WriteLine('} '+aScript);
  end;
  Console.ForegroundColor := lCol;
end;

method Logger.LogInfo(s: String);
begin
  LogDebug(s);
end;

method Logger.CheckEnter;
begin
  if fWriteEnter then begin
     Console.Write(#8#8#8#8'    ');
     Console.WriteLine;
     fWriteEnter := false;
  end;
  if fIndent = 0 then exit;
  var s := new String(' ', fIndent * 2);
  Console.Write(s);
end;

class method ConsoleApp.Main(): Integer;
begin
  Console.WriteLine('RemObjects Train - JavaScript-based build automation');
  Console.WriteLine('Copyright (c) RemObjects Software, 2012. All rights reserved.');
  var lLogger: ILogger := new Logger;
  var lGlobalVars := new Dictionary<String, String>;
  var lOptions := new OptionSet();
  var lShowHelp: Boolean := false;
  var lDryRun: Boolean := false;
  var lXMLOut: String := nil;
  var lWait := false;
  var lGlobalSettings: String := Path.Combine(Path.GetDirectoryName(typeOf(ConsoleApp).Assembly.Location), 'Train.ini');
  var lIncludes: List<String> := new List<String>;
  lOptions.Add('o|options=', 'Override the ini file with the global options', v-> begin lGlobalSettings := coalesce(lGlobalSettings, v); end);
  lOptions.Add('d|debug', 'Show debugging messages', v-> begin LoggerSettings.ShowDebug := assigned(v); end);
  lOptions.Add('w|warning', 'Show warning messages', v-> begin LoggerSettings.ShowWarning := assigned(v); end);
  lOptions.Add('i|hint', 'Show hint messages', v-> begin LoggerSettings.ShowDebug := assigned(v); end);
  lOptions.Add('m|message', 'Show info messages', v-> begin LoggerSettings.ShowMessage := assigned(v); end);
  lOptions.Add("h|?|help", "show help", v -> begin lShowHelp := assigned(v); end );
  lOptions.Add('v|var=', 'Defines global vars; sets {0:name}={1:value}; multiple allowed', (k, v) -> begin if assigned(k) and assigned(v) then begin
    lGlobalVars.Add(k, v); end; end);
  lOptions.Add('x|xml=', 'Write XML log to file', (v) -> begin lXMLOut := v; end);
  lOptions.Add('include=', 'Include a script', (v) -> begin if assigned(v) then lIncludes.Add(v); end);
  lOptions.Add('wait', 'Wait for a key before finishing', v-> begin lWait := assigned(v) end);
  lOptions.Add('dryrun', 'Do a script dry run (skips file/exec actions)', v->begin lDryRun := assigned(v); end);
  var lArgs: List<String>;
  try
    lArgs := lOptions.Parse(OptionCommandLine.Parse(Environment.CommandLine).Skip(1));
  except
    on  Exception  do
      lShowHelp := true;
  end;
  if  lShowHelp then begin
    Console.WriteLine('Train.exe <script.js> [options]');
    lOptions.WriteOptionDescriptions(Console.Out);
    exit 1;
  end else if lArgs.Count = 0 then begin
    lLogger.LogError('No files specified');
    exit 1;
  end;
  var lMulti: MultiLogger := new MultiLogger;
  try
    lMulti.Loggers.Add(lLogger);
    lLogger := lMulti;
    if not String.IsNullOrEmpty(lXMLOut) then begin
      lMulti.Loggers.Add(new XmlLogger(new FileStream(lXMLOut, FileMode.Create, FileAccess.Write)));
    end;
    var lRoot := new RemObjects.Train.API.Environment();
    lRoot.LoadSystem;
    if File.Exists(lGlobalSettings) then 
      lRoot.LoadIni(lGlobalSettings);
     lRoot['Train'] := Path.GetDirectoryName(typeOf(ConsoleApp).Assembly.Location);
    for each el in lGlobalVars do lRoot[el.Key] := el.Value;
    if LoggerSettings.ShowDebug then
      lLogger.LogDebug('Root Variables: '#13#10'{0}',String.Join(#13#10, lRoot.Select(a->a.Key+'='+a.Value).ToArray));

    for each el in lArgs do begin
      var lEngine := new Engine(lRoot, el);
      lEngine.Logger := lLogger;
      lEngine.DryRun := lDryRun;
      for each incl in lIncludes do
        lEngine.LoadInclude(incl);
      lEngine.Run();
      lEngine.Logger := nil;
    end;
  except
    on e: Exception do begin
      //if LoggerSettings.ShowDebug then
      //  lLogger.LogError('Exception: {0}', e.ToString)
      //else
//        lLogger.LogError('Exception: {0}', e.Message);

      exit 1;
    end;
  finally
    lMulti.Dispose;
    if lWait then begin
      Console.WriteLine('Waiting for enter to continue');
      Console.ReadLine;
    end;
  end;
end;

end.