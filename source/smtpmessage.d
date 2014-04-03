import std.stdio;

/++
 Implements SmtpMessage compositor.
 Allows to get string representation of message and also send it via SmtpClient.
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
		this.m_sender = sender.dup;
		this.m_recipients = recipients.dup;
		this.m_subject = subject.dup;
		this.m_message = message.dup;
		this.m_replyTo = replyTo.dup;
	}

	@property string sender() { return m_sender.dup; }
	@property string[] recipients() { return m_recipients.dup; }
	@property string message() { return m_message.dup; }
	@property string subject() { return m_subject.dup; }
	@property string replyTo() { return m_replyTo.dup; }

	override string toString() {
		return "";
	}
}