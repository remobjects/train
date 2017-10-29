namespace RemObjects.Train.API;

interface
uses
  System,
  System.Collections,
  System.Collections.Generic,
  System.Text,
  System.Linq,
  System.IO;


type
  UnmanagedResourceElement = public class
  public
    property Data: array of System.Byte;
    property ResourceType: System.String;
    property Name: System.String;
    property DataVersion: Integer;
    property Language: System.UInt16;
    property &Flags: System.UInt16;
    property Version: System.UInt32;
    property Characterisitics: System.UInt32;
  end;

  EInvalidResource = public class(Exception);

  UnmanagedResourceFile = public class(List<UnmanagedResourceElement>)
  private
    method Align4(val: Int32): Integer;
  public
    constructor;
    constructor (m: Stream);
    class method FromFile(s: String): UnmanagedResourceFile;
    method Save(aOut: Stream);
    method Save(fn: String);

    const RT_VERSION = #0'16';
    const RT_ICON = #0'3';
    const RT_ICONGROUP = #0'14';

    method ReplaceIcons(aIconData: array of Byte); // removes it all & replaces
    method AddVersionInfo(aDeleteExisting: Boolean; aLang: Integer; v: Win32VersionInfoResource);
  end;

  VersioInfoFlags = public flags (
        debug = 1,
        prerelease = 2,
        patched = 4,
        privatebuild = 8,
        infoinferred = $10,
        specialbuild = $20);

  Win32VersionInfoResource = public class
  private

    method Pad32Bits(wr: BinaryWriter);
    method WriteData(wr: BinaryWriter);
    fData: array of Byte;
  public
    /// <summary>
    /// file version major
    /// </summary>
    property FileVerMaj: System.UInt16;
    /// <summary>
    /// file version minor
    /// </summary>
    property FileVerMin: System.UInt16;
    /// <summary>
    /// file version build
    /// </summary>
    property FileVerBuild: System.UInt16;
    /// <summary>
    /// file version release
    /// </summary>
    property FileVerRelease: System.UInt16;
    /// <summary>
    /// product version major
    /// </summary>
    property ProductVerMaj: System.UInt16;
    /// <summary>
    /// product version minor
    /// </summary>
    property ProductVerMin: System.UInt16;
    /// <summary>
    /// product version build
    /// </summary>
    property ProductVerBuild: System.UInt16;
    /// <summary>
    /// product version build
    /// </summary>
    property ProductVerRelease: System.UInt16;
    /// <summary>
    /// file date
    /// </summary>
    property FileDate: System.UInt64;
    /// <summary>
    /// lags
    /// </summary>
    property &Flags: VersioInfoFlags;
    /// <summary>
    /// is this a dll?
    /// </summary>
    property IsDll: System.Boolean;
    /// <summary>
    /// code page
    /// </summary>
    property CodePage: System.UInt16;
    /// <summary>
    /// resource language
    /// </summary>
    property ResLang: System.UInt16;

    /// <summary>
    /// Dont add ProductVersion or FileVersion
    /// </summary>
    property Values: IList<KeyValuePair<System.String, System.String>> := new List<KeyValuePair<String,String>>; readonly;
    method GetData: array of System.Byte;
  end;
  IconResource = class
  public
    bWidth: System.Byte;
    bHeight: System.Byte;
    bColorCount: System.Byte;
    bReserved: System.Byte;
    wPlanes: System.UInt16;
    wBitCount: System.UInt16;
    dwBytesInRes: System.UInt32;
    dwImageOffset: System.UInt32;
    Data: array of System.Byte;
  end;

implementation


