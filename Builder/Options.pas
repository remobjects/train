//
// Options.Pas
// Converted to Delphi Prism from original code by Anton Kasyanov
// (CS2PAS utility was used (http://code.remobjects.com/p/csharptoxy/))
// NDesk.Options is available at http://www.ndesk.org/Options
//
// Authors:
//  Jonathan Pryor <jpryor@novell.com>
//
// Copyright (C) 2008 Novell (http://www.novell.com)
//
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// Compile With:
//   gmcs -debug+ -r:System.Core Options.cs -o:NDesk.Options.dll
//   gmcs -debug+ -d:LINQ -r:System.Core Options.cs -o:NDesk.Options.dll
//
// The LINQ version just changes the implementation of
// OptionSet.Parse(IEnumerable<string>), and confers no semantic changes.
//
// A Getopt::Long-inspired option parsing library for C#.
//
// NDesk.Options.OptionSet is built upon a key/value table, where the
// key is a option format string and the value is a delegate that is 
// invoked when the format string is matched.
//
// Option format strings:
//  Regex-like BNF Grammar: 
//    name: .+
//    type: [=:]
//    sep: ( [^{}]+ | '{' .+ '}' )?
//    aliases: ( name type sep ) ( '|' name type sep )*
// 
// Each '|'-delimited name is an alias for the associated action.  If the
// format string ends in a '=', it has a required value.  If the format
// string ends in a ':', it has an optional value.  If neither '=' or ':'
// is present, no value is supported.  `=' or `:' need only be defined on one
// alias, but if they are provided on more than one they must be consistent.
//
// Each alias portion may also end with a "key/value separator", which is used
// to split option values if the option accepts > 1 value.  If not specified,
// it defaults to '=' and ':'.  If specified, it can be any character except
// '{' and '}' OR the *string* between '{' and '}'.  If no separator should be
// used (i.e. the separate values should be distinct arguments), then "{}"
// should be used as the separator.
//
// Options are extracted either from the current option by looking for
// the option name followed by an '=' or ':', or is taken from the
// following option IFF:
//  - The current option does not contain a '=' or a ':'
//  - The current option requires a value (i.e. not a Option type of ':')
//
// The `name' used in the option format string does NOT include any leading
// option indicator, such as '-', '--', or '/'.  All three of these are
// permitted/required on any named option.
//
// Option bundling is permitted so long as:
//   - '-' is used to start the option group
//   - all of the bundled options are a single character
//   - at most one of the bundled options accepts a value, and the value
//     provided starts from the next character to the end of the string.
//
// This allows specifying '-a -b -c' as '-abc', and specifying '-D name=value'
// as '-Dname=value'.
//
// Option processing is disabled by specifying "--".  All options after "--"
// are returned by OptionSet.Parse() unchanged and unprocessed.
//
// Unprocessed options are returned from OptionSet.Parse().
//
// Examples:
//  int verbose = 0;
//  OptionSet p = new OptionSet ()
//    .Add ("v", v => ++verbose)
//    .Add ("name=|value=", v => Console.WriteLine (v));
//  p.Parse (new string[]{"-v", "--v", "/v", "-name=A", "/name", "B", "extra"});
//
// The above would parse the argument string array, and would invoke the
// lambda expression three times, setting `verbose' to 3 when complete.  
// It would also print out "A" and "B" to standard output.
// The returned array would contain the string "extra".
//
// C# 3.0 collection initializers are supported and encouraged:
//  var p = new OptionSet () {
//    { "h|?|help", v => ShowHelp () },
//  };
//
// System.ComponentModel.TypeConverter is also supported, allowing the use of
// custom data types in the callback type; TypeConverter.ConvertFromString()
// is used to convert the value option to an instance of the specified
// type:
//
//  var p = new OptionSet () {
//    { "foo=", (Foo f) => Console.WriteLine (f.ToString ()) },
//  };
//
// Random other tidbits:
//  - Boolean options (those w/o '=' or ':' in the option format string)
//    are explicitly enabled if they are followed with '+', and explicitly
//    disabled if they are followed with '-':
//      string a = null;
//      var p = new OptionSet () {
//        { "a", s => a = s },
//      };
//      p.Parse (new string[]{"-a"});   // sets v != null
//      p.Parse (new string[]{"-a+"});  // sets v != null
//      p.Parse (new string[]{"-a-"});  // sets v == null
//
namespace NDesk.Options;

interface
uses
  System  ,
  System.Collections,
  System.Collections.Generic,
  System.Collections.ObjectModel,
  System.ComponentModel,
  System.Globalization,
  System.IO,
  System.Runtime.Serialization,
  System.Security.Permissions,
  System.Text,
  System.Text.RegularExpressions;


