module smtp.mailsender;

import smtp.auth;
import smtp.client;
import smtp.message;
import smtp.ssl;

/++
 High-level implementation of SMTP client.
 +/
class MailSender : SmtpClient {

private:
	bool _authenticated;
	EncryptType _encType;

public:
	this(string host, ushort port, EncryptType encType = EncryptType.None) {
		super(host, port);
		_encType = encType;
	}

	const @property authenticated() {
		return _authenticated;
	}

	/++
	 Perform most-used initialization for SMTP clients:
	  - Connect to server
	  - Send initial EHLO
	  - Start TLS on channel if needed
	 +/
	bool initialize() {
		if (connect().success) {
			if (ehlo().success) {
				return startTLS(_encType).success;
			} else {
				return false;
			}
		} else {
			return false;
		}
	}

	/++
	 Perfrom authentication process in one method (high-level) instead
	 of sending AUTH and auth data in several messages
	 +/
	 bool authenticate(A...)(in SmtpAuthType authType, A params) {
	 	switch (authType) {
	 	case SmtpAuthType.PLAIN:
	 		static if (params.length) {
	 			static if (params.length == 2) {
	 				auth(authType);
	 				if (authPlain(params[0], params[1]).success) {
	 					_authenticated = true;
	 				}
	 			}
	 		}
	 	default:
	 		return SmtpReply(false, 0, "");
	 	}
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