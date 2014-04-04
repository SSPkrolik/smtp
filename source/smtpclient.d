module smtpclient;

import std.conv;
import std.socket;
import std.stdio;
import std.string;

import smtpmessage;

/++
 SMTP Client implementation.
 +/
class SmtpClient {

private:
	Socket transport;
	InternetAddress server;

	/++
	 High-level method to send whole buffer of data into socket.
	 +/
	void sendData(string data) {
		char[] buf = to!(char[])(data);
		ptrdiff_t sent = 0;
		while (sent < buf.length) {
			sent += this.transport.send(buf);
		}
	}

	/++
	 High-level method to receive data from socket as a string.
	 +/
	string receiveData() {
		char[1024] buf;
		ptrdiff_t bytesReceived = this.transport.receive(buf);
		return to!string(buf[0 .. bytesReceived]);
	}

	/++
	 Implementation of request/response pattern for easifying
	 communication with SMTP server.
	 +/
	string getResponse(string command, string suffix="\r\n") {
		sendData(command ~ suffix);
		return receiveData();
	}

public:
	this(string host, ushort port = 25) {
		auto addr = new InternetHost;
		if (addr.getHostByName(host)) {
			this.server = new InternetAddress(addr.addrList[0], port);
		} else {
		}
		this.transport = new TcpSocket(AddressFamily.INET);
	}

	/++
	 Return SMTP server address
	 +/
	@property Address serverAddress() {
		return this.server;
	}

	/++
	 Performs socket connection establishment.
	 connect is the first method to be called after SmtpClient instantiation.
	 +/
	void connect() {
		this.transport.connect(this.server);
		receiveData();
	}

	/++
	 Performs clean disconnection from server.
	 It is recommended to use disconnect after quit method which signals
	 SMTP server about end of the session.
	 +/
	void disconnect() {
		this.transport.shutdown(SocketShutdown.BOTH);
		this.transport.close();
	}

	/++
	 Initial message to send after connection.
	 Nevertheless it is recommended to use `ehlo()` instead of this method
	 in order to get more information about SMTP server configuration.
	 +/
	string helo() {
		return getResponse("HELO localhost");
	}

	/++
	 Initial message to send after connection.
	 Retrieves information about SMTP server configuration
	 +/
	string ehlo() {
		return getResponse("EHLO localhost");
	}

	/++
	 Low-level method to initiate process of sending mail.
	 This can be called either after connect or after helo/ehlo methods call.
	 +/
	string mail(string sender) {
		return getResponse("MAIL FROM:" ~ sender);
	}

	/++
	 Low-level method to specify recipients of the mail. Must be called
	 after 
	 +/
	string rcpt(string to) {
		return getResponse("RCPT TO:" ~ to);
	}

	/++
	 Low-level method to initiate sending of the message body.
	 Must be called after rcpt method call.
	 +/
	string data() {
		return getResponse("DATA");
	}

	/++
	 Sends the body of message to server. Must be called after `data` method.
	 Also dataBody sends needed suffix to signal about the end of the message body.
	 +/
	string dataBody(string message) {
		return getResponse(message, "\r\n.\r\n");
	}

	/++
	 Performs disconnection from server. In one session several mails can be sent,
	 and it is recommended to do so. quit forces server to close connection with
	 client.
	 +/
	string quit() {
		return getResponse("QUIT");
	}

	/++
	 High-level method for sending messages.

	 Accepts SmtpMessage instance and returns true
	 if message was sent successfully or false otherwise.

	 This method is recommended in order to simplify the whole workflow
	 with the `smtp` library.

	 send method basically implements [mail -> rcpt ... rcpt -> data -> dataBody]
	 method calls chain.
	 +/
	bool send(in SmtpMessage mail) {
		auto rawBody = "From: \"\" <" ~ mail.sender ~ ">\r\n";

		auto answer = this.mail(mail.sender);
		if (icmp(answer[0 .. 3], "250") != 0) return false;

		foreach (i, recipient; mail.recipients) {
			answer = getResponse("RCPT TO:"~recipient);
			if (icmp(answer[0 .. 3], "250") != 0) return false;

			if (i == 0) {
				rawBody ~= "To: \"\" <" ~ mail.recipients[i] ~ ">\r\n";
			} else {
				rawBody ~= "Cc: \"\" <" ~ mail.recipients[i] ~ ">\r\n";
			}
		}
		answer = data();
		if (icmp(answer[0 .. 3], "354") != 0) return false;

		rawBody ~= "Subject: " ~ mail.subject ~ "\r\n\r\n" ~ mail.message;
		answer = dataBody(rawBody);
		if (icmp(answer[0 .. 3], "250") != 0) return false;

		return true;
	}
}