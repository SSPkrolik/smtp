module smtp.message;

import std.string;
import std.uuid;

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
	static string boundary;
	Recipient sender;
	Recipient[] recipients;
	string subject;
	string message;
	string replyTo;
	Attachment[] attachments;

	static this() {
		boundary = randomUUID().toString();
	}

	void attach(Attachment[] a...) {
		attachments ~= a;
	}

	private string cc() const {
		string tCc = "Cc:\"%s\" <%s>\r\n";
		string cc = "";
		if (recipients.length > 1) {
			foreach(recipient; recipients) {
				cc ~= format(tCc, recipient.name, recipient.address);
			}
		} else {
			cc = "";
		}
		return cc;
	}

	private string messageWithAttachments() const {
		const string crlf = "\r\n";
		return boundary ~ crlf
			~ "Content-Type: text/plain; charset=utf-8" ~ crlf
			~ crlf
			~ message ~ crlf
			~ crlf;
	}

	private string attachmentsToString() const {
		string result = "";
		foreach(ref a; attachments) {
			result ~= a.toString(boundary);
		}
		return result;
	}

	string toString() const {
		const string tFrom      = "From: \"%s\" <%s>\r\n";
		const string tTo        = "To: \"%s\" <%s>\r\n";
		const string tSubject   = "Subject:%s\r\n";
		const string mime = "MIME-Version: 1.0";
		const string tMultipart = format("Content-Type: multipart/mixed;\r\n boundary=\"%s\"\r\n\r\n", SmtpMessage.boundary);
		const string tReplyTo   = "Reply-To:%s\r\n";
		const string crlf = "\r\n";

		if (!attachments.length) {
			return format(tFrom, sender.name, sender.address)
   			 ~ format(tTo, recipients[0].name, recipients[0].address)
				 ~ cc()
				 ~ format(tSubject, subject)
				 ~ format(tReplyTo, replyTo)
				 ~ crlf
				 ~ message;
		} else {
			return format(tFrom, sender.name, sender.address)
				 ~ format(tTo, recipients[0].name, recipients[0].address)
				 ~ cc()
				 ~ format(tSubject, subject)
				 ~ mime
				 ~ tMultipart
				 ~ format(tReplyTo, replyTo)
				 ~ messageWithAttachments()
				 ~ attachmentsToString();
		}
	}
}
