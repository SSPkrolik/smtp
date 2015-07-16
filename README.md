## SMTP library for D - version 0.2.1

Native synchronous SMTP client implementation in D language. Get at official Dub repository: [code.dlang.org](http://code.dlang.org/packages/smtp)

Tested with:
 - `dmd-2.066.0` stable on Ubuntu 15.04 Vivid Vervet

## Features

 1. `SmtpClient` class that implements SMTP client (mostly low-level functions)
 2. `MailSender` class that implements simplified API
 3. `GMailSender` is a `MailSender` predefined to use GMail's smtp gateway (**ssl** version only)
 4. `SmtpMessage` class that implements SMTP message fields storage
 5. `SSL/TLS` encryption support (via `OpenSSL`). Next encryption methods implemented:
   - `SSLv2`
   - `SSLv23`
   - `SSLv3`
   - `TLSv1`
 6. Authentication support which includes the next methods:
   - `PLAIN`
   - `LOGIN`

## TODO

 1. More authentication methods.
 2. More Dedicated clients for popular mail providers, additional API simplification.
 3. Unit-tests suite.
 4. Asynchronous version (based on fibers?)

## Installation

You can use `smtp` library for D via `dub` package manager.
For this, follow the next steps:

 1. Download dub from [DLang site](http://code.dlang.org) (if you still don't have it installed).
 2. Create your project (or use `dub.json` from your existing one).
 3. Add `smtp` as a dependency:

     ```JSON
     {
       "dependencies": {
       		"smtp": ">=0.1.1",
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
     or with SSL/TLS support when OpenSSL is prebuilt without SSLv2 support:
     ```bash
     $ dub -c ssl-no-ssl2
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

 1. [`lowlevel`](https://github.com/SSPkrolik/smtp/tree/master/examples/lowlevel)
  Shows the simplest chain of routines to send e-mail message via
  unencrypted channel.

 2. [`lowlevel-tls`](https://github.com/SSPkrolik/smtp/tree/master/examples/lowlevel-tls)
  Shows the simplest chain of routines to send e-mail message via
  encrypted channel. _Note: if you want to use SSLv2 encryption type for some
  reason, you have to change `"smtp": "ssl-no-ssl2"` to `"smtp": "ssl2"` in
  `subConfiguration` section of the example's dub.json file._

 3. [`sender`](https://github.com/SSPkrolik/smtp/tree/master/examples/sender)
  Shows how to authenticate and send a message using high-level API via
  `MailSender` class: `connect`, `authenticate`, `send`, and `quit` methods.
  `MailSender` high-level methods provide thread-safety.

You can enter folder `examples/<example-project-name>` and perform `$ dub` in order
to run and test example.

If you're a `Linux` or `OS X` user, you can use standard `sendmail` utility
to get SMTP server up and running on your local host. For that just open
new terminal tab or window and type `sendmail`.

If you want to test encrypted client, you can use `smtp.gmail.com:587` along
with `TLSv1` encryption method. Obviously this works with `ssl` configuration
of smtp library only.
