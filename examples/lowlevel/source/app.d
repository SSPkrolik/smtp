/++
 Example: smtp library `SmtpClient` low-level API usage.

 Working with SMTP server via SmtpClient over non-encrypted communication channel.
 Here we send sample letter using SMTP protocol commands directly in
 an order specified by RFC 2821 (April 2001).

 ! WARNING ! You can mention strange code here, which is though made in such a special
 manner to demonstrate as much features of the library as possible.
 +/
import std.stdio;

import smtp.client;
import smtp.mailsender;
import smtp.reply;

void main()
{
	// SmtpClient instantiation (Second parameter is a port, '25' by default
	// for non-SSL connections). Low-level client API.
	auto client = new SmtpClient("localhost");

	// All public methods except `disconnect` return SmtpReply struct instance
	// that has bool `success` field indicating request/operation result.
	if(!client.connect().success) { // Connecting to server
		writeln("Cannot connect to specified server at address: ", client.address);
		return;
	}

	// You can use write to log `SmtpReply` instances. This function
	// implicitly uses `toString()` method to convert struct to string.
	// Resulting string is equal to the raw reply text came from SMTP server.
	write("Initiating: ", client.mail("from@localhost")); // Initiating mail sending

	// SmtpReply structs also have `message` field that holds textual
	// part of SMTP server reply. Also if you want to send your letter
	// to several people, you have to call `rcpt()` method for each
	// letter recipient.
	write("RCPT message:", client.rcpt("to@example.com").message); // Telling server who must receive our e-mail

	// `data()` method initiates transmission of your letter's body. Also check
	// `SmtpReply` last field `code` which returns request/operation result
	// code according to standard.
	auto reply = client.data(); // Telling that we're going to send message body
	if (reply.code < 400) { // Actually this is done for you (check `success` field)
		writeln("Data transfer initiated");
	} else {
		writeln("Data transfer problem:", reply);
		return;
	}

	// Transmitting data body to server
	client.dataBody("Subject: Test subject\r\n\r\nTest message");  // Sending message body

	// Telling SMTP server we're finishing communication
	write(client.quit());

	// Making clean disconnect
	client.disconnect(); // Making clean sockets shutdown
}
