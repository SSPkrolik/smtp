/++
 Example: smtp library `MailSender` high-level API usage.
 
 Typical workflow is: connect() -> [authenticate()] -> send() x n -> quit()

 Working with SMTP server via MailSender over non-encrypted communication channel.
 Here we send sample letter using SMTP protocol.

 ! WARNING ! You can mention strange code here, which is though made in such a special
 manner to demonstrate as much features of the library as possible.
 +/
import std.stdio;

import smtp.client;
import smtp.mailsender;
import smtp.message;

void main()
{
	// High-level SMTP client - `MailSender` instance.
	auto sender = new MailSender("localhost", 25);

	// Connecting to server
	auto result = sender.connect();
	if (result.success) {
		// Performing authentication using PLAIN method with login and password
		write(sender.authenticate(SmtpAuthType.PLAIN, "login", "password"));

		// Creating `SmtpMssage` - convinient struct to create valid formed SMTP message
		auto message = SmtpMessage(
			Recipient("from@example.com", "From"),
			[Recipient("to@example.com", "To")],
			"Subject",
			"This is a message body",
			"replyto@example.com",
		);

		// Smart method to send message.
		// Performs message transmission sequence with error checking.
		// In case message cannot be sent, `rset` method is called implicitly.
		write(sender.send(message));
	} else {
		write(result);
		return;
	}
}
