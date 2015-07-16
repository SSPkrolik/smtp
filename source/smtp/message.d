module smtp.message;

import std.string;

import smtp.attachment;

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
	string contentType = "";
	string mimeVersion = "";
	Attachment[] attachments;

	void attach(Attachment[] a...) {
		attachments ~= a;
	}

	const string toString() {
		string tFrom = "From: \"%s\" <%s>\r\n";
		string tTo = "To: \"%s\" <%s>\r\n";
		string tCc = "Cc:\"%s\" <%s>\r\n";
		string tSubject = "Subject:%s\r\n";
		string tReplyTo = "Reply-To:%s\r\n";
		string tCRLF = "\r\n";
		string tBody = "%s";

		string cc = "";
		if (recipients.length > 1) {
			foreach(recipient; recipients) {
				cc ~= format(tCc, recipient.name, recipient.address);
			}
		} else {
			cc = "";
		}

		return format(tFrom, sender.name, sender.address)
   			 ~ format(tTo, recipients[0].name, recipients[0].address)
				 ~ cc
				 ~ format(tSubject, subject)
				 ~ format(tReplyTo, replyTo)
				 ~ tCRLF
				 ~ format(tBody, message);
	}
}
