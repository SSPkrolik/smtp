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
	static string boundary;        // Parts delmiter in multipart message
	Recipient sender;              // Specifies name/address of a sender
	Recipient[] recipients;        // Specifies names/adresses of recipients
	string subject;                // Message subject
	string message;                // Message text (body)
	string replyTo;                // Messages chains maked (reply-to:)
	SmtpAttachment[] attachments;  // Attachments to message

	/++
	  Initializes boundary for parts in multipart/mixed message type.

		Boundary is a random sequence of chars that must divide message
		into parts: message, and attachments.
	 +/
	static this() {
		boundary = randomUUID().toString();
	}

	/++
	  Add attachments to the `SmtpMessage`.
	 +/
	void attach(SmtpAttachment[] a...) {
		attachments ~= a;
	}

	/++
	  Builds string representation for a list of copies-to-send over SMTP.
	 +/
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

	/++
	  Builds message representation in case we have multipart/mixed MIME-type
		of the message to send.
	 +/
	private string messageWithAttachments() const {
		const string crlf = "\r\n";
		return "Content-Type: text/html; charset=utf-8" ~ crlf
			~ crlf
			~ message ~ crlf
			~ crlf ~ "--" ~ SmtpMessage.boundary ~ crlf;
	}

	/++
	 Partly converts attachments to string for SMTP protocol representation
	 +/
	private string attachmentsToString() const {
		string result = "";
		foreach(ref a; attachments) {
			result ~= a.toString(boundary);
		}
		return result[0..$ - 2] ~ ".\r\n";
	}

	/++
	  This method converts SmtpMessage struct to string representation.

		This string representation is a ready-to-send representation for
		SMTP protocol.
	 +/
	string toString() const {
		const string tFrom      = "From: \"%s\" <%s>\r\n";
		const string tTo        = "To: \"%s\" <%s>\r\n";
		const string tSubject   = "Subject: %s\r\n";
		const string mime       = "MIME-Version: 1.0\r\n";
		const string tMultipart = format("Content-Type: multipart/mixed; boundary=\"%s\"\r\n", SmtpMessage.boundary);
		const string tReplyTo   = "Reply-To:%s\r\n";
		const string crlf       = "\r\n";

		if (!attachments.length) {
			return format(tFrom, sender.name, sender.address)
   			 ~ format(tTo, recipients[0].name, recipients[0].address)
				 ~ cc()
				 ~ format(tSubject, subject)
				 ~ format(tReplyTo, replyTo)
				 ~ crlf
				 ~ message ~ "." ~ crlf;
		} else {
			return format(tFrom, sender.name, sender.address)
				 ~ format(tTo, recipients[0].name, recipients[0].address)
				 ~ cc()
				 ~ format(tSubject, subject)
				 ~ mime
				 ~ tMultipart
				 ~ format(tReplyTo, replyTo) ~ crlf
				 ~ "--" ~ boundary ~ crlf
				 ~ messageWithAttachments()
				 ~ attachmentsToString();
		}
	}
}
