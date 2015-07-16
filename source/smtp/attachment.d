module smtp.attachment;

import std.string;

/**
  Implements mail message attachment.
 */
struct Attachment
{
  string title;
  byte[] bytes;
}
