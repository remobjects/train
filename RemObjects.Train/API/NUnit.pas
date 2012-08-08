namespace RemObjects.Train.API;

interface

uses
  RemObjects.Train,
  System.Threading,
  System.Text,
  RemObjects.Script.EcmaScript, 
  RemObjects.Script.EcmaScript.Internal;
type

  [PluginRegistration]
  NUnitPlugin = public class(IPluginRegistration)
  private
  protected
  public
    method &Register(aServices: IApiRegistrationServices);
    [WrapAs('nunit.run')]
    class method NUnitRun(aServices: IApiRegistrationServices;  ec: ExecutionContext; aFilename: String);
  end;

  NUnitPluginEventListener = public class(NUnit.Core.EventListener)
  private
  public
    method RunStarted(name: System.String; testCount: System.Int32); empty;
    method TestOutput(testOutput: NUnit.Core.TestOutput); empty;
    method UnhandledException(exception: System.Exception);
    method SuiteFinished(&result: NUnit.Core.TestResult); empty;
    method SuiteStarted(testName: NUnit.Core.TestName); empty;
    method TestFinished(&result: NUnit.Core.TestResult);
    method TestStarted(testName: NUnit.Core.TestName); empty;
    method RunFinished(&result: NUnit.Core.TestResult); empty;
    method RunFinished(exception: Exception); empty;
    property Log: StringBuilder := new StringBuilder();
  end;

implementation

uses
  System.IO,
  NUnit.*;

method NUnitPluginEventListener.TestFinished(&result: NUnit.Core.TestResult);
begin
 if &result.IsFailure then
 begin
   self.Log.AppendLine();
   self.Log.Append('Test Failed: ');
   self.Log.AppendLine(&result.FullName);
   self.Log.AppendLine(&result.Message);   
 end;
end;

method NUnitPluginEventListener.UnhandledException(exception: System.Exception);
begin
  raise exception;
end;

method NUnitPlugin.&Register(aServices: IApiRegistrationServices);
begin
   aServices.RegisterObjectValue('nunit')
    .AddValue('run', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(NUnitPlugin), 'NUnitRun'));
end;

class method NUnitPlugin.NUnitRun(aServices: IApiRegistrationServices;  ec: ExecutionContext; aFilename: String);
begin
  aFilename := aServices.ResolveWithBase(ec, aFilename);
  aServices.Logger.LogMessage('Running Unit Tests in this file : ' + aFilename);
  CoreExtensions.Host.InitializeService(); 
  var runner := new SimpleTestRunner();
  var testPackage := new TestPackage(aFilename);
  if runner.Load(testPackage) then
  begin
    var el := new NUnitPluginEventListener();
    var testresult := runner.Run(el, TestFilter.Empty, false, LoggingThreshold.All);
    var summ := new ResultSummarizer(testresult);
    aServices.Logger.LogMessage('Errors : ' + summ.Errors.ToString);
    aServices.Logger.LogMessage('Failures : ' + summ.Failures.ToString);
    aServices.Logger.LogMessage('Ignored : ' + summ.Ignored.ToString);
    aServices.Logger.LogMessage('Passed : ' + summ.Passed.ToString);
    aServices.Logger.LogMessage('Tests Run : ' + summ.TestsRun.ToString);  
    if el.Log.Length > 0 then raise new Exception(el.Log.ToString()); 
    aServices.Logger.LogMessage('All Tests were successfull');  
  end
  else raise new Exception('Could not load test assembly!');
end;

end.
