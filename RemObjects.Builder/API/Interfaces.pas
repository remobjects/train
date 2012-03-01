namespace RemObjects.Builder.API;

interface

uses 
  RemObjects.Builder,
  RemObjects.Script.EcmaScript;

type
  IApiRegistrationServices = public interface
    method RegisterValue(aName: string; aValue: Object); 
    method RegisterProperty(aName: string; aGet: Func<Object>; aSet: Action<Object>);
    
    property Environment: Environment read;
    property Globals: GlobalObject read;
    property Engine: Engine read;
    property Logger: ILogger read;
    property AsyncWorker: AsyncWorker read write;
    method ResolveWithBase(s: string): string;
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
