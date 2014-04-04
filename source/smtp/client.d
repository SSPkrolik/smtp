module smtp.client;

import std.conv;
import std.socket;
import std.stdio;
import std.string;

import smtp.message;
import smtp.ssl;

/++
 Authentication types according to SMTP extensions
 +/
enum AuthType : string {
	PLAIN      = "PLAIN",
	LOGIN      = "LOGIN",
	GSSAPI     = "GSSAPI",
	DIGEST_MD5 = "DIGEST-MD5",
	MD5        = "MD5",
	CRAM_MD5   = "CRAM-MD5"
};

/++
 SMTP server reply codes, RFC 2921, April 2001
 +/
enum ReplyCode : uint {
	GREETINGS                         = 220,
	OK                                = 250,
	SYNTAX_ERROR                      = 500,
	SYNTAX_ERROR_PARAMETERS           = 501,
	COMMAND_NOT_IMPLEMENTED           = 502,
	BAD_SEQUENCE                      = 503,
	COMMAND_PARAMETER_NOT_IMPLEMENTED = 504,
	STATUS_REPLY                      = 211,
	HELP_REPLY                        = 214,
	SERVICE_READY                     = 220,
	SERVICE_CLOSING_CHANNEL           = 221,
	SERVICE_NOT_AVAILABLE             = 421,
	FORWARDING                        = 251,
	VERIFICATION_FAILED               = 252,
	MAILBOX_BUSY                      = 450,
	MAILBOX_NO_ACCESS                 = 550,
	ACTION_ABORTED                    = 451,
	TRY_FORWARDING                    = 551,
	INSUFFICIENT_STORAGE              = 452,
	EXCEEDED_STORAGE                  = 552,
	MAILBOX_NAME_NOT_ALLOWED          = 553,
	DATA_START                        = 354,
	TRANSACTION_FAILED                = 554
};

/++
 SMTP Reply
 +/
struct SmtpReply {
	uint code;
	string reply;
};

/++
 SMTP Client implementation.
 +/
class SmtpClient {

private:
	bool secure;
	InternetAddress server;
	Socket transport;
	SocketSSL secureTransport;

	/++
	 High-level method to send whole buffer of data into socket.
	 +/
	bool sendData(in char[] data) {
		if (!this.secure) {
			ptrdiff_t sent = 0;
			while (sent < data.length) {
				sent += this.transport.send(data);
			}
			return true;
		} else {
			return secureTransport.write(data) ? true : false;
		}
	}

	/++
	 High-level method to receive data from socket as a string.
	 +/
	string receiveData() {
		char[1024] buf;
		if (!this.secure) {
			ptrdiff_t bytesReceived = this.transport.receive(buf);
			//write("S: ", to!string(buf[0 .. bytesReceived]));
			return to!string(buf[0 .. bytesReceived]);
		} else {
			return secureTransport.read();
		}
	}

	/++
	 Parses server reply and converts it to 'SmtpReply' structure.
	 +/
	const SmtpReply parseReply(string rawReply) {
		return SmtpReply(
			to!uint(rawReply[0 .. 3]),
			strip(rawReply[4 .. $]).idup
		);
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
	 If reply.code == 220, then connection was set successfully.
	 +/
	SmtpReply connect() {
		this.transport.connect(this.server);
		return parseReply(receiveData());
	}

	/++
	 Send command indicating that TLS encrypting of socket data stream has started.
	 +/
	bool startTls(EncryptType enctype = EncryptType.SSLv3, bool verifyCertificate = false) {
		writeln(getResponse("STARTTLS"));
		secureTransport = new SocketSSL(transport, enctype);
		secure = verifyCertificate ? secureTransport.ready && secureTransport.certificateIsVerified : secureTransport.ready;
		return secure;
	}

	/++
	 Initial message to send after connection.
	 Nevertheless it is recommended to use `ehlo()` instead of this method
	 in order to get more information about SMTP server configuration.
	 +/
	SmtpReply helo() {
		return parseReply(getResponse("HELO localhost"));
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

	/++
	 Performs disconnection from server. In one session several mails can be sent,
	 and it is recommended to do so. quit forces server to close connection with
	 client.
	 +/
	string quit() {
		return getResponse("QUIT");
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

}