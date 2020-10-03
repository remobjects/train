namespace RemObjects.Train;

interface

uses
  System.Collections.Generic,
  System.IO,
  System.Reflection;

type
    SharedSettings = public sealed class
    private
      class var defaultInstance: SharedSettings;
      //var fValues: Dictionary<String, String>;
      //method get_MachineName: System.String;
      //method get_Values(aValue: String): String;
      //method get_OptionalValues(aValue: String): String;
      class method get_DefaultInstance: SharedSettings;
      constructor;
    public
      class method FixFolder(aFolder: String): String;
      class property &Default: SharedSettings read get_DefaultInstance;
      //class property SettingsData: String;
      //property Values[aValue: String]: String read get_Values; default;
      //property OptionalValues[aValue: String]: String read get_OptionalValues;
      property Filename: String read private write;
      //property MachineName: String read get_MachineName;
      property PlatformName: String read case RemObjects.Elements.RTL.Environment.OS of
        RemObjects.Elements.RTL.OperatingSystem.Windows: "Windows";
        RemObjects.Elements.RTL.OperatingSystem.macOS: "Mac";
        RemObjects.Elements.RTL.OperatingSystem.Linux: "Linux";
      end;
    end;

implementation

{ SharedSettings }

constructor SharedSettings;
begin
  inherited constructor;

  var lBaseName := Path.Combine(Path.GetDirectoryName(&Assembly.GetEntryAssembly.Location),
                                Path.GetFileNameWithoutExtension(&Assembly.GetEntryAssembly.Location));

  var lMachineName := System.Environment.MachineName.Trim();
  if lMachineName.EndsWith('.local') then
    lMachineName := lMachineName.Substring(0, lMachineName.Length-6);

  //if assigned(SettingsData) then begin
    //Console.WriteLine('Using configured data, not loading ini');
    //fValues :=  Helpers.ReadIniFileData(SettingsData)
  //end else
  begin
    Console.WriteLine('Considering ini file '+lBaseName+'.'+lMachineName+'.ini');
    if File.Exists(lBaseName+'.'+lMachineName+'.ini') then begin
      Console.WriteLine('Loading ini file '+lBaseName+'.'+lMachineName+'.ini');
      //fValues :=  Helpers.ReadIniFile(lBaseName+'.'+lMachineName+'.ini')
      Filename := lBaseName+'.'+lMachineName+'.ini';
    end
    else begin
      Console.WriteLine('Considering ini file '+lBaseName+'.'+PlatformName+'.ini');
      if File.Exists(lBaseName+'.'+PlatformName+'.ini') then begin
        Console.WriteLine('Loading ini file '+lBaseName+'.'+PlatformName+'.ini');
        //fValues := Helpers.ReadIniFile(lBaseName+'.'+PlatformName+'.ini')
        Filename := lBaseName+'.'+PlatformName+'.ini';
      end
      else begin
        Console.WriteLine('Considering ini file '+lBaseName+'.ini');
        if File.Exists(lBaseName+'.ini') then begin
          Console.WriteLine('Loading ini file '+lBaseName+'.ini');
          //fValues := Helpers.ReadIniFile(lBaseName+'.ini');
          Filename := lBaseName+'.ini';
        end
        else begin
          Console.WriteLine('No config file found.');
          //raise new Exception('No config file found.');
        end;
      end;
    end;
  end;

end;

//method SharedSettings.get_MachineName: System.String;
//begin
  //if fValues:ContainsKey('MachineName') then
    //result := fValues['MachineName'] as System.String;

  //var lPhysicalMachineName := System.Environment.MachineName;
  //if lPhysicalMachineName.EndsWith('.local') then
    //lPhysicalMachineName := lPhysicalMachineName.Substring(0, lPhysicalMachineName.Length-6);

  //if fValues:ContainsKey('MachineName-'+lPhysicalMachineName) then
    //result := fValues['MachineName-'+lPhysicalMachineName] as System.String;

  //if length(result) = 0 then
    //result := System.Environment.GetEnvironmentVariable("CI2_MACHINE_NAME");

  //if length(result) = 0 then
    //result := lPhysicalMachineName;
//end;

//method SharedSettings.get_Values(aValue: String): String;
//begin
  //if fValues:ContainsKey(aValue) then
    //exit (fValues[aValue] as System.String):Trim
  //else
    //raise new Exception('Value '+aValue+' not found in server .ini');
//end;

//method SharedSettings.get_OptionalValues(aValue: String): String;
//begin
  //if fValues.ContainsKey(aValue) then
    //exit (fValues[aValue] as System.String).Trim
  //else
    //exit nil;
//end;

class method SharedSettings.get_DefaultInstance: SharedSettings;
begin
  if not assigned(defaultInstance) then
    defaultInstance := new SharedSettings;
  result := defaultInstance;
end;

class method SharedSettings.FixFolder(aFolder: String): String;
begin
  result := aFolder;
  if result.StartsWith("~/") or result.StartsWith("~\") then begin
    var lHome := System.Environment.GetEnvironmentVariable("HOME");
    if length(lHome) > 0 then
      result := lHome+result.Substring(1);
  end;
end;


end.