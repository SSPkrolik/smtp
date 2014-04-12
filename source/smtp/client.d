module smtp.client;

import std.base64;
import std.conv;
import std.socket;
import std.stdio;
import std.string;

import smtp.auth;
import smtp.reply;
import smtp.ssl;

/++
 Low-level synchronous API for implementing SMTP clients.

 SmtpClient handles:
  + TCP data transmission and buffers management
  + TLS/SSL channel encryption
  + SMTP protocol request/reply handling
  + transport layer exceptions

 SmtpClient does NOT handle:
  * semantic class usage mistakes like bad commands sequences

 Supported SMTP commands:
  NOOP, HELO, EHLO, MAIL, RSET, RCPT, DATA (data, dataBody), AUTH (auth, authPlain),
  STARTTLS, VRFY, EXPN QUIT

 Supported authentication methods:
  PLAIN
 +/
class SmtpClient {
protected:
	char[1024] _recvbuf;

	bool _secure;
	bool _authenticated;

	InternetAddress server;
	Socket transport;

	// SSL Enabled
	version (ssl) {
	SocketSSL secureTransport;
	}

	/++
	 Convenience method to send whole buffer of data into socket.
	 +/
	bool sendData(in char[] data) {
		// SSL Enabled
		version(ssl) {
			if (!this._secure) {
				ptrdiff_t sent = 0;
				while (sent < data.length) {
					sent += this.transport.send(data);
				}
				return true;
			} else {
				return secureTransport.write(data) ? true : false;
			}
		// SSL Disabled
		} else {
			ptrdiff_t sent = 0;
			while (sent < data.length) {
				sent += this.transport.send(data);
			}
			return true;
		}
	}

	/++
	 Convenience method to receive data from socket as a string.
	 +/
	string receiveData() {
		// SSL Enabled
		version(ssl) {  
			if (!this._secure) {
				ptrdiff_t bytesReceived = this.transport.receive(_recvbuf);
				return to!string(_recvbuf[0 .. bytesReceived]);
			} else {
				return secureTransport.read();
			}
		// SSL Disabled
		} else {
			ptrdiff_t bytesReceived = this.transport.receive(_recvbuf);
			return to!string(_recvbuf[0 .. bytesReceived]);
		}
	}

	/++
	 Parses server reply and converts it to 'SmtpReply' structure.
	 +/
	SmtpReply parseReply(string rawReply) {
		auto reply = SmtpReply(
			true,
			to!uint(rawReply[0 .. 3]),
			(rawReply[3 .. $]).idup
		);
		if (reply.code >= 400) {
			reply.success = false;			
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
	@property bool secure() const { return _secure; }
	@property Address address() { return this.server; }

	this(string host, ushort port = 25) {
		auto addr = new InternetHost;
		if (addr.getHostByName(host)) {
			server = new InternetAddress(addr.addrList[0], port);
		} else {
		}
		transport = new TcpSocket(AddressFamily.INET);
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
	SmtpReply starttls(EncryptionMethod enctype = EncryptionMethod.SSLv3, bool verifyCertificate = false) {
		version(ssl) {
		auto response = parseReply(getResponse("STARTTLS"));
		if (response.success) {
			secureTransport = new SocketSSL(transport, enctype);
			_secure = verifyCertificate ? secureTransport.ready && secureTransport.certificateIsVerified : secureTransport.ready;
		}
		return response;
		} else {
		return SmtpReply(false, 0, "");
		}
	}

	/++
	 A `no operation` message. essage that does not invoke any specific routine
	 on server, but still the reply is received.
	 +/
	SmtpReply noop() {
		return parseReply(getResponse("NOOP"));
	}

	/++
	 Initial message to send after connection.
	 Nevertheless it is recommended to use `ehlo()` instead of this method
	 in order to get more information about SMTP server configuration.
	 +/
	SmtpReply helo() {
		return parseReply(getResponse("HELO " ~ transport.hostName));
	}

	/++
	 Initial message to send after connection.
	 Retrieves information about SMTP server configuration
	 +/
	SmtpReply ehlo() {
		return parseReply(getResponse("EHLO " ~ transport.hostName));
	}

	/++
	 Perform authentication (according to RFC 4954)
	 +/
	SmtpReply auth(in SmtpAuthType authType) {
		return parseReply(getResponse("AUTH " ~ authType));
	}

	/++
	 Send base64-encoded authentication data according to RFC 2245.
	 Need to be performed after `data` method call;
	 +/
	SmtpReply authPlain(string login, string password) {
		string data = login ~ "\0" ~ login ~ "\0" ~ password;
		const(char)[] encoded = Base64.encode(cast(ubyte[])data);
		return parseReply(getResponse(to!string(encoded)));
	}

	/++
	 Low-level method to initiate process of sending mail.
	 This can be called either after connect or after helo/ehlo methods call.
	 +/
	SmtpReply mail(string address) {
		return parseReply(getResponse("MAIL FROM:<" ~ address ~ ">"));
	}

	/++
	 Low-level method to specify recipients of the mail. Must be called
	 after 
	 +/
	SmtpReply rcpt(string to) {
		return parseReply(getResponse("RCPT TO:<" ~ to ~ ">"));
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
	 This method cancels mail transmission if mail session is in progress
	 (after `mail` method was called).
	 +/
	SmtpReply rset() {
		return parseReply(getResponse("RSET"));
	}

	/++
	 This method asks server to verify if the user's mailbox exists on server.
	 You can pass [username] or <[e-mail]> as an argument. The result is a reply
	 that contains e-mail of the user, or an error code.
	 
	 IMPORTANT NOTE: most of servers forbid using of VRFY considering it to
	 be a security hole.
	 +/
	SmtpReply vrfy(string username) {
		return parseReply(getResponse("VRFY " ~ username));
	}

	/++
	 EXPN expands mailing list on the server. If mailing list is not available
	 for you, you receive appropriate error reply, else you receive a list of
	 mailiing list subscribers.
	 +/
	SmtpReply expn(string mailinglist) {
		return parseReply(getResponse("EXPN " ~ mailinglist));
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