(** Book record and creation utilities. *)

open Person

type book = {
  ext_id : string option;
  (** External ID (e.g. from <id> element). Defined for most books. *)

  version : string option;
  (** Optional version of the book (e.g. "1.1", "1.2", ...).
      The tuple (version, ext_id) should be unique, but this is not enforced by the program. *)

  title : string;
  (** Book title — this field is required and must not be empty after normalization. *)

  authors : person list;
  (** List of authors. May be empty (e.g. for magazines or anonymous works). *)

  lang : string option;
  (** Book language as specified in the FB2 metadata (not validated). *)

  genre : string option;
  (** Book genre as specified in the FB2 metadata (not validated). *)

  filename : string;
  (** Original filename without the .fb2 extension. *)

  encoding : string;
  (** Original character encoding of the file (e.g. "utf8", "windows-1251"). *)
}

val normalize_title : string -> string option
(** [normalize_title title] normalizes the book title for use in [id] and filesystem paths.

    Applies the same normalization rules as person names (lowercasing, removing extra spaces, etc.).
    Returns [None] if the title normalizes to empty. *)

val book_create_exn :
  string ->
  person list ->
  string option ->
  string option ->
  string option ->
  string option ->
  string ->
  string ->
  book
(** [book_create_exn title authors ext_id version lang genre filename encoding] creates a new [book] record.

    - Computes [id] from normalized title + author ids.
    - Raises [Failure] with a descriptive message (including the original title and author count)
      if the title is empty after normalization or if no valid data is provided. *)

val digest : book -> string
(** [digest b] generates a unique hexadecimal digest for the book based on its key fields.

    The digest is built from: normalized title | ext_id | version | normalized author ids.
    Useful for deduplication when importing large ZIP archives with duplicate or near-duplicate books. *)
