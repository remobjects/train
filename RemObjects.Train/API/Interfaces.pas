namespace RemObjects.Train.API;

interface

uses 
  RemObjects.Train,
  RemObjects.Script.EcmaScript;

type
  IApiRegistrationServices = public interface
    method RegisterValue(aName: String; aValue: Object); 
    method RegisterObjectValue(aName: String): EcmaScriptObject;
    method RegisterProperty(aName: String; aGet: Func<Object>; aSet: Action<Object>);
    method RegisterTask(aTask: System.Threading.Tasks.Task; aSignature: String; aLogger: DelayedLogger);
    method UnregisterTask(aTask: System.Threading.Tasks.Task);
    
    property Environment: Environment read;
    property Globals: GlobalObject read;
    property Engine: Engine read;
    property Logger: ILogger read;
    property AsyncWorker: AsyncWorker read write;
    method ResolveWithBase(ec: ExecutionContext;s: String): String;
  end;

  IPluginRegistration = public interface
    method Register(aServices: IApiRegistrationServices);
  end;

  [AttributeUsage(AttributeTargets.Class)]
  PluginRegistrationAttribute = public class(Attribute)
  public
    constructor; empty;
  end;

implementation

end.
