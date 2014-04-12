/++
 Example: smtp library `SmtpClient` low-level API usage.

 Working with SMTP server via SmtpClient over TLS-encrypted communication channel.
 This example is based on `../lowlevel` one
 +/
import std.stdio;

import smtp.client;
import smtp.ssl;

void main()
{
	// We use 587 as it is a default port for TLS-encrypted SSL connections
	auto client = new SmtpClient("localhost", 587);
	
	// All public methods except `disconnect` return SmtpReply struct instance
	// that has bool `success` field indicating request/operation result.
	if(!client.connect().success) { // Connecting to server
		writeln("Cannot connect to specified server at address: ", client.address);
		return;
	}

	// Some SMTP server require EHLO command to be sent first in order to
	// receive SMTP extensions supported by server.
	write("Server supports next extensions: ", client.ehlo());

	// Saying server we're going to communicate over TLSv1 encrypted channel
	auto tlsreply = client.starttls(EncryptionMethod.TLSv1);
	
	// `secure` property returns `true` if encryption was
	// successfully initiated.
	if (!client.secure) {
		writeln("Could not start TLS, because: ", tlsreply);
		return;
	} else {
		// After `starttls` method call, server can allow other possibilities
		// than in unencrypted mode.
		writeln("Server possibilities in TLS mode:", client.ehlo());
	}

	// Sending mail message
	client.mail("from@localhost");
	client.rcpt("to@example.com");
	client.data();
	client.dataBody("Subject: Test subject\r\n\r\nTest message");
	
	// Telling SMTP server we're finishing communication
	client.quit();

	// Making clean disconnect
	client.disconnect(); // Making clean sockets shutdown
}
