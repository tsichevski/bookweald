open Utils

module Log = (val Logs.src_log (Logs.Src.create "xml-declaration" ~doc:"Reading XML declaration and extracting encoding.") : Logs.LOG)

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
let consume_xml_decl_exn (ic : char Seq.t) : string * char Seq.t =
  let buf = Buffer.create 64 in
  let rec loop ic wasq =
    match Seq.uncons ic with
    | None ->
      Log.warn (fun m -> m "XML declaration Incomplete");
      failwith "XML declaration Incomplete"
    | Some (c, ic) ->
      Buffer.add_char buf c;
      if wasq && c = '>' then
        let decl = Buffer.contents buf in
        let enc = extract_encoding decl in
        (enc, ic)
      else
        loop ic (c = '?')
  in
  loop ic false

let read_declaration inp =
  let ic = Input_channel.create inp in
  Input_channel.mark ic;
  let out = Input_channel.to_seq ic in
  (* Check if file starts with <?xml *)
  let magic, out = Input_channel.take 5 out in
  if magic <> "<?xml" then
    begin
      (* Does not start with <?xml *)
      (* Rewind the pos back to initial*)
      Log.debug (fun m -> m "No XML declaration detected");
      Input_channel.reset ic;
      ("utf-8", out)
    end    
  else
    begin
      (* Starts with <?xml *)
      (* Read up to ?> and extract encoding *)
      (* Note: instead of resetting buffered channel and using its sequence
         we use the original sequence and dispose the input channel *)
      Input_channel.drop_mark ic;
      consume_xml_decl_exn out
    end
