/++
 Example: smtp library `SmtpClient` low-level API usage with replies processing.

 Working with SMTP server via SmtpClient over non-encrypted communication channel.
 Here we send sample letter using SMTP protocol commands directly in
  an order specified by RFC 2821 (April 2001).
 +/
import std.stdio;
import smtp.client;

void main()
{
	// SmtpClient instantiation (Second parameter is a port, '25' by default
	//	for non-SSL connections)
	auto client = new SmtpClient("localhost");
	
	// Every operation that communicates with server returns `SmtpReply`
	// structure instance with
	//  - bool   `.success` field indicating server operation result or current server status
	//  - uint   `.code` field storing SMTP reply code
	//  - string `.message` field storing text of the reply message
	if (client.connect().success) { // Connecting to server
		writeln("Successfully connected to server");
		if (bool success = client.mail("from@localhost").success) {
			writeln("Mail sending initiated successfully");
			auto reply = client.rcpt("to@example.com"); // Telling server who must receive our e-mail
			write(reply.message);
			reply = client.data();  // Telling that we're going to send message body
			write(reply.message);
			reply = client.dataBody("Subject: Test subject\r\n\r\nTest message");  // Sending message body
			write(reply.message);
		} else {
			writeln("Could not initiate mail sending");
		}
	} else {
		writeln("Connection was not established for some reason");
	}

	// Telling server about finishing sessions
	write(client.quit());  
	
	// Making clean `disconnect` which only does the job.
	// Its return value is `void`.
	client.disconnect(); // Making clean sockets shutdown 
}
