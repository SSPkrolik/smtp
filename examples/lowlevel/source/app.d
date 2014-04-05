/++
 Example: smtp library `SmtpClient` low-level API usage.

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
	
	// In those next lines we assume all our operations are successfull. 
	client.connect(); // Connecting to server
	client.mail("from@localhost"); // Initiating mail sending
	client.rcpt("to@example.com"); // Telling server who must receive our e-mail
	client.data();  // Telling that we're going to send message body
	client.dataBody("Subject: Test subject\r\n\r\nTest message");  // Sending message body
	client.quit();  // Telling server about finishing sessions

	// Making clean disconnect
	client.disconnect(); // Making clean sockets shutdown
}