constructor UnmanagedResourceFile(m: Stream);
begin
  var sr := new BinaryReader(m);
  if (((((((sr.ReadUInt32() <> $0) or (sr.ReadUInt32() <> $20)) or (sr.ReadUInt32() <> $ffff)) or (sr.ReadUInt32() <> $ffff)) or (sr.ReadUInt32() <> $0)) or (sr.ReadUInt32() <> $0)) or (sr.ReadUInt32() <> $0)) or (sr.ReadUInt32() <> $0) then    raise new EInvalidResource();
  while sr.BaseStream.Position < sr.BaseStream.Length do begin
    var element: UnmanagedResourceElement := new UnmanagedResourceElement();
    Add(element);

    var HeaderSoFar: System.Int32 := 0;
    var DataSize: System.Int32 := sr.ReadInt32();
    HeaderSoFar := HeaderSoFar + 4;
    var HeaderSize: System.Int32 := sr.ReadInt32();
    HeaderSoFar := HeaderSoFar + 4;
    var num: System.UInt16 := sr.ReadUInt16();
    HeaderSoFar := HeaderSoFar + 2;
    if num = $ffff then begin
      num := sr.ReadUInt16();
      HeaderSoFar := HeaderSoFar + 2;
      element.ResourceType := #0 + num.ToString()
    end
    else begin
      var tmp: StringBuilder := new StringBuilder();
      tmp.Append(Char(num));
      while true do begin
        num := sr.ReadUInt16();
        HeaderSoFar := HeaderSoFar + 2;
        if num = 0 then          break;
        tmp.Append(Char(num));
      end;
      element.ResourceType := tmp.ToString()
    end;
    while sr.BaseStream.Position mod 4 <> 0 do begin
      sr.ReadByte();
      inc(HeaderSoFar);
    end;

    num := sr.ReadUInt16();
    HeaderSoFar := HeaderSoFar + 2;
    if num = $ffff then begin
      num := sr.ReadUInt16();
      HeaderSoFar := HeaderSoFar + 2;
      element.Name := #0 + num.ToString()
    end
    else begin
      var tmp: StringBuilder := new StringBuilder();
      tmp.Append(Char(num));
      while true do begin
        num := sr.ReadUInt16();
        HeaderSoFar := HeaderSoFar + 2;
        if num = 0 then          break;
        tmp.Append(Char(num));
      end;
      element.Name := tmp.ToString()
    end;
    while sr.BaseStream.Position mod 4 <> 0 do begin
      sr.ReadByte();
      inc(HeaderSoFar);
    end;

    element.DataVersion := sr.ReadUInt32();
    HeaderSoFar := HeaderSoFar + 4;
    element.Flags := sr.ReadUInt16();
    HeaderSoFar := HeaderSoFar + 2;
    element.Language := sr.ReadUInt16();
    HeaderSoFar := HeaderSoFar + 2;
    element.Version := sr.ReadUInt32();
    HeaderSoFar := HeaderSoFar + 4;
    element.Characterisitics := sr.ReadUInt32();
    HeaderSoFar := HeaderSoFar + 4;
    var i: System.Int32 := HeaderSize - HeaderSoFar;
    while i >= 4 do begin
      sr.ReadInt32();
      i := i - 4
    end;
    while i > 0 do begin
      sr.ReadByte();
      dec(i)
    end;
    element.Data := sr.ReadBytes(DataSize);
    i := 4 - (DataSize mod 4);
    while (i <> 4) and (i > 0) do begin
      if sr.BaseStream.Position >= sr.BaseStream.Length then        exit;
      sr.ReadByte();
      dec(i)
    end
  end

end;

constructor UnmanagedResourceFile;
begin

end;

method UnmanagedResourceFile.Save(aOut: Stream);
begin
  var sr := new BinaryWriter(aOut);
  sr.Write(Int32(0));
  sr.Write(Int32($20));
  sr.Write(Int32($ffff));
  sr.Write(Int32($ffff));
  sr.Write(Int32(0));
  sr.Write(Int32(0));
  sr.Write(Int32(0));
  sr.Write(Int32(0)); // empty resource

  for each el in self do begin
    while sr.BaseStream.Position mod 4 <> 0 do
      sr.Write(Byte(0));
    sr.Write(Int32(length(el.Data)));

    var lSize: Integer := 0;
    if el.Name[0] = #0 then lSize := lSize + 4 else begin
      lSize := lSize + Align4((1+el.Name.Length) * 2);
    end;
    if el.ResourceType[0] = #0 then lSize := lSize + 4 else begin
      lSize := lSize + Align4((1+el.ResourceType.Length) * 2);
    end;
    sr.Write(lSize + 24);
    if el.ResourceType[0] = #0 then begin
      sr.Write(Int16($FFFF));
      sr.Write(Int16.Parse(el.ResourceType.Substring(1)));
      while sr.BaseStream.Position mod 4 <> 0 do
        sr.Write(Byte(0));
    end else  begin
      sr.Write(Encoding.Unicode.GetBytes(el.ResourceType));
      sr.Write(Int16(0));
      while sr.BaseStream.Position mod 4 <> 0 do
      sr.Write(Byte(0));
    end;
    if el.Name[0] = #0 then begin
      sr.Write(Int16($FFFF));
      sr.Write(Int16.Parse(el.Name.Substring(1)));
    end else begin
      sr.Write(Encoding.Unicode.GetBytes(el.Name));
      sr.Write(Int16(0));
      while sr.BaseStream.Position mod 4 <> 0 do
      sr.Write(Byte(0));
    end;
    sr.Write(el.DataVersion);
    sr.Write(el.Flags);
    sr.Write(el.Language);
    sr.Write(el.Version);
    sr.Write(el.Characterisitics);

    sr.Write(el.Data);

  end;

end;

