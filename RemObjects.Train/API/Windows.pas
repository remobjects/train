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
  WindowsPlugin = public class(IPluginRegistration)
  public

    method Register(aServices: IApiRegistrationServices);
    begin
      if System.Environment.OSVersion.Platform = PlatformID.Win32NT  then begin
        var lWindowsObject := aServices.RegisterObjectValue('windows');
        lWindowsObject.AddValue('createStartMenuShortcut', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(WindowsPlugin), 'createStartMenuShortcut'));
      end;
    end;

    [WrapAs('windows.createStartMenuShortcut', SkipDryRun := false)]
    class method createStartMenuShortcut(aServices: IApiRegistrationServices; ec: ExecutionContext; aDestinationPath: String; aName: String := nil; aDescription: String := nil; aSubFolder: String := nil): Boolean;
    begin
      var link := new ShellLink() as IShellLink;

      // setup shortcut information
      link.SetDescription(aDescription);
      link.SetPath(aDestinationPath);

      // save it
      var file := System.Runtime.InteropServices.ComTypes.IPersistFile(link);
      var lPath := System.Environment.GetFolderPath(System.Environment.SpecialFolder.StartMenu);
      if assigned(aSubFolder) then begin
        lPath := Path.Combine(lPath, aSubFolder);
        Directory.CreateDirectory(lPath);
      end;
      if length(aName) = 0 then
        aName := Path.GetFileNameWithoutExtension(aDestinationPath);
      file.Save(Path.Combine(lPath, aName+".lnk"), false);
    end;

  end;

  [ComImport]
  [Guid("00021401-0000-0000-C000-000000000046")]
  ShellLink = assembly class
  end;

  [ComImport]
  [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  [Guid("000214F9-0000-0000-C000-000000000046")]
  IShellLink = assembly interface
    method GetPath([&Out] [MarshalAs(UnmanagedType.LPWStr)] pszFile: StringBuilder; cchMaxPath: Integer; out pfd: IntPtr; fFlags: Integer);
    method GetIDList(out ppidl: IntPtr);
    method SetIDList(pidl: IntPtr);
    method GetDescription([&Out] [MarshalAs(UnmanagedType.LPWStr)] pszName: StringBuilder; cchMaxName: Integer);
    method SetDescription([MarshalAs(UnmanagedType.LPWStr)] pszName: String);
    method GetWorkingDirectory([&Out] [MarshalAs(UnmanagedType.LPWStr)] pszDir: StringBuilder; cchMaxPath: Integer);
    method SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] pszDir: String);
    method GetArguments([&Out] [MarshalAs(UnmanagedType.LPWStr)] pszArgs: StringBuilder; cchMaxPath: Integer);
    method SetArguments([MarshalAs(UnmanagedType.LPWStr)] pszArgs: String);
    method GetHotkey(out pwHotkey: Int16);
    method SetHotkey(wHotkey: Int16);
    method GetShowCmd(out piShowCmd: Integer);
    method SetShowCmd(iShowCmd: Integer);
    method GetIconLocation([&Out] [MarshalAs(UnmanagedType.LPWStr)] pszIconPath: StringBuilder; cchIconPath: Integer; out piIcon: Integer);
    method SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] pszIconPath: String; iIcon: Integer);
    method SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] pszPathRel: String; dwReserved: Integer);
    method Resolve(hwnd: IntPtr; fFlags: Integer);
    method SetPath([MarshalAs(UnmanagedType.LPWStr)] pszFile: String);
  end;

end.