#!/usr/bin/rdmd

import std.stdio;
import std.string;

import smtp.client;
import smtp.message;
import smtp.ssl;


void main() {
	auto message = SmtpMessage(
		Recipient("from@example.com", "Name"),  // Sender (put some existing address here)
		[Recipient("to1@example.com", "Name")], // Recipients (put some existing addresses here)
		"Test message subject",                 // Subject (topic)
		"This is a test message body",          // Body of the message
		""                                      // Reply-to still does not work
	);

	auto client = new SmtpClient(
		"localhost", // SMTP server host
		25           // SMTP server port
	); 
	client.connect();  // Perform connection
	
	// Uncomment next line to start TLS-encrypted communication with server
	// `startTls` method will work if and only if your SMTP server
	// support SSL/TLS encryption.
	// 
	// Good news is that `SmtpClient`
	// analyzes replies for you and in case your server does not support
	// encryption, the next code up to the end of the application
	// will continue working through unencryted channel.
	client.startTls(EncryptType.SSLv3);

	if (client.send(message)) {  // Check if message was sent successfully
		writefln("Message: `%s` from <%s> to <%s> sent successfully!",
			message.subject, message.sender, message.recipients);
	} else {
		writefln("Message was not sent for some reason");
	}
	client.quit();       // Tell SMTP server we're done with sending messages
	client.disconnect(); // Making clean disconnect from server
}