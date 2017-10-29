namespace RemObjects.Train.API;

interface

uses
  System.Collections.Generic,
  System.Runtime.InteropServices,
  System.Text;


type
  [ComImport(),
    InterfaceType(ComInterfaceType.InterfaceIsIUnknown),
    Guid('e707dcde-d1cd-11d2-bab9-00c04f8eceae')]
  IAssemblyCache = assembly interface
    [PreserveSig()]
    method UninstallAssembly(&flags: System.Int32;     [MarshalAs(UnmanagedType.LPWStr)]assemblyName: String; refData: IntPtr; out disposition: IntPtr): System.Int32;

    [PreserveSig()]
    method QueryAssemblyInfo(&flags: System.Int32;     [MarshalAs(UnmanagedType.LPWStr)]assemblyName: String; assemblyInfo: IntPtr): System.Int32;
    [PreserveSig()]
    method Reserved(&flags: System.Int32; pvReserved: IntPtr; out ppAsmItem: Object;     [MarshalAs(UnmanagedType.LPWStr)]assemblyName: String): System.Int32;
    [PreserveSig()]
    method Reserved(out ppAsmScavenger: Object): System.Int32;

    [PreserveSig()]
    method InstallAssembly(&flags: System.Int32;     [MarshalAs(UnmanagedType.LPWStr)]assemblyFilePath: String; refData: IntPtr): System.Int32;
  end;

  [ComImport(),
    InterfaceType(ComInterfaceType.InterfaceIsIUnknown),
    Guid('CD193BC0-B4BC-11d2-9833-00C04FC31D2E')]
  IAssemblyName = assembly interface
    [PreserveSig()]
    method SetProperty(PropertyId: System.Int32; pvProperty: IntPtr; cbProperty: System.Int32): System.Int32;

    [PreserveSig()]
    method GetProperty(PropertyId: System.Int32; pvProperty: IntPtr; var pcbProperty: System.Int32): System.Int32;

    [PreserveSig()]
    method &Finalize: System.Int32;

    [PreserveSig()]
    method GetDisplayName(pDisplayName: StringBuilder; var pccDisplayName: System.Int32; displayFlags: System.Int32): System.Int32;

    [PreserveSig()]
    method Reserved(var guid: Guid; obj1: Object; obj2: Object; string1: String; llFlags: Int64; pvReserved: IntPtr; cbReserved: System.Int32; out ppv: IntPtr): System.Int32;

    [PreserveSig()]
    method GetName(var pccBuffer: System.Int32; pwzName: StringBuilder): System.Int32;

    [PreserveSig()]
    method GetVersion(out versionHi: System.Int32; out versionLow: System.Int32): System.Int32;
    [PreserveSig()]
    method IsEqual(pAsmName: IAssemblyName; cmpFlags: System.Int32): System.Int32;

    [PreserveSig()]
    method Clone(out pAsmName: IAssemblyName): System.Int32;
  end;


  [ComImport(),
    InterfaceType(ComInterfaceType.InterfaceIsIUnknown),
    Guid('21b8916c-f28e-11d2-a473-00c04f8ef448')]
  IAssemblyEnum = assembly interface
    [PreserveSig()]
    method GetNextAssembly(pvReserved: IntPtr; out ppName: IAssemblyName; &flags: System.Int32): System.Int32;
    [PreserveSig()]
    method Reset: System.Int32;
    [PreserveSig()]
    method Clone(out ppEnum: IAssemblyEnum): System.Int32;
  end;

  AssemblyCacheFlags = assembly flags (ASM_CACHE_GAC = 2);

  CreateAssemblyNameObjectFlags = assembly enum(
    CANOF_DEFAULT = 0,
    CANOF_PARSE_DISPLAY_NAME = 1
  );

  MSWinGacUtil = assembly class
  private
    [DllImport('fusion.dll')]
    class method CreateAssemblyEnum(out ppEnum: IAssemblyEnum; pUnkReserved: IntPtr; pName: IAssemblyName; &flags: AssemblyCacheFlags; pvReserved: IntPtr): System.Int32; external;

    [DllImport('fusion.dll')]
    class method CreateAssemblyNameObject(out ppAssemblyNameObj: IAssemblyName;     [MarshalAs(UnmanagedType.LPWStr)]szAssemblyName: String; &flags: CreateAssemblyNameObjectFlags; pvReserved: IntPtr): System.Int32; external;

    [DllImport('fusion.dll')]
    class method CreateAssemblyCache(out ppAsmCache: IAssemblyCache; reserved: System.Int32): System.Int32; external;
    class method WithCache(aRun: Action<IAssemblyCache>);
  const
    ASM_DISPLAYF_VERSION                 = $01;
    ASM_DISPLAYF_CULTURE                 = $02;
    ASM_DISPLAYF_PUBLIC_KEY_TOKEN        = $04;
    ASM_DISPLAYF_PUBLIC_KEY              = $08;
    ASM_DISPLAYF_CUSTOM                  = $10;
    ASM_DISPLAYF_PROCESSORARCHITECTURE   = $20;
    ASM_DISPLAYF_LANGUAGEID              = $40;
    ASM_DISPLAYF_RETARGET                = $80;
    ASM_DISPLAYF_CONFIG_MASK             = $100;
    ASM_DISPLAYF_MVID                    = $200;
    ASM_DISPLAYF_FULL                    =
                      ASM_DISPLAYF_VERSION           or
                      ASM_DISPLAYF_CULTURE           or
                      ASM_DISPLAYF_PUBLIC_KEY_TOKEN  or
                               ASM_DISPLAYF_RETARGET          or
                      ASM_DISPLAYF_PROCESSORARCHITECTURE;

    ASM_DISPLAYF_NORMAL = ASM_DISPLAYF_FULL;
  public
    class method Register(aName: String);
    class method Unregister(aFullName: String);
    class method List(aDisplayName: String): sequence of String;
  end;

