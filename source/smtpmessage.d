import std.stdio;

/++
 Implements SmtpMessage compositor.
 Allows to get string representation of message and also send it via SmtpClient.
 +/
class SmtpMessage {

private:

public:
	this(string sender, string[] recipients) {

	}

	override string toString() {
		return "";
	}
}