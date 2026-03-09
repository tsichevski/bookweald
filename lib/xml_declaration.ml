(*
  XML declaration parser.

  Parses <?xml ... encoding="..."?> from the start of a binary file.
  Safe for any encoding because the declaration syntax is ASCII-compatible.
 *)

open Base

(** [extract_encoding declaration] parses encoding from XML declaration bytes.

    Example: extract_encoding "<?xml version=\"1.0\" encoding=\"cp1251\"?>"
    Returns: "cp1251"

    Returns "utf-8" if no encoding attribute found (per XML spec).
*)
let extract_encoding (declaration : string) : string =
  match String.substr_index declaration ~pattern:"encoding=\"" with
  | None -> "utf-8"
  | Some pos ->
    let start = pos + String.length "encoding=\"" in
    if start >= String.length declaration then
      "utf-8"
    else
      (match String.index_from declaration start '"' with
       | None -> "utf-8"
       | Some end_pos ->
         String.sub declaration ~pos:start ~len:(end_pos - start)
         |> String.lowercase)

(** [read_declaration ic] reads and parses the XML declaration from channel.

    Reads bytes until "?>" marker is found. Works for any file encoding
    because the declaration itself is ASCII-safe.

    Returns (encoding, declaration_bytes) where:
    - encoding: detected encoding name (lowercase), defaults to "utf-8"
    - declaration_bytes: the raw <?xml...?> bytes (including markers)

    If no declaration found, returns ("utf-8", "").
*)
let read_declaration (ic : Core.In_channel.t) : string * string =
  let buf = Buffer.create 256 in
  let rec read_until_marker () =
    match Core.In_channel.input_char ic with
    | None -> 
      (* EOF without ?>: incomplete or no declaration *)
      ("utf-8", Buffer.contents buf)
    | Some '?' ->
      Buffer.add_char buf '?';
      (match Core.In_channel.input_char ic with
       | Some '>' ->
         Buffer.add_char buf '>';
         let decl = Buffer.contents buf in
         let enc = extract_encoding decl in
         (enc, decl)
       | Some c ->
         Buffer.add_char buf c;
         read_until_marker ()
       | None ->
         ("utf-8", Buffer.contents buf))
    | Some c ->
      Buffer.add_char buf c;
      read_until_marker ()
  in

  (* Check if file starts with <?xml *)
  let magic = Bytes.create 5 in
  let bytes_read = Core.In_channel.input ic ~buf:magic ~pos:0 ~len:5 in
  if bytes_read < 5 || not (String.equal (Bytes.to_string magic) "<?xml") then
    begin
      (* Does not start with <?xml *)
      Core.In_channel.seek ic 0L;
      ("utf-8", "")
    end    
  else
    begin
      Buffer.add_bytes buf magic;
      read_until_marker ()
    end
