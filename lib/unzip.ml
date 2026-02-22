(* Unzip file support *)
(*
  utop:
#require "zip";;
 *)
open Zip

let with_zip_in zip_path f =
  let zip = ref None in
  Fun.protect
    ~finally:(fun () ->
      match !zip with
      | Some z -> Zip.close_in z
      | None   -> ())
    (fun () ->
      let z = Zip.open_in zip_path in
      zip := Some z;
      f z)
(* val with_zip_in : string -> (in_file -> 'a) -> 'a = <fun> *)
;;

(* Usage example: extract only .fb2 files *)
let extract_fb2_files zip_path target_dir =
  with_zip_in zip_path @@ fun zip ->
  let count = ref 0 in

  List.iter (fun entry ->
    if not entry.is_directory && Filename.check_suffix entry.filename ".fb2" then
      try
        let out_path = Filename.concat target_dir (Filename.basename entry.filename) in

        (* Ensure parent dir exists *)
        let dir = Filename.dirname out_path in
        if not (Sys.file_exists dir) then Fs.mkdir_p dir;

        Zip.copy_entry_to_file zip entry out_path;
        incr count;
        Printf.printf "Extracted: %s\n" (Filename.basename entry.filename)
      with e ->
        Printf.eprintf "Error on %s: %s\n" entry.filename (Printexc.to_string e)
  ) (Zip.entries zip);

  !count