implementation

class method MSWinGacUtil.&Register(aName: String);
begin
  WithCache(aCache-> begin
    var res :=  aCache.InstallAssembly(2, aName, 0);
    if res <> 0 then Marshal.ThrowExceptionForHR(res);
  end);
end;

class method MSWinGacUtil.Unregister(aFullName: String);
begin
  WithCache(aCache-> begin
    var lDummy: IntPtr;
    var res := aCache.UninstallAssembly(0, aFullName, IntPtr.Zero, out lDummy);
    if res <> 0 then Marshal.ThrowExceptionForHR(res);
  end);
end;

class method MSWinGacUtil.List(aDisplayName: String): sequence of  String;
var
  lName: IAssemblyName;
  lEnum: IAssemblyEnum;
  lRes: List<String> := new List<String>;
  lLen: Integer;
begin

  if String.IsNullOrEmpty(aDisplayName) then lName := nil
  else
    CreateAssemblyNameObject(out lName, aDisplayName, CreateAssemblyNameObjectFlags.CANOF_PARSE_DISPLAY_NAME, IntPtr.Zero);

  CreateAssemblyEnum(out lEnum, IntPtr.Zero, lName, AssemblyCacheFlags.ASM_CACHE_GAC, IntPtr.Zero);
  if lEnum = nil then exit;
  while lEnum.GetNextAssembly(IntPtr.Zero, out lName, 0) = 0 do begin
    lLen := 0;
    lName.GetDisplayName(nil, var lLen, ASM_DISPLAYF_NORMAL);
    var lSB := new StringBuilder(lLen);
    lName.GetDisplayName(lSB, var lLen, ASM_DISPLAYF_NORMAL);
    lRes.Add(lSB.ToString().TrimEnd([#0]));
  end;
  exit lRes;
end;

class method MSWinGacUtil.WithCache(aRun: Action<IAssemblyCache>);
begin
  var lTmp: IAssemblyCache;
  CreateAssemblyCache(out lTmp, 0);
  aRun(lTmp);
end;

end.