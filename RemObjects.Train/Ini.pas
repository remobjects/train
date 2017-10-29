namespace RemObjects.Train;

interface
uses
  System.Collections.Generic,
  System.Linq,
  System.IO;


type
  IniFile = public class
  private
    method WriteSection(ssw: TextWriter; aItem: IniSection);
    method set_Keys(i : Int32; value: String);
    fSections: List<Tuple<String, IniSection>> := new List<Tuple<String, IniSection>>;
  public
    property Count: Integer read fSections.Count;
    property Keys[i: Integer]: String read fSections[i].Item1  write set_Keys;
    property Item[s: String]: IniSection read fSections.FirstOrDefault(a-> String.Equals(a.Item1,s, StringComparison.InvariantCultureIgnoreCase)):Item2;

    property Sections: List<Tuple<String, IniSection>> read fSections;

    method AddSection(s: String): IniSection;
    method RemoveAt(i: Integer);
    method Remove(s: String): Boolean;

    method SaveToStream(sr: TextWriter);
    method ToString: String; override;
    method SaveToFile(s: String);
    method LoadFromStream(sr: TextReader);
    method LoadFromFile(s: String);
  end;
  IniSection = public class(Dictionary<String, String>)
  private
    method get_Item(s : String): String;
    method set_Item(s : String; value: String);
  public
    constructor;
    property Item[s: String]: String read get_Item write set_Item; reintroduce;
  end;

implementation

method IniSection.get_Item(s : String): String;
begin
  TryGetValue(s, out result);
end;

method IniSection.set_Item(s : String; value: String);
begin
  inherited Item[s] := value;
end;

constructor IniSection;
begin
  inherited constructor(StringComparer.InvariantCultureIgnoreCase);
end;

method IniFile.set_Keys(i : Int32; value: String);
begin
  fSections[i] := new Tuple<String, IniSection>(value, fSections[i].Item2);
end;

method IniFile.AddSection(s: String): IniSection;
begin
  result := Item[s];
  if result = nil then begin
    result := new IniSection;
    fSections.Add(new Tuple<String, IniSection>(s, result));
  end;
end;

method IniFile.RemoveAt(i: Integer);
begin
  fSections.RemoveAt(i);
end;

method IniFile.SaveToStream(sr: TextWriter);
begin
  var lItem := Item[''];
  if lItem <> nil then begin
    WriteSection(sr, lItem);
  end;

  for each el in fSections do begin
    if String.IsNullOrEmpty(el.Item1) then continue;
    sr.WriteLine('[{0}]', el.Item1);
    WriteSection(sr, el.Item2);
  end;
end;

method IniFile.SaveToFile(s: String);
begin
  using sr := new StreamWriter(s) do SaveToStream(sr);
end;

method IniFile.LoadFromStream(sr: TextReader);
begin
  var lCurrentSection: IniSection;
  loop begin
    var s := sr.ReadLine():Trim();
    if s = nil then break;
    if s = '' then continue;
    if s.StartsWith('#') then continue;
    if s.StartsWith('[') then begin
      s := s.Substring(1);
      if s.EndsWith(']') then s := s.Substring(0, s.Length-1).Trim;
      lCurrentSection := AddSection(s);
    end else if s.IndexOf('=') >= 0 then begin
      var lItem := s.Split(['='], 2, StringSplitOptions.RemoveEmptyEntries);
      if length(lItem) = 2 then begin
        if lCurrentSection = nil then lCurrentSection := AddSection('');
        lCurrentSection[lItem[0]] := lItem[1];
      end;
    end;
  end;
end;

method IniFile.LoadFromFile(s: String);
begin
  using sr := new StreamReader(s) do
    LoadFromStream(sr);
end;

method IniFile.WriteSection(ssw: TextWriter; aItem: IniSection);
begin
  for each el in aItem do begin
    ssw.WriteLine('{0}={1}', el.Key, el.Value);
  end;
end;

method IniFile.ToString: String;
begin
  var sr := new StringWriter();
  SaveToStream(sr);
  exit sr.GetStringBuilder().ToString;
end;

method IniFile.&Remove(s: String): Boolean;
begin
  var n := fSections.FindIndex(a-> String.Equals(a.Item1, s, StringComparison.InvariantCultureIgnoreCase));
  if n < 0 then exit false;
  RemoveAt(n);
  exit true;
end;

end.