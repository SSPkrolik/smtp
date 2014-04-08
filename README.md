## SMTP library for D

Current version: 0.0.9
Get at: [Dub registry](http://code.dlang.org/packages/smtp)

Native SMTP client implementation in D language.

Tested with:
 * `gdc-4.8` on Ubuntu 13.10
 * `dmd-2.065.0` on OS X 10.9.2

## Features

 1. `SmtpClient` class that implements SMTP client (mostly low-level functions).
 2. `MailSender` class that implements simplified API.
 3. `GMailSender` is a `MailSender` predefined to use GMail's smtp gateway.
 4. `SmtpMessage` class that implements SMTP message fields storage.
 5. `SSL/TLS` encryption support (via `OpenSSL`). Next encryption methods implemented:
   
   * `SSLv2`.
   * `SSLv23`.
   * `SSLv3`.
 6. Authentication support which includes the next methods:

   * PLAIN

## TODO

 1. More authentication methods.
 2. More Dedicated clients for popular mail providers, additional API simplification.
 3. Add thread-safety for high-level clients.
 4. Unit-tests suite.
 
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
 4. Use dub to build smtp library:

     without SSL/TLS support
     ```bash
     $ dub
     ```
     or with SSL/TLS support:
     ```bash
     $ dub -c ssl
     ```
     To chose right smtp building configuration for your project use `subConfigurations` setting in
     your project's `dub.json`:
     ```json
     {
       "subConfigurations": { "smtp": "no-ssl" }
     }
     ```
     Available configurations are:
       * `no-ssl` by default
       * `ssl` to build with `OpenSSL` support

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
 
 4. `highlevel`

    Shows the simples chain of routines to send e-mail via unencrypted channel.
    Also you can find this example in this wiki page below.

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
    "from@example.com",                     // Sender (put some existing address here)
    ["to1@example.com", "to2@example.com"], // Recipients (put some existing addresses here)
    "Test message subject",                 // Subject (topic)
    "This is a test message body",          // Body of the message
    ""                                      // Reply-to still does not work
  );

  auto client = new SmtpClient(
    "localhost", // SMTP server host
    25           // SMTP server port
  ); 
  client.connect();  // Perform connection
  
  // Uncomment next line to start TLS-encrypted communication with server
  // `startTls` method will work if and only if your SMTP server
  // support SSL/TLS encryption.
  // 
  // Good news is that `SmtpClient`
  // analyzes replies for you and in case your server does not support
  // encryption, the next code up to the end of the application
  // will continue working through unencryted channel.
  client.startTls(EncryptType.SSLv3);

  if (client.send(message)) {  // Check if message was sent successfully
    writefln("Message: `%s` from <%s> to <%s> sent successfully!",
      message.subject, message.sender, message.recipients);
  } else {
    writefln("Message was not sent for some reason");
  }
  client.quit();       // Tell SMTP server we're done with sending messages
  client.disconnect(); // Making clean disconnect from server
}
```