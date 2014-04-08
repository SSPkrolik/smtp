## SMTP library for D, 0.0.9

Native SMTP client implementation in D language.
Get at: [Dub registry](http://code.dlang.org/packages/smtp)

Tested with:
 * `gdc-4.8` `dmd-2.065.0` on Ubuntu 13.10
 * `dmd-2.065.0` on OS X 10.9.2

## Features

 1. `SmtpClient` class that implements SMTP client (mostly low-level functions)
 2. `MailSender` class that implements simplified API
 3. `GMailSender` is a `MailSender` predefined to use GMail's smtp gateway
 4. `SmtpMessage` class that implements SMTP message fields storage
 5. `SSL/TLS` encryption support (via `OpenSSL`). Next encryption methods implemented:
   
   - `SSLv2`
   - `SSLv23`
   - `SSLv3`
   - `TLSv1`
 6. Authentication support which includes the next methods:

   * PLAIN

## TODO

 1. More authentication methods.
 2. More Dedicated clients for popular mail providers, additional API simplification.
 3. Thread-safety.
 4. High-level client.
 5. Unit-tests suite.
 6. Asynchronous version (based on fibers?)
 
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

You can enter folder `examples/<example-project-name>` and perform `$ dub` in order
to run and test example.

If you're a `Linux` or `OS X` user, you can use standard `sendmail` utility
to get SMTP server up and running on your local host. For that just open
new terminal tab or window and type `sendmail`.

Here's an example of high-level `SmtpClient` API usage for sending sample email
either using open or encrypted channel.

```D
/++
 Example: smtp library `SmtpClient` low-level API usage.

 Working with SMTP server via SmtpClient over non-encrypted communication channel.
 Here we send sample letter using SMTP protocol commands directly in
 an order specified by RFC 2821 (April 2001).

 ! WARNING ! You can mention strange code here, which is though made in such a special
 manner to demonstrate as much features of the library as possible.
 +/
import std.stdio;

import smtp.client;
import smtp.message;

void main()
{
  // SmtpClient instantiation (Second parameter is a port, '25' by default
  // for non-SSL connections). Low-level client API.
  auto client = new SmtpClient("localhost");
  
  // All public methods except `disconnect` return SmtpReply struct instance
  // that has bool `success` field indicating request/operation result.
  if(!client.connect().success) { // Connecting to server
    writeln("Cannot connect to specified server at address: ", client.address);
    return;
  }

  // You can use write to log `SmtpReply` instances. This function
  // implicitly uses `toString()` method to convert struct to string.
  // Resulting string is equal to the raw reply text came from SMTP server.
  write("Initiating: ", client.mail("from@localhost")); // Initiating mail sending

  // SmtpReply structs also have `message` field that holds textual
  // part of SMTP server reply. Also if you want to send your letter
  // to several people, you have to call `rcpt()` method for each
  // letter recipient.
  write("RCPT message: ", client.rcpt("to@example.com").message); // Telling server who must receive our e-mail
  
  // `data()` method initiates transmission of your letter's body. Also check
  // `SmtpReply` last field `code` which returns request/operation result
  // code according to standard.
  auto reply = client.data(); // Telling that we're going to send message body
  if (reply.code < 400) { // Actually this is done for you (check `success` field)
    writeln("Data transfer initiated");
    return;
  }
  
  // Transmitting data body to server
  client.dataBody("Subject: Test subject\r\n\r\nTest message");  // Sending message body
  
  // Telling SMTP server we're finishing communication
  client.quit();

  // Making clean disconnect
  client.disconnect(); // Making clean sockets shutdown
}
```