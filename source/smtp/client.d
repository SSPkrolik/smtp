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
enum SmtpAuthType : string {
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
enum SmtpReplyCode : uint {
	HELP_STATUS     = 211,  // Information reply
	HELP            = 214,  // Information reply

	READY           = 220,  // After connection is established
	QUIT            = 221,  // After connected aborted
	OK              = 250,  // Transaction success
	FORWARD         = 251,  // Non-local user, message is forwarded
	VRFY_FAIL       = 252,  // Verification failed (still attempt to deliver)

	DATA_START      = 354,  // Server starts to accept mail data

	NA              = 421,  // Not Available. Shutdown must follow after this reply
	BUSY            = 450,  // Mail action failed.
	ABORTED         = 451,  // Action aborted (internal server error)
	STORAGE         = 452,  // Not enough system storage on server

	SYNTAX          = 500,  // Command syntax error
	SYNTAX_PARAM    = 501,  // Command parameter syntax error
	NI              = 502,  // Command not implemented
	BAD_SEQUENCE    = 503,  // This command breaks specified allowed sequences
	NI_PARAM        = 504,  // Command parameter not implemented
	
	MAILBOX         = 550,  // Mailbox is not found (for different reasons)
	TRY_FORWARD     = 551,  // Non-local user, forwarding is needed
	MAILBOX_STORAGE = 552,  // Storage for mailbox exceeded
	MAILBOX_NAME    = 553,  // Unallowed name for the mailbox
	FAIL            = 554   // Transaction fail
};

/++
 SMTP Reply
 +/
struct SmtpReply {
	bool success;
	uint code;
	string message;

	string toString() {
		return to!string(code) ~ " " ~ message;
	}
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
			return to!string(buf[0 .. bytesReceived]);
		} else {
			return secureTransport.read();
		}
	}

	/++
	 Parses server reply and converts it to 'SmtpReply' structure.
	 If we receive 421 code we are forced to shutdown client (acording to RFC 2821).
	 +/
	SmtpReply parseReply(string rawReply) {
		auto reply = SmtpReply(
			true,
			to!uint(rawReply[0 .. 3]),
			(rawReply[4 .. $]).idup
		);
		// Syntax and implementation errors check
		if (reply.code >= 400) {
			reply.success = false;			
		}
		if (reply.code == SmtpReplyCode.NA) {
			disconnect();
		}
		return reply;
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
			server = new InternetAddress(addr.addrList[0], port);
		} else {
		}
		transport = new TcpSocket(AddressFamily.INET);
	}

	/++
	 Return SMTP server address
	 +/
	@property Address address() {
		return this.server;
	}

	/++
	 Performs socket connection establishment.
	 connect is the first method to be called after SmtpClient instantiation.
	 +/
	SmtpReply connect() {
		try {
			this.transport.connect(this.server);
		} catch (SocketOSException) {
			return SmtpReply(false, 0, "");
		}
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
		SmtpReply reply = parseReply(getResponse("HELO localhost"));
		return reply;
	}

	/++
	 Initial message to send after connection.
	 Retrieves information about SMTP server configuration
	 +/
	SmtpReply ehlo() {
		SmtpReply reply = parseReply(getResponse("EHLO localhost"));
		return reply;
	}

	/++
	 Low-level method to initiate process of sending mail.
	 This can be called either after connect or after helo/ehlo methods call.
	 +/
	SmtpReply mail(string sender) {
		return parseReply(getResponse("MAIL FROM:" ~ sender));
	}

	/++
	 Low-level method to specify recipients of the mail. Must be called
	 after 
	 +/
	SmtpReply rcpt(string to) {
		return parseReply(getResponse("RCPT TO:" ~ to));
	}

	/++
	 Low-level method to initiate sending of the message body.
	 Must be called after rcpt method call.
	 +/
	SmtpReply data() {
		return parseReply(getResponse("DATA"));
	}

	/++
	 Sends the body of message to server. Must be called after `data` method.
	 Also dataBody sends needed suffix to signal about the end of the message body.
	 +/
	SmtpReply dataBody(string message) {
		return parseReply(getResponse(message, "\r\n.\r\n"));
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
		if (!this.mail(mail.sender).success) return false;
		
		foreach (i, recipient; mail.recipients) {
			auto answer = getResponse("RCPT TO:"~recipient);
			if (icmp(answer[0 .. 3], "250") != 0) return false;

			if (i == 0) {
				rawBody ~= "To: \"\" <" ~ mail.recipients[i] ~ ">\r\n";
			} else {
				rawBody ~= "Cc: \"\" <" ~ mail.recipients[i] ~ ">\r\n";
			}
		}
		
		if (!this.data().success) return false;
		rawBody ~= "Subject: " ~ mail.subject ~ "\r\n\r\n" ~ mail.message;
		if (!this.dataBody(rawBody).success) return false;
		
		return true;
	}

	/++
	 Performs disconnection from server. In one session several mails can be sent,
	 and it is recommended to do so. quit forces server to close connection with
	 client.
	 +/
	SmtpReply quit() {
		return parseReply(getResponse("QUIT"));
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