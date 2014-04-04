module smtpclient;

import std.conv;
import std.socket;
import std.stdio;
import std.string;

import deimos.openssl.bio;
import deimos.openssl.conf;
import deimos.openssl.err;
import deimos.openssl.ssl;

import smtpmessage;

/++
 Authentication types according to SMTP extensions
 +/
enum AuthType : string {
	PLAIN = "PLAIN",
	LOGIN = "LOGIN",
	GSSAPI = "GSSAPI",
	DIGEST_MD5 = "DIGEST-MD5",
	MD5 = "MD5",
	CRAM_MD5 = "CRAM-MD5"
};

/++
 Encryption methods for use with SSL
 +/
enum EncryptType : uint {
	SSLv3 = 0,
}

/++
 SMTP Client implementation.
 +/
class SmtpClient {

private:
	Socket transport;
	InternetAddress server;

	SSL_METHOD *encmethod;
	SSL *ssl;
	bool secure;

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
			if (SSL_write(ssl, data, to!(int)(data.length)) < 0) {
				return false;
			}
			return true;
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
			int ret = SSL_read(ssl, buf, buf.length);
			if (ret < 0) {
				return "";
			} else {
				return to!string(buf);
			}
		}
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

	 	OPENSSL_config("");
	 	SSL_library_init();
	 	SSL_load_error_strings();
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
	 Send command indicating that TLS encrypting of socket data stream has started.
	 +/
	bool startTls(EncryptType enctype, bool verifyCertificate = false) {
		getResponse("STARTTLS");

	 	// Creating SSL context
	 	switch (enctype) {
	 	case EncryptType.SSLv3:
	 		encmethod = cast(SSL_METHOD*)SSLv3_client_method();
	 		break;
	 	default:
	 		encmethod = cast(SSL_METHOD*)SSLv3_client_method();
	 	}
	 	
	 	SSL_CTX* ctx = SSL_CTX_new(cast(const(SSL_METHOD*))(encmethod));
	 	if (ctx == null) {
	 		writeln("ERROR");
	 		return false;
	 	}

	 	// Creating secure data stream
	 	this.ssl = SSL_new(ctx);
	 	if (ssl == null) {
	 		writeln("ERROR");
	 		return false;
	 	}
	 	SSL_set_fd(ssl, this.transport.handle);

	 	// Making SSL handshake
	 	auto ret = SSL_connect(ssl);
	 	if (ret != 1) {
	 		writeln("ERROR:", ret);
	 		return false;
	 	}

	 	// Get certificate
	 	X509 *certificate = SSL_get_peer_certificate(ssl);
	 	if (certificate == null) {
	 		writeln("CERTIFICATE ERROR");
	 		return false;
	 	}

	 	this.secure = true;

	 	// Verify certificate
	 	if (verifyCertificate) {
		 	long verificationResult = SSL_get_verify_result(ssl);
		 	if (verificationResult != X509_V_OK) {
		 		X509_verify_cert_error_string(verificationResult);
		 		return false;
		 	}
		}
     	return true;
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

		if (secure) {
			SSL_shutdown(this.ssl);
			SSL_free(this.ssl);
		}
	}

}