class method UnmanagedResourceFile.FromFile(s: String): UnmanagedResourceFile;
begin
  using fs := new FileStream(s, FileMode.Open, FileAccess.Read) do
    exit new UnmanagedResourceFile(fs);
end;

method UnmanagedResourceFile.Save(fn: String);
begin
  using fs := new FileStream(fn, FileMode.Create, FileAccess.Write) do
    Save(fs);
end;

method UnmanagedResourceFile.Align4(val: Int32): Integer;
begin
  if val mod 4 = 0 then exit val;
  exit val + 4 - (val mod 4);
end;

method UnmanagedResourceFile.AddVersionInfo(aDeleteExisting: Boolean; aLang: Integer; v: Win32VersionInfoResource);
begin
  if aDeleteExisting then begin
    for each el in self.Where(a->a.ResourceType = RT_VERSION).ToArray() do
      Remove(el);
  end;
  var lNewElement := new UnmanagedResourceElement;
  lNewElement.Data := v.GetData;
  lNewElement.Language:= 0;
  lNewElement.Name := #0'1';
  lNewElement.ResourceType := RT_VERSION;
  Add(lNewElement);
end;

method UnmanagedResourceFile.ReplaceIcons(aIconData: array of Byte);
begin
  for each el in self.Where(a->(a.ResourceType = RT_ICON) or (a.ResourceType = RT_ICONGROUP)).ToArray() do
    Remove(el);
  var br: BinaryReader := new BinaryReader(new MemoryStream(aIconData));
  var lDest := new MemoryStream();
  var bw: BinaryWriter := new BinaryWriter(lDest);
  var count: System.UInt16;
  br.ReadUInt16();
  bw.Write(0 as System.UInt16);
