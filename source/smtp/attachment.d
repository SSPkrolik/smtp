module smtp.attachment;

import std.base64;
import std.conv;
import std.string;

/**
  Implements mail message attachment.
 */
struct Attachment
{
  string title;
  ubyte[] bytes;

  /++
    Returns plain base64 represenation of the attachment.

    The representaiton is ready to be injected into the formatted
    SMTP message.
   +/
  string toString(const string boundary) const {
    const string crlf = "\r\n";
    return boundary ~ crlf
      ~ "Content-Type: application/octet-stream" ~ crlf
      ~ "Content-Transfer-Encoding: base64" ~ crlf
      ~ "Content-Disposition: attachment; filename=\"" ~ title ~ "\"" ~ crlf ~ crlf
      ~ to!string(Base64.encode(bytes)) ~ crlf
      ~ boundary ~ crlf
      ~ crlf;
  }
}
