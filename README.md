## SMTP library for D

Current version: 0.0.3

Native SMTP client implementation in D language.

Tested with:
 * `gdc-4.8` on Ubuntu 13.10
 * `dmd-2.065.0` on OS X 10.9.2

## Features

 1. `SmtpClient` class that implements SMTP client.
 2. `SmtpMessage` class that implements SMTP message fields storage.

## TODO

 1. Authentication support.
 2. SSL/TLS encryption support (via `OpenSSL`).

## Installation

You can use `smtp` library for D via `dub` package manager.
For this, follow the next steps:
 
 1. Download dub from [DLang site](http://code.dlang.org) (if you still don't have it installed).
 2. Create your project (or use `dub.json` from your existing one).
 3. Add `smtp` as a dependency:

     ```JSON
     {
       "dependencies": {
       		"smtp": ">=0.0.3",
       }
     }
     ```
 4. Use dub to build project:

     ```bash
     $ dub
     ```

## Usage

Here's an example of high-level `SmtpClient` API usage for sending sample email:

```D
#!/usr/bin/rdmd

import std.stdio;
import std.string;

import smtpclient;
import smtpmessage;


void main() {
	auto message = new SmtpMessage(
		"from@example.com",	 					// Sender (put some existing address here)
		["to1@example.com", "to2@example.com"], // Recipients (put some existing addresses here)
		"Test message subject",  				// Subject (topic)
		"This is a test message body",  		// Body of the message
		""										// Reply-to still does not work
	);

	auto client = new SmtpClient(
		"localhost", 	// SMTP server host
		25			 	// SMTP server port
	); 
	client.connect(); 	// Perform connection
	
	if (client.send(message)) {  // Check if message was sent successfully
		writefln("Message: `%s` from <%s> to <%s> sent successfully!",
			message.subject, message.sender, message.recipients);
	} else {
		writefln("Message was not sent for some reason");
	}
	client.quit();		 // Tell SMTP server we're done with sending messages
	client.disconnect(); // Making clean disconnect from server
}
```