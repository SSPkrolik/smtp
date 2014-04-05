## SMTP library for D

Current version: 0.0.3

Native SMTP client implementation in D language.

Tested with:
 * `gdc-4.8` on Ubuntu 13.10
 * `dmd-2.065.0` on OS X 10.9.2

## Features

 1. `SmtpClient` class that implements SMTP client.
 2. `SmtpMessage` class that implements SMTP message fields storage.
 3. `SSL/TLS` encryption support (via `OpenSSL`). Next encryption methods implemented:
   
   1. `SSLv2`.
   2. `SSLv23`.
   3. `SSLv3`.

## TODO

 1. Authentication support.
 2. Dedicated clients for popular mail providers.
 3. Unit-tests suite.
 
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
     to build with dependencies or 
     ```bash
     $ dub --force
     ```
     after code update for rebuilding.

## Usage

You can find low-level API usage example projects in `examples` folder:

 1. `lowlevel`
    
    Shows the simplest chain of routines to send e-mail message via
    unencrypted channel.
 
 2. `lowlevel-logged`
    
    Similar to `lowlevel` but also demonstrates possibities of `SmtpReply`
    structure to get and log messages from SMTP server.
 
 3. `lowlevel-safe`
    
    Similar to `lowlevel-logged` but also shows how to check if errors
    happened during mail sending session.

You can enter folder `examples/<example-project-name>` and perform `$ dub` in order
to run and test example.

If you're a `Linux` or `OS X` user, you can use standard `sendmail` utility
to get SMTP server up and running on your local host. For that just open
new terminal tab or window and type `sendmail`.

Here's an example of high-level `SmtpClient` API usage for sending sample email
either using open or encrypted channel.

```D
#!/usr/bin/rdmd

import std.stdio;
import std.string;

import smtp.client;
import smtp.message;
import smtp.ssl;


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
	
	// Uncomment next line to start TLS-encrypted communication with server
	// client.startTls(EncryptType.SSLv3);

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