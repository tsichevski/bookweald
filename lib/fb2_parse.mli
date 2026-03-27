(** FB2 metadata extraction (streaming / SAX-style with xmlm).

    Parses FB2 files efficiently without loading the full document into memory.
    Processing stops as soon as all [<title-info>] and [<document-info>]
    elements are fully read and relevant metadata extracted.

    Current limitations / assumptions:
    - Authors collected from both [<title-info>] and [<document-info>]
    - Input must be well-formed XML; no recovery from severe malformations
    - Encoding declared in XML prologue is respected and converted to UTF-8
      (via internal recoding support for common legacy Russian codepages)

    Dependencies: xmlm, recoding_channel (internal), Book module types

    @raise Fb2_parse_error on missing required elements, malformed structure,
                          unsupported encoding, or I/O errors during parsing
*)

open Book
open Person

(** {1 Main parsing function} *)

val parse_book_info : string -> (string, person) Hashtbl.t option -> book
(** [parse_book_info path aliases] parses the FB2 file located at [path] using a streaming XML parser.

    Behavior:
    - Reads the file incrementally (low memory usage, suitable for large archives)
    - Detects encoding from the XML declaration and converts legacy codepages
      (e.g. CP1251, KOI8-R) to Unicode/UTF-8
    - Extracts title from the first [<book-title>] inside [<title-info>]
    - Collects author(s) from [<author>] elements (name parts: first-name, middle-name, last-name)
    - Stops parsing early after the closing tag of the first relevant info block

    @param path Absolute or relative filesystem path to a .fb2 file
    @param aliases Optional alias -> canonical author name table
    @return A [book] record populated with extracted title and author information
    @raise Fb2_parse_error if required metadata is missing or XML is invalid
    @raise Failure if the declared encoding is unsupported or file cannot be opened
*)

(** {1 Validation / debugging} *)

val validate : string -> unit
(** [validate path] performs a basic well-formedness check on the FB2 file.

    Currently checks XML structure. Does not extract metadata.

    Intended for batch verification of library archives.

    @param path Path to the FB2 file to check
    @raise Fb2_parse_error on validation failure with descriptive message
*)