// reserved (0)
  br.ReadUInt16();
  bw.Write(1 as System.UInt16);

  count := br.ReadUInt16();
  bw.Write(count);

  var res: array of IconResource := new IconResource[count];
  for i: System.Int32 := 0 to res.Length -1 do begin
    res[i] := new IconResource();
    res[i].bWidth := br.ReadByte();
    res[i].bHeight := br.ReadByte();
    res[i].bColorCount := br.ReadByte();
    res[i].bReserved := br.ReadByte();
    res[i].wPlanes := br.ReadUInt16();
    res[i].wBitCount := br.ReadUInt16();
    res[i].dwBytesInRes := br.ReadUInt32();
    res[i].dwImageOffset := br.ReadUInt32()
  end;
  for i: System.Int32 := 0 to res.Length -1 do begin
    br.BaseStream.Position := res[i].dwImageOffset;
    res[i].Data := new System.Byte[res[i].dwBytesInRes];
    br.BaseStream.Read(res[i].Data, 0, res[i].dwBytesInRes as System.Int32)
  end;
  for i: System.Int32 := 0 to res.Length -1 do begin
    bw.Write(res[i].bWidth);
    bw.Write(res[i].bHeight);
    bw.Write(res[i].bColorCount);
    bw.Write(res[i].bReserved);
    bw.Write(res[i].wPlanes);
    bw.Write(res[i].wBitCount);
    bw.Write(res[i].dwBytesInRes);
    bw.Write((i + 1) as System.UInt16)
  end;
  bw.Flush();
  Add(new UnmanagedResourceElement(ResourceType := RT_ICONGROUP, Name := #0'0', Data := lDest.ToArray));
  for i: System.Int32 := 0 to res.Length -1 do
    Add(new UnmanagedResourceElement(ResourceType := RT_ICON, Name := #0+(i+1).ToString, Data := res[i].Data));
end;

method Win32VersionInfoResource.Pad32Bits(wr: BinaryWriter);
begin
  wr.Flush();
  var len: System.Int32 := 4 - (System.Int32(wr.BaseStream.Position) mod 4);

  while (len <> 4) and (len > 0) do begin
    dec(len);
    wr.Write(0 as System.Byte)
  end;
end;

method Win32VersionInfoResource.GetData: array of System.Byte;
begin
  if fData <> nil then    exit fData;
  var st: MemoryStream := new MemoryStream();
  var wr: BinaryWriter := new BinaryWriter(st, Encoding.Unicode);

  WriteData(wr);

  fData := st.ToArray();
  exit fData
end;

method Win32VersionInfoResource.WriteData(wr: BinaryWriter);
begin
  var keyData := 'VS_VERSION_INFO';
  wr.Write(0 as System.UInt16);
  wr.Write(Int16(13 * 4));
  wr.Write(0 as System.UInt16);
  var b: array of System.Byte := Encoding.Unicode.GetBytes(keyData);
  wr.Write(b);
// make sure it's 16bits unicode
  wr.Write(0 as System.UInt16);
  Pad32Bits(wr);

  wr.Write($feef04bd); //0x04B0
  wr.Write(0 as System.UInt32);
  wr.Write(FileVerMin);
  wr.Write(FileVerMaj);
  wr.Write(FileVerBuild);
  wr.Write(FileVerRelease);
  wr.Write(ProductVerMin);
  wr.Write(ProductVerMaj);
  wr.Write(ProductVerBuild);
  wr.Write(ProductVerRelease);
  wr.Write($3f as System.UInt32);
  wr.Write(System.UInt32(&Flags));
  wr.Write(4 as System.UInt32); // VOS_WIN32
  if IsDll then    wr.Write(2 as System.UInt32)
  else    wr.Write(1 as System.UInt32);
  wr.Write(0 as System.UInt32);
  wr.Write(System.UInt32((FileDate shr 32)));
  wr.Write(System.UInt32((FileDate and $ffffffff)));

  wr.Flush();
  var strpos: System.UInt16 := System.UInt16(wr.BaseStream.Position);
  wr.Write(0 as System.UInt16);
  wr.Write(0 as System.UInt16);
  wr.Write(0 as System.UInt16);
  b := Encoding.Unicode.GetBytes('StringFileInfo');
  wr.Write(b);
  wr.Write(0 as System.UInt16);
  Pad32Bits(wr);

  wr.Flush();
  var str2pos: System.UInt16 := System.UInt16(wr.BaseStream.Position);
  wr.Write(0 as System.UInt16);
  wr.Write(0 as System.UInt16);
  wr.Write(0 as System.UInt16);
  b := Encoding.Unicode.GetBytes(String.Format('{0:X4}{1:X4}', ResLang, CodePage));
  wr.Write(b);
  wr.Write(0 as System.UInt16);
  var z: System.UInt16;
  begin
    var i: System.Int32 := 0;
    while i < Values.Count do begin begin
        var key: System.String := Values[i].Key;
        var val: System.String := Values[i].Value;
        wr.Flush();
        z := System.UInt16(wr.BaseStream.Position);
        wr.Write(System.UInt16(z));
        wr.Write(System.UInt16((val.Length + 1)));
        wr.Write(1 as System.UInt16);
        b := Encoding.Unicode.GetBytes(key);
        wr.Write(b);
// make sure it's 16bits unicode
        wr.Write(0 as System.UInt16);
        Pad32Bits(wr);
        b := Encoding.Unicode.GetBytes(val);
        wr.Write(b);
// make sure it's 16bits unicode
        wr.Write(0 as System.UInt16);
        Pad32Bits(wr);
        var nz: System.UInt16 := System.UInt16((wr.BaseStream.Position - z));
        wr.Flush();
        wr.BaseStream.Position := z;
        wr.Write(nz);
        wr.Flush();
        wr.BaseStream.Position := wr.BaseStream.Length
      end;
// TODO: not supported Increment might not get called when using continue
      {POST}inc(i);
    end;
  end;
  wr.Flush();
  z := System.UInt16((wr.BaseStream.Length - strpos));
  wr.BaseStream.Position := strpos;
  wr.Write(z);
  wr.Flush();
  z := System.UInt16((wr.BaseStream.Length - str2pos));
  wr.BaseStream.Position := str2pos;
  wr.Write(z);
  wr.Flush();
  wr.BaseStream.Position := wr.BaseStream.Length;
  strpos := System.UInt16(wr.BaseStream.Position);
  wr.Write(0 as System.UInt16);
// length
  wr.Write(0 as System.UInt16);
  wr.Write(0 as System.UInt16);
// type
  b := Encoding.Unicode.GetBytes('VarFileInfo');
  wr.Write(b);
  wr.Write(0 as System.UInt16);
  Pad32Bits(wr);

  str2pos := System.UInt16(wr.BaseStream.Length);
  wr.Write(0 as System.UInt16);
// length
  wr.Write(4 as System.UInt16);
// valuelength
  wr.Write(0 as System.UInt16);
// type
  b := Encoding.Unicode.GetBytes('Translation');
  wr.Write(b);
  wr.Write(0 as System.UInt16);
  Pad32Bits(wr);
  wr.Write(System.UInt16(ResLang));
  wr.Write(System.UInt16(CodePage));
  z := System.UInt16((wr.BaseStream.Length - strpos));
  wr.BaseStream.Position := strpos;
  wr.Write(z);
  wr.Flush();
  z := System.UInt16((wr.BaseStream.Length - str2pos));
  wr.BaseStream.Position := str2pos;
  wr.Write(z);

  wr.Flush();
  z := System.UInt16(wr.BaseStream.Length);
  wr.BaseStream.Position := 0;
  wr.Write(z);
  wr.Flush()
end;

end.