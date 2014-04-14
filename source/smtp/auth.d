module smtp.auth;

/++
 Authentication types according to SMTP extensions
 +/
enum SmtpAuthType : string {
	PLAIN = "PLAIN",
	LOGIN = "LOGIN",
};
