module smtp.reply;

import std.conv;

/++
 SMTP server reply codes, RFC 2921, April 2001
 +/
enum SmtpReplyCode : uint {
	HELP_STATUS     = 211,  // Information reply
	HELP            = 214,  // Information reply

	READY           = 220,  // After connection is established
	QUIT            = 221,  // After connected aborted
	AUTH_SUCCESS    = 235,  // Authentication succeeded
	OK              = 250,  // Transaction success
	FORWARD         = 251,  // Non-local user, message is forwarded
	VRFY_FAIL       = 252,  // Verification failed (still attempt to deliver)

	AUTH_CONTINUE   = 334,  // Answer to AUTH <method> prompting to send auth data
	DATA_START      = 354,  // Server starts to accept mail data

	NA              = 421,  // Not Available. Shutdown must follow after this reply
	NEED_PASSWORD   = 435,  // Password transition is needed
	BUSY            = 450,  // Mail action failed
	ABORTED         = 451,  // Action aborted (internal server error)
	STORAGE         = 452,  // Not enough system storage on server
	TLS             = 454,  // TLS unavailable | Temporary Auth fail

	SYNTAX          = 500,  // Command syntax error | Too long auth command line
	SYNTAX_PARAM    = 501,  // Command parameter syntax error
	NI              = 502,  // Command not implemented
	BAD_SEQUENCE    = 503,  // This command breaks specified allowed sequences
	NI_PARAM        = 504,  // Command parameter not implemented
	
	AUTH_REQUIRED   = 530,  // Authentication required
	AUTH_TOO_WEAK   = 534,  // Need stronger authentication type
	AUTH_CRED       = 535,  // Wrong authentication credentials
	AUTH_ENCRYPTION = 538,  // Encryption reqiured for current authentication type

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
		return to!string(code) ~ message;
	}
};
