namespace RemObjects.Train;

interface

type
  PluginSystem = public static class
  private
    class var TrainLib, ScriptLib: System.Reflection.&Assembly;
    class method Resolve(o: Object; args: ResolveEventArgs): System.Reflection.&Assembly;
  public
    class constructor;
    class method Load(fn: String);
  end;

implementation

class method PluginSystem.Load(fn: String);
begin
  System.Reflection.Assembly.LoadFile(fn);
end;

class constructor PluginSystem;
begin
  TrainLib := typeOf(PluginSystem).Assembly;
  ScriptLib := typeOf(RemObjects.Script.EcmaScript.EcmaScriptArrayObject).Assembly;

  AppDomain.CurrentDomain.AssemblyResolve += Resolve;
end;

class method PluginSystem.Resolve(o: Object; args: ResolveEventArgs): System.Reflection.&Assembly;
begin
  var name := args.Name.Split(',')[0].Trim.ToLowerInvariant;
  if name = 'remobjects.script' then
    exit ScriptLib;
  if name = 'remobjects.train' then
    exit TrainLib;
  exit nil;
end;

end.