type
  OptionValueType = public enum(
    None,
    Optional,
    Required);


  OptionValueCollection = public class(IList, IList<String>)
  private
    var fValues: List<String> := new List<String>();
    var fContext: OptionContext;
   
    method get_Item(&index: Int32): String;
    method set_Item(&index: Int32; value: String);
  assembly
    constructor (optionContext: OptionContext);

  public
    {$REGION ICollection }
    method CopyTo(&array: &Array; &index: Int32); implements ICollection.CopyTo;

    property IsSynchronized: Boolean read (self.fValues as ICollection).IsSynchronized; implements ICollection.IsSynchronized;
    property SyncRoot: Object read (self.fValues as ICollection).SyncRoot; implements ICollection.SyncRoot;
    {$ENDREGION}

    {$REGION ICollection<T> }
    method &Add(value: String);
    method Clear();
    method Contains(value: String): Boolean;
    method CopyTo(&array: array of String; arrayIndex: Int32);
    method &Remove(value: String): Boolean;

    property Count: Integer read self.fValues.Count;
    property IsReadOnly: Boolean read false;
    {$ENDREGION}

    {$REGION IEnumerable }
    method GetEnumerator2(): IEnumerator; implements IEnumerable.GetEnumerator;
    {$ENDREGION}

    {$REGION IEnumerable<T> }
    method GetEnumerator(): IEnumerator<String>;
    {$ENDREGION}

    {$REGION IList }
    method &Add(value: Object): Int32; implements IList.Add;
    method Contains(value: Object): Boolean; implements IList.Contains;
    method IndexOf(value: Object): Int32; implements IList.IndexOf;
    method Insert2(&index: Int32; value: Object); implements IList.Insert;
    method &Remove(value: Object); implements IList.Remove;
    method RemoveAt2(&index: Int32); implements IList.RemoveAt;

    property IsFixedSize: Boolean read false; implements IList.IsFixedSize;
    property Item2[&index: Int32]: Object read self.Item[&index] write (self.fValues as IList).Item[&index]; implements IList.Item;
    {$ENDREGION}

    {$REGION IList<T> }
    method IndexOf(value: String): Int32;
    method Insert(&index: Int32;  value: String);
    method RemoveAt(&index: Int32);
    method AssertValid(&index: Int32);

    property Item[&index: Int32]: String read get_Item write set_Item; default;
    {$ENDREGION}

    method ToList(): List<String>;
    method ToArray(): array of String;
    method ToString(): String; override;
  end;


  OptionContext = public class
  public
    constructor (optionSet: OptionSet);

    property Option: Option read write;
    property OptionName: String read write;
    property OptionIndex: Int32 read write;
    property OptionSet: OptionSet read private write;
    property OptionValues: OptionValueCollection read private write;
  end;


  Option = public abstract class
  private
    class var NameTerminator: array of Char := ['=', ':']; readonly;

  private
    method ParsePrototype(): OptionValueType;
    class method AddSeparators(name: String;  &end: Int32;  separators: ICollection<String>);

  protected
    constructor(prototype: String;  description: String;  maxValueCount: Int32 := 1);

    class method Parse<T>(value: String; optionContext: OptionContext): T;
    method OnParseComplete(optionContext: OptionContext); abstract;

  assembly
    property Names: array of String read private write;
    property ValueSeparators: array of String read private write;

  public
    property Prototype: String read private write;
    property Description: String read private write;
    property OptionValueType: OptionValueType read private write;
    property MaxValueCount: Int32 read private write;

    method GetNames(): array of String;
    method GetValueSeparators(): array of String;
    method Invoke(optionContext: OptionContext);

    method ToString(): String; override;
  end;


  [Serializable()]
  OptionException = public class(Exception)
  protected
    constructor (info: SerializationInfo; context: StreamingContext);

  public
    property OptionName: String read private write;

    constructor;
    constructor(message: String;  optionName: String);
    constructor(message: String;  optionName: String;  innerException: Exception);

    [SecurityPermission(SecurityAction.LinkDemand, SerializationFormatter := true)]
    method GetObjectData(info: SerializationInfo; context: StreamingContext); override;
  end;


  OptionSet = public class(KeyedCollection<String, Option>)
  private
    const  OPTION_WIDTH: Int32 = 29;
    
    var fValueOption: Regex := new Regex('^(?<flag>--|-|/)(?<name>[^:=]+)((?<sep>[:=])(?<value>.*))?$'); readonly;

    method AddImpl(option: Option);
    class method Unprocessed(extra: ICollection<String>;  definition: Option;  optionContext: OptionContext;  argument: String): Boolean;
    class method Invoke(optionContext: OptionContext;  name: String;  value: String;  option: Option);
    method ParseValue(option: String; optionContext: OptionContext);
    method ParseBool(option: String; n: String; optionContext: OptionContext): Boolean;
    method ParseBundledValue(f: String; n: String; optionContext: OptionContext): Boolean;

    class method GetArgumentName(&index: Int32;  maxIndex: Int32;  description: String): String;
    class method GetDescription(description: String): String;
    class method GetLines(description: String): List<String>;
    class method GetLineEnd(start: Int32;  length: Int32;  description: String): Int32;

  protected
    method GetKeyForItem(item: Option): String; override;
    
    [Obsolete('Use KeyedCollection.this[string]')]
    method GetOptionForName(option: String): Option;

    method InsertItem(&index: Int32;  item: Option); override;
    method RemoveItem(&index: Int32); override;
    method SetItem(&index: Int32;  item: Option); override;
    method CreateOptionContext(): OptionContext; virtual;

    method GetOptionParts(argument: String; out flag: String; out name: String; out separator: String; out value: String): Boolean;
    method Parse(argument: String; optionContext: OptionContext): Boolean; virtual;

  public
    constructor ();
    constructor (localizer: Converter<String, String>);

    method &Add(option: Option): OptionSet; reintroduce;
    method &Add(prototype: String;  action: Action<String>): OptionSet;
    method &Add(prototype: String;  description: String;  action: Action<String>): OptionSet;
    method &Add(prototype: String;  action: OptionAction<String, String>): OptionSet;
    method &Add(prototype: String;  description: String;  action: OptionAction<String, String>): OptionSet;
    method &Add<T>(prototype: String;  action: Action<T>): OptionSet;
    method &Add<T>(prototype: String;  description: String;  action: Action<T>): OptionSet;
    method &Add<TKey, TValue>(prototype: String;  action: OptionAction<TKey, TValue>): OptionSet;
    method &Add<TKey, TValue>(prototype: String;  description: String;  action: OptionAction<TKey, TValue>): OptionSet;

    method Parse(arguments: IEnumerable<String>): List<String>;
    method Parse(argument: String): List<String>;

    method WriteOptionDescriptions(o: TextWriter);
    method WriteOptionPrototype(o: TextWriter; p: Option; var written: Int32): Boolean;

    class method GetNextOptionIndex(names: array of String;  i: Int32): Int32;
    class method &Write(o: TextWriter;  var n: Int32;  s: String);

    property MessageLocalizer: Converter<String, String> read private write;
  end;


  ActionOption nested in OptionSet = sealed class(Option)
  private
    var  fAction: Action<OptionValueCollection>;

  protected
    method OnParseComplete(optionContext: OptionContext); override;

  public
    constructor (prototype: String;  description: String;  count: Int32;  action: Action<OptionValueCollection>);
  end;


  ActionOption<T> nested in OptionSet = sealed class(Option)
  private
    var fAction: Action<T>;

  protected
    method OnParseComplete(optionContext: OptionContext); override;

  public
    constructor (prototype: String;  description: String;  action: Action<T>);
  end;


  ActionOption<TKey, TValue> nested in OptionSet = sealed class(Option)
  private
    var fAction: OptionAction<TKey, TValue>;

  protected
    method OnParseComplete(optionContext: OptionContext); override;

  public
    constructor (prototype: String;  description: String;  action: OptionAction<TKey, TValue>);
  end;


  OptionAction<TKey, TValue> = public delegate(key: TKey; value: TValue);


  OptionCommandLine = public static class
  public
    class method Parse(const commandLine: String): array of String;
  end;


  ParserState nested in OptionCommandLine = private enum
    (
    Separator,
    Token,
    QuotedToken,
    QuotedTokenStart,
    QuotedTokenEnd);


