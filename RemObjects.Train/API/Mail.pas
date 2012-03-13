namespace RemObjects.Train.API;

interface

uses
  System.Collections.Generic,
  System.Text;

type
  [PluginRegistration]
  MailReg = public class(IPluginRegistration)
  private
  protected
  public
    method &Register(aServices: IApiRegistrationServices);

    [WrapAs('mail.send')]
    class method MailSend(aServices: IApiRegistrationServices; ec: RemObjects.Script.EcmaScript.ExecutionContext;
      aFrom: String := nil; 
      aTo: String := nil;
      aSubject: String:= nil;
      aBody: String := nil;
      aOpt: MailOptions := nil);
  end;

  MailOptions = public class
  private
  public
    property bcc: String;
    property cc: String;
    property attachments: array of MailAttachment;
  end;

  MailAttachment = public class
  private
  public
    property name: String;
    property data: String;
    property filename: String;
  end;


implementation


method MailReg.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterValue('mail', new RemObjects.Script.EcmaScript.EcmaScriptObject(aServices.Globals)
  .AddValue('send', RemObjects.Train.Utilities.SimpleFunction(aServices.Engine, typeOf(MailReg), 'MailSend'))
  );
end;

class method MailReg.MailSend(aServices: IApiRegistrationServices; ec: RemObjects.Script.EcmaScript.ExecutionContext;aFrom: String; aTo: String; aSubject: String; aBody: String; aOpt: MailOptions);
begin
  var lMailMsg := new System.Net.Mail.MailMessage(aFrom, aTo, aSubject, aBody);
  var lSMTPServer := String(aServices.Environment['SMTP_Server']);
  if lSMTPServer = nil then raise new Exception('No smtp server configured (SMTP_Server key)');
  var lSMTP := new System.Net.Mail.SmtpClient(lSMTPServer);
  var lUN := String(aServices.Environment['SMTP_ServerLogin']);
  var lPW := String(aServices.Environment['SMTP_ServerPassword']);
  if assigned(lUN) and assigned(lPW) then 
    lSMTP.Credentials := new System.Net.NetworkCredential(lUN, lPW);
  if aServices.Engine.DryRun then exit;
  if aOpt <> nil then begin
    if String.IsNullOrEmpty(aOpt.cc) then
      lMailMsg.CC.Add(aOpt.cc);
    if String.IsNullOrEmpty(aOpt.bcc) then
      lMailMsg.Bcc.Add(aOpt.bcc);
    for each el in aOpt.attachments do begin
      if (el.data = nil) and (el.filename = nil) then continue;
      if el.data <> nil then begin
        lMailMsg.Attachments.Add(new System.Net.Mail.Attachment(new System.IO.MemoryStream(Encoding.UTF8.GetBytes(el.data)), el.name));
      end else begin
        var lAtt2 := new System.Net.Mail.Attachment(aServices.ResolveWithBase(ec,el.filename));
        if el.name <> nil then lAtt2.Name := el.name;
        lMailMsg.Attachments.Add(lAtt2);
      end;
    end;
  end;
  lSMTP.Send(lMailMsg);
end;

end.
