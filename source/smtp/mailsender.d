module smtp.mailsender;

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

public:
version(ssl) {
	this(string host, ushort port, EncryptionMethod encType = EncryptionMethod.None) {
		super(host, port);
		_encType = encType;
	}
} else {
	this(string host, ushort port) {
		super(host, port);
	}
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
	 	final switch (authType) {
	 	case SmtpAuthType.PLAIN:
	 		static assert(params.length == 2 && isSomeString(params[0]) && isSomeString(params[1]));
			auto reply = auth(authType);
			return reply.success ? authPlain(params[0], params[1]) : reply;
	 	case SmtpAuthType.LOGIN:
	 		static assert(params.length == 2 && isSomeString(A[0]) && isSomeString(A[1]));
			auto reply = auth(authType);
			if (reply.success) {
				reply = authLoginUsername(params[0]);
				return reply.success ? authLoginPassword(params[1]) : reply;
			} else {
				return reply;
			}
	 	}
 		return SmtpReply(false, 0, "");
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
		if (!this.mail(mail.sender.address).success) return false;
		foreach (i, recipient; mail.recipients) {
			if (!this.rcpt(recipient.address).success) return false;
		}
		if (!this.data().success) return false;
		if (!this.dataBody(mail.toString()).success) return false;
		return true;
	}
}