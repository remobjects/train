namespace RemObjects.Builder.API;

interface

uses
  System.Collections.Generic,
  System.Text;

type
  [PluginRegistration]
  Mail = public class(IPluginRegistration)
  private
  protected
  public
    method &Register(aServices: IApiRegistrationServices);
  end;

implementation

method Mail.&Register(aServices: IApiRegistrationServices);
begin
  aServices.RegisterValue('mail', new RemObjects.Script.EcmaScript.EcmaScriptObject(aSErvices.Globals)
  .AddValue('send', RemObjects.Builder.Utilities.SimpleFunction(aServices.Engine, method (ec: RemObjects.Script.EcmaScript.ExecutionContext; o: Object; args: array of Object): Object begin
    aServices.Logger.Enter('mail.send', args);
    try
      var lMailMsg := new System.Net.Mail.MailMessage(
        RemObjects.Script.EcmaScript.Utilities.GetArgAsString(args, 0, ec),
        RemObjects.Script.EcmaScript.Utilities.GetArgAsString(args, 1, ec),
        RemObjects.Script.EcmaScript.Utilities.GetArgAsString(args, 2, ec),
        RemObjects.Script.EcmaScript.Utilities.GetArgAsString(args, 3, ec));
      var lOpt := RemObjects.Script.EcmaScript.EcmaScriptObject(RemObjects.Script.EcmaScript.Utilities.GetArg(args, 4));
      var lSMTPServer := string(aServices.Environment['SMTP_Server']);
      if lSMTPServer = nil then raise new Exception('No smtp server configured (SMTP_Server key)');
      var lSMTP := new System.Net.Mail.SmtpClient(lSMTPServer);
      var lUN := String(aSErvices.Environment['SMTP_ServerLogin']);
      var lPW := String(aSErvices.Environment['SMTP_ServerPassword']);
      if assigned(lUN) and assigned(lPW) then 
        lSMTP.Credentials := new System.Net.NetworkCredential(lUN, lPW);
      if lOpt <> nil then begin
        var lArr := RemObjects.Script.EcmaScript.EcmaScriptArrayObject(lOpt.Get(ec, 0, 'attachments'));
        var s := string(lOpt.Get(ec, 0, 'bcc'));
        if s <> nil then 
          lMailMsg.Bcc.Add(s);
        s := string(lOpt.Get(ec, 0, 'cc'));
        if s <> nil then 
          lMailMsg.cc.Add(s);

        if assigned(larr) then
        for i: Integer := 0 to lArr.Length -1 do begin
          var lObj := RemObjects.Script.EcmaScript.EcmaScriptObject(lArr.Get(ec, 0, i.ToString));
          if lObj <> nil then begin
            var lName := string(lObj.Get(ec, 0, 'name'));
            var lData := string(lObj.Get(ec, 0, 'data'));
            var lFilename := string(lObj.Get(ec, 0, 'filename'));
            if (lData = nil) and (lFilename = nil) then continue;
            if lData <> nil then begin
              lMailMSg.Attachments.Add(new System.Net.Mail.Attachment(new System.IO.MemoryStream(Encoding.UTF8.GetBytes(lData)), lName));
            end else begin
              lFilename := aServices.ResolveWithBase(lFilename);
              var lAtt2 := new System.Net.Mail.Attachment(lFilename);
              if lName <> nil then lAtt2.Name := lName;
              lMailMSg.Attachments.Add(lAtt2);
            end;
          end;
        end;
      end;
      lSMTP.Send(lMailMsg);
    finally
      aSErvices.Logger.Exit('mail.send', args);
    end;
  end)));
end;

end.