implementation


{$REGION OptionValueCollection }
constructor OptionValueCollection(optionContext: OptionContext);
begin
  self.fContext := optionContext;
end;


method OptionValueCollection.get_Item(&index: Int32): String;
begin
  self.AssertValid(&index);

	if  (&index < self.fValues.Count)  then
    exit  (self.fValues[&index])
  else
    exit  (nil);
end;


method OptionValueCollection.set_Item(&index: Int32; value: String);
begin
  self.fValues[&index] := value;
end;


method OptionValueCollection.CopyTo(&array: Array; &index: Int32);
begin
  ICollection(self.fValues).CopyTo(&array, &index);
end;


method OptionValueCollection.Add(value: String);
begin
  self.fValues.Add(value);
end;


method OptionValueCollection.Clear();
begin
  self.fValues.Clear();
end;


method OptionValueCollection.Contains(value: String): Boolean;
begin
  exit  (self.fValues.Contains(value));
end;


method OptionValueCollection.CopyTo(&array: array of String; arrayIndex: Int32);
begin
  self.fValues.CopyTo(&array, arrayIndex);
end;


method OptionValueCollection.Remove(value: String): Boolean;
begin
  self.fValues.Remove(value);
end;


method OptionValueCollection.GetEnumerator2(): IEnumerator;
begin
  exit  (self.fValues.GetEnumerator());
end;


method OptionValueCollection.GetEnumerator(): IEnumerator<String>;
begin
  exit  (self.fValues.GetEnumerator());
end;


method OptionValueCollection.Add(value: Object): Int32;
begin
  IList(self.fValues).Add(value);
end;


method OptionValueCollection.Contains(value: Object): Boolean;
begin
  exit  (IList(self.fValues).Contains(value));
end;


method OptionValueCollection.IndexOf(value: Object): Int32;
begin
  exit  (IList(self.fValues).IndexOf(value));
end;


method OptionValueCollection.Insert2(&index: Int32; value: Object);
begin
  IList(self.fValues).Insert(&index, value);
end;


method OptionValueCollection.Remove(value: Object);
begin
  IList(self.fValues).Remove(value);
end;


method OptionValueCollection.RemoveAt2(&index: Int32);
begin
  IList(self.fValues).RemoveAt(&index);
end;


method OptionValueCollection.IndexOf(value: String): Int32;
begin
  exit  (self.fValues.IndexOf(value));
end;


method OptionValueCollection.Insert(&index: Int32;  value: String);
begin
  self.fValues.Insert(&index, value);
end;


method OptionValueCollection.RemoveAt(&index: Int32);
begin
  self.fValues.RemoveAt(&index);
end;


method OptionValueCollection.AssertValid(&index: Int32);
begin
  if  (not assigned(self.fContext.Option))  then
    raise new InvalidOperationException('OptionContext.Option is null.');

  if  (&index >= self.fContext.Option.MaxValueCount)  then
    raise new ArgumentOutOfRangeException('index');

  if  ((self.fContext.Option.OptionValueType = OptionValueType.Required)  and  (&index >= self.fValues.Count)) then
    raise new OptionException(String.Format(self.fContext.OptionSet.MessageLocalizer('Missing required value for option ''{0}''.'), self.fContext.OptionName), self.fContext.OptionName);
end;


method OptionValueCollection.ToList(): List<String>;
begin
  exit  (new List<String>(self.fValues));
end;


method OptionValueCollection.ToArray(): array of String;
begin
  exit  (self.fValues.ToArray());
end;


method OptionValueCollection.ToString(): String;
begin
  exit  (String.Join(', ', self.fValues.ToArray()));
end;
{$ENDREGION}


{$REGION OptionContext }
constructor OptionContext(optionSet: OptionSet);
begin
  self.OptionSet := optionSet;
  self.OptionValues := new OptionValueCollection(self);
end;
{$ENDREGION}


{$REGION Option }
constructor Option(prototype: String;  description: String;  maxValueCount: Int32 := 1);
begin
  if  (not assigned(prototype))  then
    raise new ArgumentNullException('prototype');

  if  (prototype.Length = 0)  then
    raise new ArgumentException('Cannot be an empty string.', 'prototype');

  if  (maxValueCount < 0)  then
    raise new ArgumentOutOfRangeException('maxValueCount');

  self.Prototype := prototype;
  self.Names := prototype.Split('|');
  self.Description := description;
  self.MaxValueCount := maxValueCount;
  self.OptionValueType := self.ParsePrototype();
  
  if  ((self.MaxValueCount = 0) and (self.OptionValueType <> OptionValueType.None))  then
    raise new ArgumentException('Cannot provide maxValueCount of 0 for OptionValueType.Required or ' + 'OptionValueType.Optional.', 'maxValueCount');
  
  if  ((self.OptionValueType = OptionValueType.None) and (maxValueCount > 1))  then
    raise new ArgumentException(String.Format('Cannot provide maxValueCount of {0} for OptionValueType.None.', maxValueCount), 'maxValueCount');

  if  ((Array.IndexOf(self.Names, '<>') >= 0) and 
        (((self.Names.Length = 1) and (self.OptionValueType <> OptionValueType.None))  or
          ((self.Names.Length > 1) and (self.MaxValueCount > 1))))  then
    raise new ArgumentException('The default option handler ''<>'' cannot require values.', 'prototype');
