namespace RemObjects.Train.API;

interface

uses
  System.Collections.Generic,
  System.Text;

type
  [PluginRegistration()]
  ImagesPlugin = public class(IPluginRegistration)
  private
  protected
  public
    method &Register(aServices: IApiRegistrationServices);

    [WrapAs('images.createISO', SkipDryRun := true)]
    class method ImagesCreateISO(aServices: IApiRegistrationServices; ec: RemObjects.Script.EcmaScript.ExecutionContext;isoFile, basefolder: String; filemasklist: String; aDiskName: String; aRecurse: Boolean := true);
    [WrapAs('images.createDMG', SkipDryRun := true)]
    class method ImagesCreateDMG(aServices: IApiRegistrationServices; ec: RemObjects.Script.EcmaScript.ExecutionContext;isoFile, basefolder: String; filemasklist: String; aDiskName: String; aRecurse: Boolean := true);
  end;

implementation

method ImagesPlugin.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterObjectValue('images')
    .AddValue('createISO', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(ImagesPlugin), 'ImagesCreateISO'))
    .AddValue('createDMG', RemObjects.Train.MUtilities.SimpleFunction(aServices.Engine, typeOf(ImagesPlugin), 'ImagesCreateDMG'));
end;

class method ImagesPlugin.ImagesCreateISO(aServices: IApiRegistrationServices; ec: RemObjects.Script.EcmaScript.ExecutionContext; isoFile: String; basefolder: String; filemasklist: String; aDiskName: String; aRecurse: Boolean := true);
begin
  if String.IsNullOrEmpty(filemasklist) then filemasklist := '*';
  basefolder := aServices.ResolveWithBase(ec,basefolder);
  if not basefolder.EndsWith(System.IO.Path.DirectorySeparatorChar) then 
    basefolder := basefolder + System.IO.Path.DirectorySeparatorChar;
  var lDisk := new DiscUtils.Iso9660.CDBuilder();
  lDisk.VolumeIdentifier := aDiskName;
  lDisk.UseJoliet := true;
  for each mask in filemasklist.Split([';'], StringSplitOptions.RemoveEmptyEntries) do 
  for each el in System.IO.Directory.EnumerateFiles(basefolder, mask, if aRecurse then System.IO.SearchOption.AllDirectories else System.IO.SearchOption.TopDirectoryOnly) do begin
    var lFal := el;
    if lFal.StartsWith(basefolder) then
      lFal := lFal.Substring(basefolder.Length);
    lDisk.AddFile(lFal, el);
  end;
  lDisk.Build(aServices.ResolveWithBase(ec,isoFile));
end;

class method ImagesPlugin.ImagesCreateDMG(aServices: IApiRegistrationServices; ec: RemObjects.Script.EcmaScript.ExecutionContext;isoFile: String; basefolder: String; filemasklist: String; aDiskName: String; aRecurse: Boolean := true);
begin
  if String.IsNullOrEmpty(filemasklist) then filemasklist := '*';
  basefolder := aServices.ResolveWithBase(ec,basefolder);
  if not basefolder.EndsWith(System.IO.Path.DirectorySeparatorChar) then 
    basefolder := basefolder + System.IO.Path.DirectorySeparatorChar;

  raise new NotImplementedException;
end;

end.
