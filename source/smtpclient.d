import std.stdio;

class SMTPClient {

	string host;
	int port;

	this(string host, int port) {
		this.host = host;
		this.port = port;
	}
}