end;


method Option.ParsePrototype(): OptionValueType;
begin
  var  lType: Char := #00;
  var  lSeparators: List<String> := new List<String>();
  var  lNames := self.Names;

  for  i: Int32  :=  0  to  lNames.Length-1 do begin
    var  lName: String := lNames[i];
    if  (String.IsNullOrEmpty(lName))  then
      raise new ArgumentException('Empty option names are not supported.', 'prototype');

    var  lEnd: Int32 := lName.IndexOfAny(Option.NameTerminator);
    if  (lEnd = -1)  then
      continue;

     lNames[i] := lName.Substring(0, lEnd);
     
     if  ((lType = #00) or (lType = lName[lEnd]))  then
       lType := lName[lEnd]
     else
       raise new ArgumentException(String.Format('Conflicting option types: ''{0}'' vs. ''{1}''.', lType, lName[lEnd]), 'prototype');

     Option.AddSeparators(lName, lEnd, lSeparators);
  end;

  if  (lType = #00)  then
    exit  (OptionValueType.None);

  if  ((self.MaxValueCount <= 1) and (lSeparators.Count <> 0))  then
    raise new ArgumentException(String.Format('Cannot provide key/value separators for Options taking {0} value(s).', self.MaxValueCount), 'prototype');

  if  (self.MaxValueCount > 1)  then  begin
    if  (lSeparators.Count = 0)  then
      self.ValueSeparators := [':', '=']
    else if  ((lSeparators.Count = 1)  and  (String.IsNullOrEmpty(lSeparators[0])))  then
        self.ValueSeparators := nil
    else
        self.ValueSeparators := lSeparators.ToArray();
  end;

  exit  (iif(lType = '=', OptionValueType.Required, OptionValueType.Optional));
end;


class method Option.AddSeparators(name: String;  &end: Int32;  separators: ICollection<String>);
begin
  var  lStart: Int32 := -1;

  for  i: Int32  :=  &end+1   to  name.Length-1  do  begin
    case  name[i]  of
      '{':  begin
        if  (lStart <> -1)  then
          raise new ArgumentException(String.Format('Ill-formed name/value separator found in "{0}".', name), 'prototype');

        lStart := i + 1;
      end;
      
      '}':  begin
        if  (lStart = -1)  then
          raise new ArgumentException(String.Format('Ill-formed name/value separator found in "{0}".', name), 'prototype');

        separators.Add(name.Substring(lStart, i - lStart));
        lStart := -1;
      end;
      
      else  begin
        if  (lStart = -1)  then
          separators.Add(name[i].ToString());
      end;
    end;
  end;
  
  if  (lStart <> -1)  then
    raise new ArgumentException(String.Format('Ill-formed name/value separator found in "{0}".', name), 'prototype')
end;


class method Option.Parse<T>(value: String; optionContext: OptionContext): T;
begin
  var  lConverter: TypeConverter := TypeDescriptor.GetConverter(typeOf(T));
  var  lValue: T := default(T);

  try
    if  (assigned(value))  then
      lValue := T(lConverter.ConvertFromString(value))
  except
    on  e: Exception  do
      raise  new OptionException(String.Format(optionContext.OptionSet.MessageLocalizer('Could not convert string `{0}'' to type {1} for option `{2}''.'), value, typeOf(T).Name, optionContext.OptionName),
                             optionContext.OptionName,
                             e);
  end;
  
  exit  (lValue);
end;


method Option.GetNames(): array of String;
begin
  exit  (array of String(self.Names.Clone()));
end;


method Option.GetValueSeparators(): array of String;
begin
  if  (not assigned(self.ValueSeparators))  then
    exit  new String[0];

  exit  (array of String(self.ValueSeparators.Clone()));
end;


method Option.Invoke(optionContext: OptionContext);
begin
  self.OnParseComplete(optionContext);

  optionContext.OptionName := nil;
  optionContext.Option := nil;
  optionContext.OptionValues.Clear();
end;


method Option.ToString(): String;
begin
  exit  (self.Prototype);
end;
{$ENDREGION}


{$REGION OptionException }
constructor OptionException();
begin
end;


constructor OptionException(info: SerializationInfo;  context: StreamingContext);
begin
  inherited constructor(info, context);
  self.OptionName := info.GetString('OptionName');
end;


constructor OptionException(message: String;  optionName: String);
begin
  inherited constructor(message);
  self.OptionName := optionName;
end;


constructor OptionException(message: String;  optionName: String;  innerException: Exception);
begin
  inherited constructor(message, innerException);
  self.OptionName := optionName;
end;


method OptionException.GetObjectData(info: SerializationInfo; context: StreamingContext);
begin
  inherited GetObjectData(info, context);
  info.AddValue('OptionName', self.OptionName);
end;
{$ENDREGION}


{$REGION OptionSet }
constructor OptionSet();
begin
  var lDelegate: Converter<String,String> := method (f: String): String;
                                             begin
                                               exit  (f);
                                             end;

  self.MessageLocalizer := lDelegate;
end;


constructor OptionSet(localizer: Converter<String, String>);
begin
  self.MessageLocalizer := localizer;
end;


method OptionSet.AddImpl(option: Option);
begin
  if  (not  assigned(option))  then
    raise new ArgumentNullException('option');

  var  lAdded: List<String> := new List<String>(option.Names.Length);

  try
    for  i: Int32  :=  1  to  option.Names.Length-1  do  begin
      self.Dictionary.Add(option.Names[i], option);
      lAdded.Add(option.Names[i]);
    end;
  except
    on  Exception  do  begin
      for each  lName: String  in  lAdded  do
        self.Dictionary.Remove(lName);
      raise;
    end;
  end;
end;


class method OptionSet.Unprocessed(extra: ICollection<String>;  definition: Option;  optionContext: OptionContext;  argument: String): Boolean;
begin
  if  (not  assigned(definition))  then  begin
    extra.Add(argument);
    exit  (false);
  end;
  
  optionContext.OptionValues.Add(argument);
  optionContext.Option := definition;
  optionContext.Option.Invoke(optionContext);
  
  exit  (false);
end;


class method OptionSet.Invoke(optionContext: OptionContext;  name: String;  value: String;  option: Option);
begin
  optionContext.OptionName := name;
  optionContext.Option := option;
  optionContext.OptionValues.Add(value);
  
  option.Invoke(optionContext);
end;


method OptionSet.ParseValue(option: String; optionContext: OptionContext);
begin
  if  (assigned(option))  then  begin
    var  lOptionValues: array of String;
    if  (assigned(optionContext.Option.ValueSeparators))  then
      lOptionValues := option.Split(optionContext.Option.ValueSeparators, StringSplitOptions.None)
    else
      lOptionValues := [ option ];
    for each  lOptionValue: String  in  lOptionValues  do
      optionContext.OptionValues.Add(lOptionValue);
  end;
  
  if  (optionContext.OptionValues.Count = optionContext.Option.MaxValueCount)   or
        (optionContext.Option.OptionValueType = OptionValueType.Optional)  then
    optionContext.Option.Invoke(optionContext)
  else
    if  (optionContext.OptionValues.Count > optionContext.Option.MaxValueCount)  then
      raise  new OptionException(
                    self.MessageLocalizer(String.Format('Error: Found {0} option values when expecting {1}.', optionContext.OptionValues.Count, optionContext.Option.MaxValueCount)),
                    optionContext.OptionName);
end;


method OptionSet.ParseBool(option: String; n: String; optionContext: OptionContext): Boolean;
begin
  if  (not  ((n.Length >= 1) and (((n[n.Length - 1] = '+') or (n[n.Length - 1] = '-')))))  then
    exit  (false);

  var  lRN: String := n.Substring(0, n.Length - 1);

  if  (not  self.Contains(lRN))  then
    exit  (false);

  var  lOption: Option := self.Item[lRN];
  var  lValue: String := iif(n[n.Length - 1] = '+', option, nil);
  optionContext.OptionName := option;
  optionContext.Option := lOption;
  optionContext.OptionValues.Add(lValue);
  lOption.Invoke(optionContext);
  
  exit  (true);
end;


method OptionSet.ParseBundledValue(f: String; n: String; optionContext: OptionContext): Boolean;
begin
  if  (f <> '-')  then
    exit  (false);

  for  i: Int32  :=  0 to  n.Length-1  do  begin
    var  lOpt: String := f + n[i].ToString();
    var  lRN: String := n[i].ToString();
    
    if  (not  self.Contains(lRN))  then  begin
      if  (i = 0)  then
        exit  (false);

      raise new OptionException(String.Format(self.MessageLocalizer('Cannot bundle unregistered option ''{0}''.'), lOpt), lOpt)
    end;

    var  lOption: Option := self.Item[lRN];
      
    case  lOption.OptionValueType  of
      OptionValueType.None:  begin
         OptionSet.Invoke(optionContext, lOpt, n, lOption);
      end;
      
      OptionValueType.Optional,
      OptionValueType.Required:  begin
        var  v: String := n.Substring(i + 1);
        optionContext.Option := lOption;
        optionContext.OptionName := lOpt;
        self.ParseValue(iif(v.Length <> 0, v, nil), optionContext);
        
        exit  (true);
      end;
      
      else
        raise new InvalidOperationException('Unknown OptionValueType: ' + lOption.OptionValueType);
    end;
  end;

  exit  (true);
end;


class method OptionSet.GetArgumentName(&index: Int32;  maxIndex: Int32;  description: String): String;
begin
  if  (not  assigned(description))  then
    exit  (iif(maxIndex = 1, 'VALUE', 'VALUE' + (&index + 1)));

  var  lNameStart: array of String;
  if  (maxIndex = 1)  then
    lNameStart := [ '{0:', '{' ]
  else
    lNameStart := [ '{' + &index.ToString(CultureInfo.InvariantCulture) + ':' ];

  for  i: Int32  :=  0  to  lNameStart.Length-1  do  begin
    var  lStart: Int32;
    var  j: Int32 := -1;
    repeat
      inc(j);
      lStart := description.IndexOf(lNameStart[i], j);
    until  (not  iif((lStart >= 0) and (j <> 0), description[j-1] = '{', false));
    
    if  (lStart = -1)  then
      continue;

    var  lEnd: Int32 := description.IndexOf('}', lStart);
    if  (lEnd = -1)  then
      continue;

    exit  (description.Substring(lStart + lNameStart[i].Length, lEnd - lStart - lNameStart[i].Length));
  end;
  
  exit  (iif(maxIndex = 1, 'VALUE', 'VALUE' + (&index + 1)));
end;


class method OptionSet.GetDescription(description: String): String;
begin
  if  (String.IsNullOrEmpty(description))  then
    exit  (String.Empty);

  var  lResult: StringBuilder := new StringBuilder(description.Length);
  var  lStart: Int32 := -1;

  for  i: Int32  :=  0  to  description.Length-1  do  begin
    case  (description[i])  of
      '{':  begin
        if  (i = lStart)  then  begin
          lResult.Append('{');
          lStart := -1
        end
        else
          if  (lStart < 0)  then
            lStart := i + 1;
      end;

      '}':  begin
        if  (lStart < 0)  then  begin
          if  ((i + 1) = description.Length)  or  (description[i + 1] <> '}')  then
            raise  new InvalidOperationException('Invalid option description: ' + description);

          inc(i);
          lResult.Append('}');
        end
        else  begin
          lResult.Append(description.Substring(lStart, i - lStart));
          lStart := -1
        end;
      end;

      ':':  begin
        if  (lStart < 0)  then
          lResult.Append(description[i])
        else
          lStart := i + 1;
      end;

      else  begin
        if  (lStart < 0)  then
          lResult.Append(description[i])
      end;
    end;
  end;

  exit  (lResult.ToString());
end;


class method OptionSet.GetLines(description: String): List<String>;
begin
  var  lLines: List<String> := new List<String>();
  if  (String.IsNullOrEmpty(description))  then  begin
    lLines.Add(String.Empty);
    exit  (lLines);
  end;

  var  lLength: Int32 := 80 - OptionSet.OPTION_WIDTH - 2;
  var  lStart: Int32 := 0;
  var  lEnd: Int32;
  var  lDescriptionLength: Int32 := description.Length;

  repeat
    lEnd := OptionSet.GetLineEnd(lStart, lLength, description);
    
    var  lContinue: Boolean := false;

    if  (lEnd < lDescriptionLength)  then  begin
      var  lChar: Char := description[lEnd];

      if  ((lChar = '-')  or 
            (Char.IsWhiteSpace(lChar) and (not (lChar in [ #10, #13 ]))))  then
        inc(lEnd)
      else
        if  (not (lChar in [ #10, #13 ]))  then  begin
          lContinue := true;
          dec(lEnd);
        end;
    end;

    lLines.Add(description.Substring(lStart, lEnd-lStart));
    
    if  (lContinue)  then
      lLines[lLines.Count-1] := lLines[lLines.Count-1] + '-';

    lStart := lEnd;
    
    if  ((lStart < lDescriptionLength)  and  (description[lStart] in [ #10, #13 ]))  then
      inc(lStart);
  until  (not (lEnd < lDescriptionLength));
  
  exit  (lLines);
end;


class method OptionSet.GetLineEnd(start: Int32;  length: Int32;  description: String): Int32;
begin
  var  lEnd: Int32 := Math.Min(start + length, description.Length);
  var  lSeparator: Int32 := -1;
  
  for  i: Int32  :=  start  to  lEnd-1  do
    case  description[i]  of
      ' ',
      #09,
      '-',
      ',',
      '.',
      ';':  lSeparator := i;
      #10,
      #13: exit  (i);
    end;

  if  ((lSeparator = -1)  or  (lEnd = description.Length))  then
    exit  (lEnd);

  exit  (lSeparator);
end;


method OptionSet.GetKeyForItem(item: Option): String;
begin
  if  (not assigned(item))  then
    raise new ArgumentNullException('option');

  if  (assigned(item.Names)  and  (item.Names.Length > 0))  then
    exit  (item.Names[0]);

  raise  new InvalidOperationException('Option has no names!');
end;


method OptionSet.GetOptionForName(option: String): Option;
begin
  if  (not assigned(option))  then
    raise new ArgumentNullException('option');

  try
    exit  (inherited  Item[option]);
  except
    on  KeyNotFoundException  do
      exit  (nil);
  end;
end;


method OptionSet.InsertItem(&index: Int32;  item: Option);
begin
  inherited  InsertItem(&index, item);
  
  self.AddImpl(item);
end;


method OptionSet.RemoveItem(&index: Int32);
begin
  inherited  RemoveItem(&index);
  
  var  lOption: Option := self.Items[&index];
  var  lDictionary := self.Dictionary;

	for  i: Int32  :=  1  to  lOption.Names.Length  do
    lDictionary.Remove(lOption.Names[i]);
end;


method OptionSet.SetItem(&index: Int32;  item: Option);
begin
  inherited SetItem(&index, item);
  
  self.RemoveItem(&index);
  self.AddImpl(item);
end;


method OptionSet.CreateOptionContext(): OptionContext;
begin
  exit  (new OptionContext(self));
end;


method OptionSet.GetOptionParts(argument: String; out flag: String; out name: String; out separator: String; out value: String): Boolean;
begin
  if  (not assigned(argument))  then
    raise new ArgumentNullException('argument');

  flag := nil;
  name := nil;
  separator := nil;
  value := nil;

  var  lMatch: Match := self.fValueOption.Match(argument);
  if  (not  lMatch.Success)  then
    exit  (false);

  flag := lMatch.Groups['flag'].Value;
  name := lMatch.Groups['name'].Value;
  if  ((lMatch.Groups['sep'].Success) and (lMatch.Groups['value'].Success))  then  begin
    separator := lMatch.Groups['sep'].Value;
    value := lMatch.Groups['value'].Value
  end;

  exit  (true);
end;


method OptionSet.Parse(argument: String; optionContext: OptionContext): Boolean;
begin
  if  (assigned(optionContext.Option))  then  begin
    self.ParseValue(argument, optionContext);
    exit  (true);
  end;

  var  lFlag: String;
  var  lName: String;
  var  lSeparator: String;
  var  lValue: String;
  if  (not  self.GetOptionParts(argument, out lFlag, out lName, out lSeparator, out lValue))  then
    exit  (false);

  if  (self.Contains(lName))  then  begin
    var lOption: Option  :=  self.Item[lName];
    optionContext.OptionName := lFlag + lName;
    optionContext.Option := lOption;
    
    case  lOption.OptionValueType  of
      OptionValueType.None: begin
        optionContext.OptionValues.Add(lName);
        optionContext.Option.Invoke(optionContext);
      end;

      OptionValueType.Optional,
      OptionValueType.Required: begin
        self.ParseValue(lValue, optionContext);
      end;
    end;

    exit  (true);
  end;

  // no match; is it a bool option?
  if  (self.ParseBool(argument, lName, optionContext))  then
    exit  (true);

  // is it a bundled option?
  if  (self.ParseBundledValue(lFlag, String.Concat(lName + lSeparator + lValue), optionContext))  then
    exit  (true);

  exit  (false);
end;


{$REGION OptionSet.Add overloads }
method OptionSet.Add(option: Option): OptionSet;
begin
  inherited &Add(option);
  exit  (self);
end;


method OptionSet.Add(prototype: String;  action: Action<String>): OptionSet;
begin
  exit  (self.Add(prototype, nil, action));
end;


method OptionSet.Add(prototype: String;  description: String;  action: Action<String>): OptionSet;
begin
  if  (not  assigned(action))  then
    raise  new ArgumentNullException('action');

  var  lOption: Option := new ActionOption(prototype, description, 1,   method (v: OptionValueCollection);
                                                                        begin
                                                                          action(v[0]);
                                                                        end);
  inherited  &Add(lOption);
  
  exit  (self);
end;


method OptionSet.Add(prototype: String;  action: OptionAction<String, String>): OptionSet;
begin
  exit  (self.Add(prototype, nil, action));
end;


method OptionSet.Add(prototype: String;  description: String;  action: OptionAction<String, String>): OptionSet;
begin
  if  (not  assigned(action))  then
    raise  new ArgumentNullException('action');

  var  lOption: Option := new ActionOption(prototype, description, 2,  method (v: OptionValueCollection);
                                                                       begin
                                                                         action(v[0], v[1]);
                                                                       end);

  inherited  &Add(lOption);
  
  exit  (self);
end;


method OptionSet.Add<T>(prototype: String;  action: Action<T>): OptionSet;
begin
  exit  (self.Add(prototype, nil, action));
end;


method OptionSet.Add<T>(prototype: String;  description: String;  action: Action<T>): OptionSet;
begin
  exit  (self.Add(new ActionOption<T>(prototype, description, action)));
end;


method OptionSet.Add<TKey, TValue>(prototype: String;  action: OptionAction<TKey, TValue>): OptionSet;
begin
  exit  (self.Add(prototype, nil, action));
end;


method OptionSet.Add<TKey, TValue>(prototype: String;  description: String;  action: OptionAction<TKey, TValue>): OptionSet;
begin
  exit  self.Add(new ActionOption<TKey, TValue>(prototype, description, action));
end;
{$ENDREGION}


method OptionSet.Parse(arguments: IEnumerable<String>): List<String>;
begin
  var lContext: OptionContext := self.CreateOptionContext();
  lContext.OptionIndex := -1;

  var  lProcessed: Boolean := true;
  var  lUnprocessed: List<String> := new List<String>();

  var  lDefinition: Option := nil;
  if  (self.Contains('<>'))  then
    lDefinition := self.Item['<>'];

  for each  lArgument: String  in  arguments  do  begin
    lContext.OptionIndex := lContext.OptionIndex + 1;

    if  (lArgument = '--')  then  begin
      lProcessed := false;
      continue;
    end;

    if  (not lProcessed)  then  begin
      OptionSet.Unprocessed(lUnprocessed, lDefinition,  lContext,  lArgument);
      continue
    end;

    if  (not Parse(lArgument, lContext))  then
      OptionSet.Unprocessed(lUnprocessed, lDefinition, lContext, lArgument);
  end;

  if  (assigned(lContext.Option))  then
    lContext.Option.Invoke(lContext);

  exit  (lUnprocessed);
end;


method OptionSet.Parse(argument: String): List<String>;
begin
  exit  (self.Parse(OptionCommandLine.Parse(argument)));
end;


method OptionSet.WriteOptionDescriptions(o: TextWriter);
begin
  for each  lOption: Option  in  self.Items  do  begin
    var  lWritten: Int32 := 0;
    
    if  (not self.WriteOptionPrototype(o, lOption, var lWritten))  then
      continue;

    if  (lWritten < OptionSet.OPTION_WIDTH)  then
      o.Write(new String(' ', OptionSet.OPTION_WIDTH - lWritten))
    else  begin
      o.WriteLine();
      o.Write(new String(' ', OptionSet.OPTION_WIDTH))
    end;

    var  lLines: List<String> := OptionSet.GetLines(self.MessageLocalizer(OptionSet.GetDescription(lOption.Description)));
    o.WriteLine(lLines[0]);
    
    var lPrefix: String := new String(' ', OptionSet.OPTION_WIDTH + 2);

    for  I: Int32  :=  1  to  lLines.Count-1  do  begin
      o.Write(lPrefix);
      o.WriteLine(lLines[I]);
    end;
  end;
end;


method OptionSet.WriteOptionPrototype(o: TextWriter;  p: Option;  var written: Int32): Boolean;
begin
  var  lNames: array of String := p.Names;

  var  i: Int32 := OptionSet.GetNextOptionIndex(lNames, 0);
  var  lNamesLength := lNames.Length;
  if  (i = lNamesLength)  then
    exit  (false);

  if  (lNames[i].Length = 1)  then begin
    OptionSet.Write(o, var written, '  -');
    OptionSet.Write(o, var written, lNames[0]);
  end
  else begin
    OptionSet.Write(o, var written, '      --');
    OptionSet.Write(o, var written, lNames[0]);
  end;

  i := OptionSet.GetNextOptionIndex(lNames, i + 1);
  while  i < lNamesLength  do  begin
    OptionSet.Write(o, var written, ', ');
    OptionSet.Write(o, var written, iif(lNames[i].Length = 1, '-', '--'));
    OptionSet.Write(o, var written, lNames[i]);

    i := OptionSet.GetNextOptionIndex(lNames, i + 1);
  end;

  if  ((p.OptionValueType = OptionValueType.Optional)  Or  (p.OptionValueType = OptionValueType.Required))  then  begin
    if  (p.OptionValueType = OptionValueType.Optional) then
      OptionSet.Write(o, var written, self.MessageLocalizer('['));

    OptionSet.Write(o, var written, self.MessageLocalizer('=' + OptionSet.GetArgumentName(0, p.MaxValueCount, p.Description)));

    var  lSeparator: String;
    if  (assigned(p.ValueSeparators)  And  (p.ValueSeparators.Length > 0))  then
      lSeparator := p.ValueSeparators[0]
    else
      lSeparator := ' ';

    for  J: Int32  :=  1  to  p.MaxValueCount-1  do
      OptionSet.Write(o, var written, self.MessageLocalizer(lSeparator + OptionSet.GetArgumentName(J, p.MaxValueCount, p.Description)));

    if  (p.OptionValueType = OptionValueType.Optional)  then
      OptionSet.Write(o, var written, self.MessageLocalizer(']'))
  end;

  exit (true);
end;


class method OptionSet.GetNextOptionIndex(names: array of String;  i: Int32): Int32;
begin
  while  ((i < names.Length)  And  (names[i] = '<>'))  do
    inc(i);

  exit  (i);
end;


class method OptionSet.Write(o: TextWriter;  var n: Int32;  s: String);
begin
  if  (not assigned(s))  then
    exit;

  n := n + s.Length;
  o.Write(s);
end;
{$ENDREGION}


{$REGION OptionSet.ActionOption }
constructor OptionSet.ActionOption(prototype: String;  description: String;  count: Int32;  action: Action<OptionValueCollection>);
begin
  if  (not assigned(action))  then
    raise new ArgumentNullException('action');

  inherited constructor(prototype, description, count);

  self.fAction := action;
end;


method OptionSet.ActionOption.OnParseComplete(optionContext: OptionContext);
begin
  self.fAction(optionContext.OptionValues);
end;
{$ENDREGION}


{$REGION OptionSet.ActionOption<T> }
constructor OptionSet.ActionOption<T>(prototype: String;  description: String;  action: Action<T>);
begin
  if  (not assigned(action))  then
    raise new ArgumentNullException('action');

  inherited constructor(prototype, description, 1);

  self.fAction := action;
end;


method OptionSet.ActionOption<T>.OnParseComplete(optionContext: OptionContext);
begin
  self.fAction(Parse<T>(optionContext.OptionValues[0], optionContext));
end;
{$ENDREGION}


{$REGION OptionSet.ActionOption<TKey,TValue> }
constructor OptionSet.ActionOption<TKey,TValue>(prototype: String;  description: String;  action: OptionAction<TKey, TValue>);
begin
  if  (not assigned(action))  then
    raise new ArgumentNullException('action');

  inherited constructor(prototype, description, 2);

  self.fAction := action;
end;


method OptionSet.ActionOption<TKey,TValue>.OnParseComplete(optionContext: OptionContext);
begin
  self.fAction(Parse<TKey>(optionContext.OptionValues[0], optionContext), Parse<TValue>(optionContext.OptionValues[1], optionContext));
end;
{$ENDREGION}


{$REGION OptionCommandLine }
class method OptionCommandLine.Parse(const commandLine: String): array of String;
  method ExtractItem(const source: String;  startIndex: Int32;  endIndex: Int32): String;
  begin
    if  (endIndex < startIndex)  then
      exit  (String.Empty);

    exit  (source.Substring(startIndex, endIndex-startIndex+1));
  end;
begin
  if  (not  assigned(commandLine))  then
    exit  (nil);

  if  (commandLine = String.Empty)  then
    exit  ([]);

  // Ordinary Finite-State machine
  var  lParserState: OptionCommandLine.ParserState := OptionCommandLine.ParserState.Separator;
  var  lResult: List<String> := new List<String>(16);
  var  lStartIndex: Int32 := -1;
  var  lParserPosition: Int32 := 0;
  var  lCommandLineLength: Int32 := commandLine.Length;

  while  (true)  do  begin
    if  (lParserPosition >= lCommandLineLength)  then  begin
      case  lParserState  of
        OptionCommandLine.ParserState.QuotedToken,
        OptionCommandLine.ParserState.QuotedTokenStart,
        OptionCommandLine.ParserState.Token:
          lResult.Add(ExtractItem(commandLine, lStartIndex, lParserPosition-1));
        
        OptionCommandLine.ParserState.QuotedTokenEnd:
          lResult.Add(ExtractItem(commandLine, lStartIndex, lParserPosition-1));

        OptionCommandLine.ParserState.Separator:
          ;
      end; // case
      break;
    end;

    var  lParserChar: Char := commandLine[lParserPosition];

    case  lParserState  of
      OptionCommandLine.ParserState.Separator:
        case  lParserChar  of
          ' ',
          #13,
          #10,
          #09:  ;

          '"':  begin
            lStartIndex := lParserPosition;
            lParserState := OptionCommandLine.ParserState.QuotedTokenStart;
          end;

          else  begin
            lStartIndex := lParserPosition;
            lParserState := OptionCommandLine.ParserState.Token;
          end;
        end;

      OptionCommandLine.ParserState.Token:
        case  lParserChar  of
          ' ',
          #13,
          #10,
          #09:  begin
            lResult.Add(ExtractItem(commandLine, lStartIndex, lParserPosition-1));
            lParserState := OptionCommandLine.ParserState.Separator;
          end;

          '"':
            lParserState := OptionCommandLine.ParserState.QuotedToken;
        end;

      OptionCommandLine.ParserState.QuotedToken:
         case  lParserChar  of
           '"': lParserState := OptionCommandLine.ParserState.QuotedTokenEnd;
         end;
      
      OptionCommandLine.ParserState.QuotedTokenStart:
         case  lParserChar  of
           '"': lParserState := OptionCommandLine.ParserState.QuotedTokenEnd;

           else  lParserState := OptionCommandLine.ParserState.QuotedToken;
         end;

      OptionCommandLine.ParserState.QuotedTokenEnd:
         case  lParserChar  of
          ' ',
          #13,
          #10,
          #09:  begin
            lResult.Add(ExtractItem(commandLine, lStartIndex, lParserPosition-1));
            lParserState := OptionCommandLine.ParserState.Separator;
          end;

          else  lParserState := OptionCommandLine.ParserState.QuotedToken;
         end;
    end; // case

    inc(lParserPosition);
  end;

  exit  (lResult.ToArray());
end;
{$ENDREGION}


end.