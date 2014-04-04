module smtpmessage;

import std.stdio;

/++
  Implements SmtpMessage compositor.
  Allows to get string representation of message and also send it via SmtpClient.

  SmtpMessage is used by `SmtpClient.send` high-level method in order to compose
  and send mail via SMTP.
 +/
class SmtpMessage {

private:
	string m_sender;
	string[] m_recipients;
	string m_message;
	string m_subject;
	string m_replyTo;

public:
	this(string sender, string[] recipients, string subject = "", string message = "", string replyTo = "") {
		this.m_sender = sender;
		this.m_recipients = recipients.dup;
		this.m_subject = subject;
		this.m_message = message;
		this.m_replyTo = replyTo;
	}

	const @property string sender() { return m_sender; }
	const @property string[] recipients() { return m_recipients.dup; }
	const @property string message() { return m_message; }
	const @property string subject() { return m_subject; }
	const @property string replyTo() { return m_replyTo; }

	override string toString() {
		return "";
	}
}