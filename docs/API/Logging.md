---
title: Logging
---

* **log(messageFMT, Data...)** - If the "Data..." arguments are missing, the message will be emitted as-is, else they'll use .net "String.Format" style formatting. Logs as a message.
* **log.error(messageFMT, Data...)** - If the "Data..." arguments are missing, the message will be emitted as-is, else they'll use .net "String.Format" style formatting. Logs as an error.
* **log.warning(messageFMT, Data...)** - If the "Data..." arguments are missing, the message will be emitted as-is, else they'll use .net "String.Format" style formatting. Logs as a warning.
* **log.debug(messageFMT, Data...)** - If the "Data..." arguments are missing, the message will be emitted as-is, else they'll use .net "String.Format" style formatting. Logs as a debug message.
* **log.message(messageFMT, Data...)** - If the "Data..." arguments are missing, the message will be emitted as-is, else they'll use .net "String.Format" style formatting. Logs as a message.
* **log.hint(messageFMT, Data...)** - If the "Data..." arguments are missing, the message will be emitted as-is, else they'll use .net "String.Format" style formatting. Logs as a hint.
* **error(messageFMT, Data...)** - same as log.error, but throws it.