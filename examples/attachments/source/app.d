/++
 Example: smtp library attachments API usage.

 Working with SMTP server via MailSender over non-encrypted communication
 channel. Here we send sample letter with attachments using SMTP protocol.
 +/
import std.file;
import std.stdio;

import smtp.attachment;
import smtp.mailsender;
import smtp.message;

void main()
{
	// High-level SMTP client - `MailSender` instance.
	auto sender = new MailSender("localhost", 25);

	// Connecting to server
	auto result = sender.connect();
	if (result.success) {
		// Creating `SmtpMessage` - convinient struct to create valid formed SMTP message
		auto message = SmtpMessage(
			Recipient("from@example.com", "From"),
			[Recipient("to@example.com", "To")],
			"Subject",
			"This is a message body",
			"replyto@example.com",
		);

    // Reading contents of the file to create attachment
    auto bytes = cast(ubyte[])read("dlang.jpg");

    // Creating attachment instance
    auto attachment = SmtpAttachment("dlang.jpg", bytes);

    // Attaching file contents along with filename to the message
    message.attach(attachment, attachment, attachment);

		// Smart method to send message.
		// Performs message transmission sequence with error checking.
		// In case message cannot be sent, `rset` method is called implicitly.
		write(sender.send(message));

    // Perform finalization and cleanup
    sender.quit();
	} else {
		write(result);
		return;
	}
}
