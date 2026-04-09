(** Streaming FB2 2.1 parser.

    This module provides functions to parse FictionBook (.fb2) files using a
    streaming XML parser ([Xmlm]). It extracts metadata into a {!Book.book}
    record, handles character recoding for legacy Russian encodings, and
    supports author alias substitution.

    Parsing is path-based and event-driven. The module also includes a minimal
    validation function for quick sanity checks. *)

open Book
open Person

(** {1 Exceptions} *)

exception Fb2_parse_error of string
(** Raised when the FB2 structure is invalid or required sections are missing.
    The string contains a descriptive message including the file path when possible. *)

(** {1 Main parsing functions} *)

val parse_book_info :
  string -> (string, person) Hashtbl.t option -> book
(** [parse_book_info path aliases] parses a single FB2 file at [path] and
    returns a fully populated {!Book.book} record.

    @param path Path to the .fb2 file (or .fb2.zip; the module handles unzipping internally).
    @param aliases Optional hash table of author aliases (see {!Alias.load_aliases}).
           If provided, matching author names are replaced by their canonical form.

    @return A {!Book.book} with:
            - normalized title and authors
            - extracted language, genre, ext_id, version
            - original filename and detected encoding

    @raise Fb2_parse_error if the <description> section or <book-title> is missing
    @raise Failure on unsupported encoding or malformed XML
*)

val validate : string -> unit
(** [validate path] performs a minimal streaming parse to verify that the file
    is well-formed XML and contains at least a root <FictionBook> element.

    Does not extract metadata. Raises the same exceptions as [parse_book_info]
    on serious parsing failures. Useful for the [bookweald validate] command. *)
