(* Streaming (SAX-style) parsing of FB2 metadata using xmlm.
   Reads the file incrementally and stops as soon as the <title-info> element
   is fully processed.

   Current assumptions:
   - All input files are valid UTF-8 (no encoding detection or conversion)
   - Only the first <title-info> block is used
   - Only one <author> block is processed (first one found)

   Dependencies: xmlm (lightweight streaming XML parser)

   Output: (author_name, book_title, original_path) triple
   Raises Fb2_parse_error on missing required tags or malformed XML *)

exception Fb2_parse_error of string

type title_info = {
  title       : string option;
  first_name  : string option;
  middle_name : string option;
  last_name   : string option;
  lang        : string option;
  genre       : string option;
}
  
(** [parse_title_author_stream path] parses the FB2 file at [path] using xmlm.
    Collects author name (first + middle + last name) and book title from the
    first <title-info> block.

    Stops reading as soon as </title-info> is encountered — very efficient for
    large FB2 files with big <body> sections.

    @param path Path to the FB2 file
    @return (author, title, path)
    @raise Fb2_parse_error if <title-info>, <book-title> or author parts are missing *)
val parse_title_author : string -> string option * string option
