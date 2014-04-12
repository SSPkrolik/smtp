module smtp.ssl;

version(ssl) {

import std.algorithm;
import std.stdio;
import std.conv;
import std.socket;

import deimos.openssl.ssl;
import deimos.openssl.conf;
import deimos.openssl.err;
import deimos.openssl.ssl;

}

/++
 Encryption methods for use with SSL
 +/
enum EncryptionMethod : uint {
	None    = 0, // No encryption is used

	SSLv2   = 1, // SSL version 2 encryption
	SSLv23  = 2, // SSL version 23 encryption
	SSLv3   = 3, // SSL version 3 encryption

	TLSv1   = 4, // TLS version 1 encryption
}

version(ssl) {
/++
 Initializes OpenSSL library
 +/
void initializeSSL() {
	OPENSSL_config("");
	SSL_library_init();
	SSL_load_error_strings();
}

/++
 SSL-encrypted socket-based transport
 +/
class SocketSSL {

private:
	bool m_verified;
	bool m_ready;

	SSL_METHOD *encmethod;
	SSL_CTX* ctx;
	SSL *ssl;
	X509* certificate;

public:

	@property bool ready() { return m_ready; }
	@property bool certificateIsVerified() { return m_verified; }

	this(Socket socket, EncryptionMethod enctype = EncryptionMethod.SSLv3) {
	 	initializeSSL();

	 	// Creating SSL context
	 	final switch (enctype) {
	 	case EncryptionMethod.SSLv2:
 			version(ssl_no_ssl2) { return; } else {
 			encmethod = cast(SSL_METHOD*)SSLv2_client_method();
 			break;
 			}
	 	case EncryptionMethod.SSLv23:
	 		encmethod = cast(SSL_METHOD*)SSLv23_client_method();
	 		break;
	 	case EncryptionMethod.SSLv3:
	 		encmethod = cast(SSL_METHOD*)SSLv3_client_method();
	 		break;
	 	case EncryptionMethod.TLSv1:
	 		encmethod = cast(SSL_METHOD*)TLSv1_client_method();
	 		break;
	 	case EncryptionMethod.None:
	 		return;
	 	}
		ctx = SSL_CTX_new(cast(const(SSL_METHOD*))(encmethod));
		if (ctx == null) {
	 		writeln("SSL context creation error");
	 		return;
	 	}

	 	// Creating secure data stream
	 	ssl = SSL_new(ctx);
	 	if (ssl == null) {
	 		return;
	 	}
	 	SSL_set_fd(ssl, socket.handle);

	 	// Making SSL handshake
	 	auto ret = SSL_connect(ssl);
	 	if (ret != 1) {
	 		return;
	 	}

	 	// Get certificate
	 	certificate = SSL_get_peer_certificate(ssl);
	 	if (certificate == null) {
	 		return;
	 	}

	 	m_ready = true;

	 	// Verify certificate
	 	long verificationResult = SSL_get_verify_result(ssl);
	 	if (verificationResult != X509_V_OK) {
	 		m_verified = false;
	 	} else {
	 		m_verified = true;
	 	}
	}

	/++
	 Method encrypts data and writes it into channel
	 +/
	bool write(in char[] data) {
		return SSL_write(ssl, data.ptr, to!(int)(data.length)) >= 0;
	}

	/++
	 Methods reads data from channel and returns it in an unencrypted presentation
	 +/
	string read() {
		char[1024] buf;
		int ret = SSL_read(ssl, buf.ptr, buf.length);
		if (ret < 0) {
			return "";
		} else {
			for(int index = buf.length - 1; index--; index > 0) {
				if (buf[index] == '\n' && buf[index - 1] == '\r') {
					return to!string(buf[0 .. index + 1]);
				}
			}
			return to!string(buf);
		}
	}

	~ this() {
		if (m_ready) SSL_shutdown(this.ssl);

		if (certificate != null) X509_free(certificate);
		if (ssl != null) SSL_free(ssl);
		if (ctx != null) SSL_CTX_free(ctx);
	}
};
}