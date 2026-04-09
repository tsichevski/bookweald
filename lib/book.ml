open Person

type book = {
  ext_id : string option;
  version : string option;
  title : string;
  authors : person list;
  lang : string option;
  genre : string option;
  filename : string;
  encoding : string;
}

let normalize_title title : string option =
  (* Assuming a normalize function exists; adjust if it's in Normalize module *)
  if String.trim title = "" then None
  else (Normalize.normalize_name title)  (* or Utils.normalize_string title *)

let book_create_exn title (authors : person list) ext_id version lang genre filename encoding : book =
  match normalize_title title with
  | None ->
      let author_count = List.length authors in
      failwith (Printf.sprintf
        "Cannot create book: title normalized to empty.\n\
         Original title: [%s]\n\
         Number of authors provided: %d" title author_count)
  | Some norm_title ->
      { ext_id; version; title; authors; lang; genre; filename; encoding }

let digest {ext_id; version; title; authors} : string =
  let ext_id = Option.value ext_id ~default:"" in
  let version = Option.value version ~default:"" in
  let norm_title = Option.value (normalize_title title) ~default:"" in
  norm_title :: ext_id :: version :: (List.map (fun a -> a.id) authors)
  |> String.concat "|"
  |> Digest.string
  |> Digest.to_hex