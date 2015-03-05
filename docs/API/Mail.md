---
title: Mail
---

Mail sending plugin. Requires these env vars to be set:
* **SMTP_Server**:  SMTP server
* **SMTP_ServerLogin** Optional login
* **SMTP_ServerPassword** Optional password

* **mail.send(from, to, subject, body, options)** Send an email
```
options:{
  bcc
  cc
  attachments: [{
   name
   data: string or filename
  }]
}
```