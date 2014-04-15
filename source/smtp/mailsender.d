module smtp.mailsender;

import core.sync.mutex;

import std.algorithm;
import std.conv;
import std.stdio;
import std.string;
import std.traits;

import smtp.auth;
import smtp.client;
import smtp.message;
import smtp.reply;

version(ssl) {
import smtp.ssl;
}

/++
 High-level implementation of SMTP client.
 +/
class MailSender : SmtpClient {

private:
	version(ssl) {
	EncryptionMethod _encType;
	}
	bool _server_supports_pipelining = false;
	bool _server_supports_vrfy = false;
	bool _server_supports_etrn = false;
	bool _server_supports_enhanced_status_codes = false;
	bool _server_supports_dsn = false;
	bool _server_supports_8bitmime = false;
	bool _server_supports_binarymime = false;
	bool _server_supports_chunking = false;
	bool _server_supports_encryption = false;

	uint _max_message_size = 0;

	Mutex _transmission_lock;

public:
version(ssl) {
	/++
	 SSL-enabled constructor
	 +/
	this(string host, ushort port, EncryptionMethod encType = EncryptionMethod.None) {
		super(host, port);
		_encType = encType;
		_transmission_lock = new Mutex();
	}
} else {
	/++
	 No-SSL constructor
	 +/
	this(string host, ushort port) {
		super(host, port);
		_transmission_lock = new Mutex();
	}
}

	/++
	 Server limits
	 +/
	uint maxMessageSize() const { return _max_message_size; }

	/++
	 Server-supported extensions
	 +/
	bool extensionPipelining() const { return _server_supports_pipelining; }
	bool extensionVrfy() const { return _server_supports_vrfy; }
	bool extensionEtrn() const { return _server_supports_etrn; }
	bool extensionEnhancedStatusCodes() const { return _server_supports_enhanced_status_codes; }
	bool extensionDsn() const { return _server_supports_dsn; }
	bool extension8bitMime() const { return _server_supports_8bitmime; }
	bool extensionBinaryMime() const { return _server_supports_binarymime; }
	bool extensionChunking() const { return _server_supports_chunking; }
	bool extensionTls() const { return _server_supports_encryption; }

	/++
	 Connecting to SMTP server and also trying to get server possibiities
	 in order to expose it via public API.
	 +/
	override SmtpReply connect() {
		_transmission_lock.lock();
		auto reply = super.connect();
		if (!reply.success) {
			_transmission_lock.unlock();
			return reply;
		}
		// Trying to get what possibilities server supports
		reply = ehlo();
		foreach(line; split(strip(reply.message), "\r\n")[1 .. $ - 1]) {
			auto extension = line[4 .. $];
			switch(extension) {
			case "STARTTLS":
				_server_supports_encryption = true;
				break;
			case "PIPELINING":
				_server_supports_pipelining = true;
				break;
			case "VRFY":
				_server_supports_vrfy = true;
				break;
			case "ETRN":
				_server_supports_etrn = true;
				break;
			case "ENHANCEDSTATUSCODES":
				_server_supports_enhanced_status_codes = true;
				break;
			case "DSN":
				_server_supports_dsn = true;
				break;
			case "8BITMIME":
				_server_supports_8bitmime = true;
				break;
			case "BINARYMIME":
				_server_supports_binarymime = true;
				break;
			default:
			}
		}

		foreach(line; split(strip(reply.message), "\r\n")[1 .. $]) {
			auto option = line[4 .. $];
			if (option.startsWith("SIZE")) {
				_max_message_size = to!int(line[9 .. $]);
				continue;
			}
			if (option.startsWith("CHUNKING")) {

			}
		}

		_transmission_lock.unlock();
		return reply;
	}
	/++
	 Perfrom authentication process in one method (high-level) instead
	 of sending AUTH and auth data in several messages.

	 Auth schemes accoring to type:
	  * PLAIN:
	    | AUTH->, <-STATUS, [encoded login/password]->, <-STATUS
	  * LOGIN:
	    | AUTH->, <-STATUS, [encoded login]->, <-STATUS, [encoded password]->, <-STATUS
	 +/
	 SmtpReply authenticate(A...)(in SmtpAuthType authType, A params) {
	 	_transmission_lock.lock();
	 	SmtpReply result;
	 	final switch (authType) {
	 	case SmtpAuthType.PLAIN:
	 		static assert((params.length == 2) && is(A[0] == string) && is(A[1] == string));
			auto reply = auth(authType);
			result = reply.success ? authPlain(params[0], params[1]) : reply;
	 	case SmtpAuthType.LOGIN:
	 		static assert((params.length == 2) && is(A[0] == string) && is(A[1] == string));
			auto reply = auth(authType);
			if (reply.success) {
				reply = authLoginUsername(params[0]);
				result = reply.success ? authLoginPassword(params[1]) : reply;
			} else {
				result = reply;
			}
	 	}
		_transmission_lock.unlock();
		return reply;
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
	SmtpReply send(in SmtpMessage mail) {
		_transmission_lock.lock();
		auto reply = this.mail(mail.sender.address);
		if (!reply.success) return reply;
		foreach (i, recipient; mail.recipients) {
			reply = this.rcpt(recipient.address); 
			if (!reply.success) {
				this.rset();
				_transmission_lock.unlock();
				return reply;
			}
		}
		reply = this.data(); 
		if (!reply.success) {
			this.rset();
			_transmission_lock.unlock();
			return reply;
		}
		reply = this.dataBody(mail.toString);
		if (!reply.success) {
			this.rset();
		}
		_transmission_lock.unlock();
		return reply;
	}
}