(*
  XML declaration parser.

  Extracts encoding information from <?xml ... encoding="..."?> declaration.
  Works for files of any size - no fixed buffer limits.

  Safe for any encoding because the declaration syntax itself is ASCII-compatible.
 *)

open Utils

(** [extract_encoding declaration] parses encoding from XML declaration string.

    Example: extract_encoding "<?xml version=\"1.0\" encoding=\"windows-1251\"?>"
    Returns: "windows-1251"

    Returns "utf-8" if no encoding attribute found (per XML 1.0 spec).

    Uses simple substring matching which is safe because the entire
    declaration is ASCII, even if the file content uses a different encoding.
*)
let extract_encoding (declaration : string) : string =
  let start_encoding = "encoding=\"" in
  match substring_index declaration start_encoding with
  | None -> "utf-8"
  | Some pos ->
    let start_pos = pos + String.length start_encoding in
    if start_pos >= String.length declaration then
      "utf-8"
    else
      (match String.index_from_opt declaration start_pos '"' with
       | None -> "utf-8"
       | Some end_pos ->
         String.sub declaration start_pos (end_pos - start_pos)
         |> String.lowercase_ascii)

(** [read_until_marker_exn ic buf] continues reading from channel until "?>" is found.

    Assumes "<?xml" was seen already .
    Returns (encoding, declaration_string).

    Throws error if EOF reached prematurely
*)
let rec read_until_marker_exn (ic : In_channel.t) (buf : Buffer.t) : string * string =
  match In_channel.input_char ic with
  | None -> 
    (* EOF without ?>: incomplete declaration *)
    failwith "XML declaration Incomplete"
  | Some '?' ->
    Buffer.add_char buf '?';
    (match In_channel.input_char ic with
     | Some '>' ->
       Buffer.add_char buf '>';
       let decl = Buffer.contents buf in
       let enc = extract_encoding decl in
       (enc, decl)
     | Some c ->
       Buffer.add_char buf c;
       read_until_marker_exn ic buf
     | None ->
       failwith "XML declaration Incomplete")
  | Some c ->
    Buffer.add_char buf c;
    read_until_marker_exn ic buf

(** [read_declaration ic] reads and parses the XML declaration from the start of a file.

    Reads byte-by-byte until "?>" marker is found. Works for any file encoding
    because the declaration syntax (<?xml version="..." encoding="..."?>) is ASCII-safe.

    Returns (encoding, declaration_string) where:
    - encoding: detected encoding name (lowercase), defaults to "utf-8"
    - declaration_string: the raw <?xml...?> text (for debugging)

    If no declaration found (file doesn't start with <?xml), returns ("utf-8", "").
    If file ends before declaration is complete, returns ("utf-8", partial_declaration).
*)
let read_declaration (ic : In_channel.t) : string * string =
  let init_pos = In_channel.pos ic in
  let buf = Buffer.create 256 in

  (* Check if file starts with <?xml *)
  let magic = Bytes.create 5 in
  let bytes_read = In_channel.input ic magic 0 5 in
  if bytes_read < 5 || not (String.equal (Bytes.to_string magic) "<?xml") then
    begin
      (* Does not start with <?xml *)
      (* Rewind the pos back to initial*)
      In_channel.seek ic init_pos;
      ("utf-8", "")
    end    
  else
    begin
      Buffer.add_bytes buf magic;
      read_until_marker_exn ic buf
    end
