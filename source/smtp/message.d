module smtp.message;

import std.string;

/++
 Struct that holds name and address of a person holding e-mail box
  and is capable of sending messages.
 +/

struct Recipient {
	string address;
	string name;
}

/++
  Implements SmtpMessage compositor.
  Allows to get string representation of message and also send it via SmtpClient.

  SmtpMessage is used by `SmtpClient.send` high-level method in order to compose
  and send mail via SMTP.
 +/
struct SmtpMessage {
	Recipient sender;
	Recipient[] recipients;
	string subject;
	string message;
	string replyTo;

	const string toString() {
		string templateCc = "Cc:<%s> \"%s\"";
		string templateResult = "From:<%s> \"%s\"\r\nTo:<%s> \"%s\"\r\n%s\r\nSubject:%s\r\nReply-To:%s\r\n\r\n%s";
		string cc = "";
		if (recipients.length > 1) {
			foreach(recipient; recipients) {
				cc ~= format(templateCc, recipient.address, recipient.name);
			}
		} else {
			cc = "Cc:";
		}

		return format(templateResult, sender.address, sender.name, recipients[0].address, recipients[0].name, cc, subject, replyTo, message);
	}
}