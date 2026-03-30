(** Representation of a book parsed from FB2 (or similar) archives in the library. *)

open Person

type book = {
  (** The <id> element value from the FB2 file. Defined for most books. *)
  ext_id : string option;

  (** Optional version of the book (e.g. "1.1", "1.2", ...).
      The tuple (version, ext_id) should be unique, but this is not enforced by the program. *)
  version : string option;

  (** Book title — this field is required. *)
  title : string;

  (** List of authors. May be empty (e.g. for magazines or anonymous works). *)
  authors : person list;

  (** Book language as specified in the FB2 metadata (not validated). *)
  lang : string option;

  (** Book genre as specified in the FB2 metadata (not validated). *)
  genre : string option;

  (** Original filename without the .fb2 extension. *)
  filename : string;

  (** Original character encoding of the file (e.g. "utf8", "windows-1251"). *)
  encoding : string;
}

(** [digest b] generates a unique hexadecimal digest for the book based on its key fields.
    The digest is built from: title | ext_id | version | normalized author keys.
    Useful for deduplication when importing ZIP archives. *)
let digest {ext_id; version; title; authors} : string =
  let ext_id = Option.value ext_id ~default:"" in
  let version = Option.value version ~default:"" in
  title :: ext_id :: version :: (List.map (fun a -> a.id) authors)
  |> String.concat "|"
  |> Digest.string
  |> Digest.to_hex

