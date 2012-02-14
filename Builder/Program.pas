namespace Builder;

interface

uses
  RemObjects.Builder,
  System.Collections.Generic,
  System.IO,
  System.Linq, 
  NDesk.Options;


type
  ConsoleApp = class
  public
    class method Main(args: array of String): Integer;
  end;

  Logger = public class(ILogger)
  private
  public
    method LogDebug(s: System.String);
    method LogWarning(s: System.String);
    method LogMessage(s: System.String);
    method LogHint(s: System.String);
    method LogError(s: System.String);

    property ShowDebug: Boolean := false;
    property ShowWarning: Boolean := true;
    property ShowMessage: Boolean := true;
    property ShowHint: Boolean := true;
  end;

implementation

method Logger.LogDebug(s: System.String);
begin
  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.DarkBlue;
  Console.WriteLine(s);
  Console.ForegroundColor := lCol;
end;

method Logger.LogError(s: System.String);
begin
  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.Red;
  Console.WriteLine(s);
  Console.ForegroundColor := lCol;
end;

method Logger.LogHint(s: System.String);
begin
  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.Magenta;
  Console.WriteLine(s);
  Console.ForegroundColor := lCol;
end;

method Logger.LogMessage(s: System.String);
begin
  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.Gray;
  Console.WriteLine(s);
  Console.ForegroundColor := lCol;
end;

method Logger.LogWarning(s: System.String);
begin
  var lCol := Console.ForegroundColor;
  Console.ForegroundColor := ConsoleColor.Yellow;
  Console.WriteLine(s);
  Console.ForegroundColor := lCol;
end;

class method ConsoleApp.Main(args: array of String): Integer;
begin
  var lLogger := new Logger;
  var lOptions := new OptionSet();
  var lShowHelp: Boolean := false;
  var lGlobalSettings: String := Path.Combine(Path.GetDirectoryName(typeOf(ConsoleApp).Assembly.Location), 'builder.ini');
  lOptions.Add('o|options=', 'Override the ini file with the global options for the ini', v-> begin lGlobalSettings := coalesce(lGlobalSettings, v); end);
  lOptions.Add('d|debug', 'Show debugging messages', v-> begin lLogger.ShowDebug := assigned(v); end);
  lOptions.Add('w|warning', 'Show warning messages', v-> begin lLogger.ShowWarning := assigned(v); end);
  lOptions.Add('h|hint', 'Show hint messages', v-> begin lLogger.ShowDebug := assigned(v); end);
  lOptions.Add('m|message', 'Show info messages', v-> begin lLogger.ShowMessage := assigned(v); end);
  lOptions.Add("h|?", "show help", v -> begin lShowHelp := assigned(v); end );
  var lArgs: List<String>;
  try
    lArgs := lOptions.Parse(args);
  except
    on  Exception  do
      lShowHelp := true;
  end;
  if  lShowHelp then begin
    Console.WriteLine('Build script...');
    lOptions.WriteOptionDescriptions(Console.Out);
    exit 1;
  end else if lArgs.Count = 0 then begin
    lLogger.LogError('No files specified');
    exit 1;
  end;
  try
    var lRoot := new Environment();
    for each el in lArgs do begin
      var lEngine := new Engine(lRoot, nil, el);
      lEngine.Logger := lLogger;
      lEngine.Run();
    end;
  except
    on e: Exception do
      lLogger.LogError('Could not load file {0}', e.Message);
  end;
end;

end.
