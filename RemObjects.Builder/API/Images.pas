namespace RemObjects.Builder.API;

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
    class method ImagesCreateISO(aServices: IApiRegistrationServices; isoFile, basefolder: String; filemasklist: string; aDiskName: string; aRecurse: Boolean := true);
    [WrapAs('images.createDMG', SkipDryRun := true)]
    class method ImagesCreateDMG(aServices: IApiRegistrationServices; isoFile, basefolder: String; filemasklist: string; aDiskName: string; aRecurse: Boolean := true);
  end;

implementation

method ImagesPlugin.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterObjectValue('images')
    .AddValue('createISO', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, typeof(ImagesPlugin), 'ImagesCreateISO'))
    .AddValue('createDMG', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, typeof(ImagesPlugin), 'ImagesCreateDMG'));
end;

class method ImagesPlugin.ImagesCreateISO(aServices: IApiRegistrationServices; isoFile: String; basefolder: String; filemasklist: string; aDiskName: string; aRecurse: Boolean := true);
begin
  if string.IsNullOrEmpty(filemasklist) then filemasklist := '*';
  basefolder := aServices.ResolveWithBase(basefolder);
  if not basefolder.EndsWith(System.IO.Path.DirectorySeparatorChar) then 
    basefolder := basefolder + System.IO.Path.DirectorySeparatorChar;
  var lDisk := new DiscUtils.Iso9660.CDBuilder();
  lDisk.VolumeIdentifier := aDiskName;
  lDisk.UseJoliet := true;
  for each el in System.IO.Directory.EnumerateFiles(basefolder, filemasklist, if aRecurse then System.IO.SearchOption.AllDirectories else System.IO.SearchOption.TopDirectoryOnly) do begin
    var lFal := el;
    if lFal.StartsWith(basefolder) then
      lFal := lFal.Substring(basefolder.Length);
    lDisk.AddFile(lFal, el);
  end;
  lDisk.Build(aServices.ResolveWithBase(isoFile));
end;

class method ImagesPlugin.ImagesCreateDMG(aServices: IApiRegistrationServices; isoFile: String; basefolder: String; filemasklist: string; aDiskName: string; aRecurse: Boolean := true);
begin
  if string.IsNullOrEmpty(filemasklist) then filemasklist := '*';
  basefolder := aServices.ResolveWithBase(basefolder);
  if not basefolder.EndsWith(System.IO.Path.DirectorySeparatorChar) then 
    basefolder := basefolder + System.IO.Path.DirectorySeparatorChar;

  raise new NotImplementedException;
end;

end.
