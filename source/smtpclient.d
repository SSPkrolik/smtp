module smtpclient;

import std.stdio;
import std.socket;
import std.conv;

import smtpmessage;

/++
 SMTP Client implementation.
 +/
class SmtpClient {

private:
	Socket transport;
	InternetAddress server;

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
	 Performs connection to smtp server.
	 +/
	void connect() {
		this.transport.connect(this.server);
	}

	void disconnect() {
		this.transport.shutdown(SocketShutdown.BOTH);
		this.transport.close();
	}

	void HELO() {
		char[] buf = to!(char[])("HELO localhost\n");
		ptrdiff_t sent = 0;
		while (sent < buf.length) {
			sent += this.transport.send(buf);
		}
	}

	void sendMail(in SmtpMessage mail) {

	}
}
