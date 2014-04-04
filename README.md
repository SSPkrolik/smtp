## SMTP library for D

Current version: 0.0.3

Native SMTP client implementation in D language.

## Features

 1. SmtpClient class that implements SMTP client.
 2. SmtpMessage class that implements SMTP message fields storage.

## TODO

 1. Authentication support.
 2. SSL/TLS encryption support (via OpenSSL).

## Installation

You can use `smtp` library for D via `dub` package manager.
For this, follow the next steps:
 
 1. Download dub from code.dlang.org (if you still didn't install).
 2. Create your project (or use `dub.json` from your existing one).
 3. Enter `smtp` as a dependency:

     ```
     {
     ...
       "dependencies": {
       		...
       		"smtp": ">=0.0.3",
       		...
       }
     ...
     }
     ```


## Usage

To be continued...