namespace RemObjects.Train;

interface

uses
  RemObjects.Script.EcmaScript,
  System.Collections.Generic,
  System.IO,
  System.Linq,
  NDesk.Options;


type
  ConsoleApp = class
  public
    class method Main(args: array of String): Integer;
    class property ShowColors: Boolean := true;
    class method StripQuotes(s: String): String;
  end;

  Logger = public class(ILogger)
  private
    fWriteEnter: Boolean;
    fIndent: Integer;
    method CheckEnter;
    method CleanedString(s: String): String;
  public
    method LogDebug(s: System.String);
    method LogWarning(s: System.String);
    method LogMessage(s: System.String);
    method LogHint(s: System.String);
    method LogInfo(s: String);
    method LogError(s: System.String);
    method LogLive(s: String);
    property InIgnore: Boolean;
    method Enter(aImportant: Boolean := false; aScript: String; params args: array of Object);
    method &Exit(aImportant: Boolean := false; aScript: String; aFailMode: FailMode; aReturn: Object);
    method &Write; empty;

    property MaxWidth: Integer read begin
      result := 80;
      try
        result := Console.WindowWidth-(2*fIndent)-1;
      except
        on E: IOException do;
      end;
      if result < 10 then result := 10;
    end;

  end;

implementation

method Logger.CleanedString(s: String): String;
begin
  var p := s.IndexOf(#10);
  if p > 0 then
    s := s.Substring(p)+"...";
  s := s.Trim();
  if length(s) > 50 then
    s := s.SubString(0, 50)+"...";
  for i: Int32 := 0 to length(s)-1 do
    if s[i] < #32 then
      s := (s as RemObjects.Elements.RTL.String).Replace(i, 1, ".");
  result := s;
end;

method Logger.LogDebug(s: System.String);
 begin
  if not LoggerSettings.ShowDebug then
    exit;
  CheckEnter;

   if length(s) > MaxWidth then
     s := s.Substring(0, MaxWidth-3)+'...';

  if ConsoleApp.ShowColors then begin
    var lCol := Console.ForegroundColor;
    Console.ForegroundColor := ConsoleColor.DarkBlue;
    Console.WriteLine(s);
    Console.ForegroundColor := lCol;
  end
  else
    Console.WriteLine(s);
end;

method Logger.LogError(s: System.String);
begin
  CheckEnter;

  if length(s) > MaxWidth then
    s := s.Substring(0, MaxWidth-3)+'...';

  if ConsoleApp.ShowColors then begin
    var lCol := Console.ForegroundColor;
    if InIgnore then
      Console.ForegroundColor := ConsoleColor.DarkRed
    else
      Console.ForegroundColor := ConsoleColor.Red;
    Console.WriteLine(s);
    Console.ForegroundColor := lCol;
  end
  else
    Console.WriteLine(s);
end;

method Logger.LogHint(s: System.String);
begin
  if not LoggerSettings.ShowHint then
    exit;
  CheckEnter;

  if length(s) > MaxWidth then
    s := s.Substring(0, MaxWidth-3)+'...';

  if ConsoleApp.ShowColors then begin
    var lCol := Console.ForegroundColor;
    Console.ForegroundColor := ConsoleColor.Magenta;
    Console.WriteLine(s);
    Console.ForegroundColor := lCol;
  end
  else
    Console.WriteLine(s);
end;

method Logger.LogMessage(s: System.String);
begin
  if not LoggerSettings.ShowMessage then
    exit;
  CheckEnter;

  if length(s) > MaxWidth then
    s := s.Substring(0, MaxWidth-3)+'...';

  if ConsoleApp.ShowColors then begin
    var lCol := Console.ForegroundColor;
    Console.ForegroundColor := ConsoleColor.Gray;
    Console.WriteLine(s);
    Console.ForegroundColor := lCol;
  end
  else
    Console.WriteLine(s);
end;

method Logger.LogWarning(s: System.String);
begin
  if not LoggerSettings. ShowWarning then
    exit;

  if length(s) > MaxWidth then
    s := s.Substring(0, MaxWidth-3)+'...';

  if ConsoleApp.ShowColors then begin
    CheckEnter;
    var lCol := Console.ForegroundColor;
    Console.ForegroundColor := ConsoleColor.Yellow;
    Console.WriteLine(s);
    Console.ForegroundColor := lCol;
  end
  else
    Console.WriteLine(s);
end;

method Logger.Enter(aImportant: Boolean := false; aScript: String; params args:  array of Object);
begin
  if not aImportant and not LoggerSettings.ShowDebug then exit;
  CheckEnter;
  if (length(args) = 1) and (args[0] is array of Object) then begin
    args := Array of Object(args[0]);
  end;

  var lCol: ConsoleColor;
  if ConsoleApp.ShowColors then begin
    lCol := Console.ForegroundColor;
    Console.ForegroundColor := ConsoleColor.White;
  end;

  var lMaxWidth := MaxWidth-aScript.Length-10;
  if lMaxWidth < 10 then lMaxWidth := 10;

  var lArgs := '';
  if length(args) > 0 then
    for each a in args do begin
      var s := CleanedString(coalesce(a:ToString, 'null'));
      if length(lArgs) > 0 then lArgs := lArgs+', ';
      lArgs := lArgs+s;
      if length(lArgs) > lMaxWidth then begin
        lArgs := lArgs.Substring(0, lMaxWidth-3)+'...';
        break;
      end;
    end;
  Console.Write(aScript+'('+lArgs+') { ... ');
  Console.Out.Flush();

  if ConsoleApp.ShowColors then begin
    Console.ForegroundColor := lCol;
  end;
  fWriteEnter := true;
  inc(fIndent);
end;

method Logger.&Exit(aImportant: Boolean := false;aScript: String; aFailMode: FailMode; aReturn: Object);
begin
  if not aImportant and not LoggerSettings.ShowDebug then exit;
  var lCol: ConsoleColor;
  if ConsoleApp.ShowColors then begin
    lCol := Console.ForegroundColor;
    Console.ForegroundColor := ConsoleColor.White;
  end;
  if fIndent > 0 then dec(fIndent);
  var lRet:= '';
  if (aReturn <> nil) and (aReturn <> Undefined.Instance) then begin
    var s := CleanedString(aReturn.ToString);
    if length(s) > 50 then s := s.Substring(0, 47)+'...';
    lRet := ': '+s;
  end
  else begin
    lRet := ' ';
  end;
  if fWriteEnter then begin
    fWriteEnter := false;

    try
      if Console.CursorLeft < Console.WindowWidth then
        Console.WriteLine(#8#8#8#8'} '+lRet) // this crashes (on Mac, at least) if the wijdow was resized smaller than current cursorX
      else
        Console.WriteLine('} '+lRet);
    except
      on E: IOException do
        Console.WriteLine('} '+lRet);
    end;

  end else begin
    CheckEnter;
    Console.WriteLine('} '+aScript+lRet);
  end;
  if ConsoleApp.ShowColors then begin
    Console.ForegroundColor := lCol;
  end;
end;

method Logger.LogInfo(s: String);
begin
  LogDebug(s);
end;

method Logger.LogLive(s: String);
begin
  LogMessage(s);
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

class method ConsoleApp.Main(args: array of String): Integer;
begin
  Console.WriteLine('RemObjects Train - JavaScript-based build automation');
  Console.WriteLine('Copyright 2013-2018 RemObjects Software, LLC. All rights reserved.');
  var lLogger: ILogger := new Logger;
  var lGlobalVars := new Dictionary<String, String>;
  var lOptions := new OptionSet();
  var lShowHelp: Boolean := false;
  var lDryRun: Boolean := false;
  var lXMLOut: String := nil;
  var lHtmlOut: String := nil;
  var lXSLT: String := nil;
  var lLogFNEnter: Boolean := true;
  var lPluginFolder: String := nil;
  var lWait := false;
  var lLiveOutput := false;
  var lGlobalSettings: String := Path.Combine(Path.GetDirectoryName(typeOf(ConsoleApp).Assembly.Location), 'Train.ini');
  var lIncludes: List<String> := new List<String>;
  lOptions.Add('o|options=', 'Override the ini file with the global options', v-> begin lGlobalSettings := coalesce(lGlobalSettings, v); end);
  lOptions.Add('c|colors', 'Use colors', v-> begin ShowColors := assigned(v); end);
  lOptions.Add('d|debug', 'Show debugging messages', v-> begin LoggerSettings.ShowDebug := assigned(v); end);
  lOptions.Add('w|warning', 'Show warning messages', v-> begin LoggerSettings.ShowWarning := assigned(v); end);
  lOptions.Add('i|hint', 'Show hint messages', v-> begin LoggerSettings.ShowDebug := assigned(v); end);
  lOptions.Add('m|message', 'Show info messages', v-> begin LoggerSettings.ShowMessage := assigned(v); end);
  lOptions.Add("h|?|help", "show help", v -> begin lShowHelp := assigned(v); end );
  lOptions.Add('v|var=', 'Defines global vars; sets {0:name}={1:value}; multiple allowed', (k, v) -> begin if assigned(k) and assigned(v) then begin
    lGlobalVars.Add(k, StripQuotes(v)); end; end);
  lOptions.Add('xslt=', 'Override XSLT for html output', (v) -> begin lXSLT := v; end);
  lOptions.Add('t|html=', 'Write HTML log to file ', (v) -> begin lHtmlOut := v; end);
  lOptions.Add('x|xml=', 'Write XML log to file', (v) -> begin lXMLOut := v; end);
  lOptions.Add('plugin=', 'use this folder to load plugins', (v) -> begin lPluginFolder := v; end);
  lOptions.Add('include=', 'Include a script', (v) -> begin if assigned(v) then lIncludes.Add(v); end);
  lOptions.Add('wait', 'Wait for a key before finishing', v-> begin lWait := assigned(v) end);
  lOptions.Add('dryrun', 'Do a script dry run (skips file/exec actions)', v->begin lDryRun := assigned(v); end);
  lOptions.Add('e|enterexit', 'Enable/Disable function enter/exit logging', v->begin lLogFNEnter := assigned(v); end);
  lOptions.Add('l|live', 'Enable live output from exeucted tasks', v->begin lLiveOutput := assigned(v); end);
  var lArgs: List<String>;
  try
    var lCmdArgs := OptionCommandLine.Parse(Environment.CommandLine);

    //lLogger.LogMessage('Invoked as: '+String.Join(' ',lCmdArgs.Select(a->'"'+a+'"').ToArray));
    //lLogger.LogMessage('Invoked as: '+String.Join(' ',args.Select(a->'"'+a+'"').ToArray));
    lArgs := lOptions.Parse(lCmdArgs.Skip(1));
  except
    on  Exception  do
      lShowHelp := true;
  end;
  if lShowHelp then begin
    Console.WriteLine('Train.exe <script.train> [options] [variable=value]');
    lOptions.WriteOptionDescriptions(Console.Out);
    exit 1;
  end
  else if not lArgs.Any(a -> a:ToLower:EndsWith(".train") or a:ToLower:EndsWith(".js")) then begin
    lLogger.LogError('No .train files specified');
    exit 1;
  end;
  var lMulti: MultiLogger := new MultiLogger;
  try
    lMulti.Loggers.Add(lLogger);
    lLogger := lMulti;
    if not String.IsNullOrEmpty(lXMLOut) or not String.IsNullOrEmpty(lHtmlOut) then begin
      lMulti.Loggers.Add(new XmlLogger(lXMLOut, lHtmlOut, lXSLT));
    end;
    var lRoot := new RemObjects.Train.API.Environment();
    lRoot.LoadSystem;
    if File.Exists(lGlobalSettings) then
      lRoot.LoadIni(lGlobalSettings);
     lRoot['Train'] := Path.GetDirectoryName(typeOf(ConsoleApp).Assembly.Location);
    for each el in lGlobalVars do lRoot[el.Key] := el.Value;
    if LoggerSettings.ShowDebug then
      lLogger.LogDebug('Root Variables: '#13#10'{0}',String.Join(#13#10, lRoot.Select(a->a.Key+'='+a.Value).ToArray));

    if not String.IsNullOrEmpty(lPluginFolder) then
    begin
      if Directory.Exists(lPluginFolder) then
      begin
        var files := Directory.GetFiles(lPluginFolder, '*.dll');
        for each file in files do
        begin
          PluginSystem.Load(file);
        end;
      end;
    end;

    for each el in lArgs.Where(a -> a.Contains('=') and not a:ToLower:EndsWith('.train') and not a:ToLower:EndsWith(".js")) do begin
      var p := el.IndexOf("=");
      var k := el.Substring(0, p);
      var v := el.Substring(p+1);
      lGlobalVars.Add(k, StripQuotes(v));
    end;

    for each el in lArgs.Where(a -> a:ToLower:EndsWith('.train') or a:ToLower:EndsWith(".js")) do begin
      if not File.Exists(el) then begin
        lLogger.LogError("File '{0}' not found.", el);
        exit 1;
      end;
      var lEngine := new Engine(lRoot, el);
      lEngine.Logger := lLogger;
      lEngine.LogFunctionEnter := lLogFNEnter;
      lEngine.DryRun := lDryRun;
      lEngine.LiveOutput := lLiveOutput;
      for each incl in lIncludes do
        lEngine.LoadInclude(incl);
      lEngine.Run();
      lEngine.Logger := nil;
    end;
  except
    on e: Exception do begin
      if e is not AbortException then
        lLogger.LogDebug('Exception: {0}', e.ToString);

      exit 1;
    end;
  finally
    lMulti.Write;
    lMulti.Dispose;
    if lWait then begin
      Console.WriteLine('Waiting for enter to continue');
      Console.ReadLine;
    end;
  end;
end;

class method ConsoleApp.StripQuotes(s: String): String;
begin
  if s = nil then exit nil;
  if s.Length > 1 then begin
    if s.StartsWith('"') and (s.EndsWith('"')) then
      s := s.Substring(1, s.Length -2).Replace('""', '"')
    else if s.StartsWith(#39) and (s.EndsWith(#39)) then
      s := s.Substring(1, s.Length -2).Replace(#39#39, #39);
  end;
  exit s;
end;

end.