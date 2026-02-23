open Ocaml_books.Unzip
open Ocaml_books.Fs
open Ocaml_books.Fb2_parse

(* let test_extract_fb2_files = *)
(*   let paths = Ocaml_books.Unzip.extract_fb2_files "/media/vvt/98a0668a-da4a-40a2-b5c8-a09e9ead9f82/Lib.Rus.Ec + MyHomeLib[FB2]/lib.rus.ec/fb2-723100-724049.zip" "/tmp/raw-fb2" in *)
(*   List.iter (Printf.printf "Extracted: %s\n") paths; *)
(*   Printf.printf "Total: %d files\n" (List.length paths) *)

let test_extract_fb2_files =
  match parse_title_author "/tmp/raw-fb2/723100.fb2" with
  | (author_name, title, path) -> 
     Printf.printf "Author: %s, title: %s; path: %s\n" author_name title path

(* let () = test_extract_fb2_files *)

