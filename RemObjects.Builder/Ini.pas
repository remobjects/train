namespace RemObjects.Builder;

interface
uses
  System.Collections.Generic,
  system.Linq,
  System.IO;


type
  IniFile = public class
  private
    method WriteSection(ssw: StreamWriter; aItem: IniSection);
    method set_Keys(i : Int32; value: String);
    fSections: List<Tuple<string, IniSection>> := new List<Tuple<string, IniSection>>;
  public
    property Count: Integer read fSections.Count;
    property Keys[i: Integer]: string read fSections[i].Item1  write set_Keys;
    property Item[s: string]: IniSection read fSections.FirstOrDefault(a->a.Item1 = s):Item2;

    property Sections: List<Tuple<string, IniSection>> read fSections;

    method AddSection(s: string): IniSection;
    method RemoveAt(i: Integer);

    method SaveToStream(sr: StreamWriter);
    method SaveToFile(s: string);
    method LoadFromStream(sr: StreamReader);
    method LoadFromFile(s: string);
  end;
  IniSection = public class(Dictionary<string, string>)
  private
    method get_Item(s : String): String;
    method set_Item(s : String; value: String);
  public
    property Item[s: string]: string read get_Item write set_Item; reintroduce;
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

method IniFile.set_Keys(i : Int32; value: String);
begin
  fSections[i] := new Tuple<string, IniSection>(value, fSections[i].Item2);
end;

method IniFile.AddSection(s: string): IniSection;
begin
  result := Item[s];
  if result = nil then begin
    result := new IniSection;
    fSections.Add(new Tuple<string, IniSection>(s, result));
  end;
end;

method IniFile.RemoveAt(i: Integer);
begin
  fSEctions.RemoveAt(i);
end;

method IniFile.SaveToStream(sr: StreamWriter);
begin
  var lItem := Item[''];
  if lItem <> nil then begin
    WriteSection(sr, lItem);
  end;

  for each el in fSections do begin
    if string.IsNullOrEmpty(el.Item1) then continue;
    sr.WriteLine('[{0}]', el.Item1);
    WriteSection(sr, el.Item2);
  end;
end;

method IniFile.SaveToFile(s: string);
begin
  using sr := new StreamWriter(s) do SaveToStream(sr);
end;

method IniFile.LoadFromStream(sr: StreamReader);
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

method IniFile.LoadFromFile(s: string);
begin
  using sr := new StreamReader(s) do
    LoadFromStream(sr);
end;

method IniFile.WriteSection(ssw: StreamWriter; aItem: IniSection);
begin
  for each el in aItem do begin
    ssw.WriteLine('{0}={1}', el.Key, el.Value);
  end;
end;

end.
