type person = {
  first_name: string option;
  middle_name: string option;
  last_name: string option;
}

(* Internal normalized person key - computed from structured person *)
let normalize_person (a : person) : string =
  let parts = List.filter_map Fun.id [a.last_name; a.first_name; a.middle_name] in
  let full = String.concat " " parts |> String.trim |> String.lowercase_ascii
  in
  (* String.map (function 'ё' | 'Ё' -> 'е' | c -> c) full *)
  full

type book_ext_id = string (** Book application ID: either the value of <id> element or initial filename if missing *)

type book = {
  ext_id: book_ext_id;
  title: string;         (** Book title, required *)
  authors: person list;  (** Book authors, at least one *)
  lang: string option;   (** Book language, unverified *)
  genre: string option;  (** Book genre, unverified *)
  filename: string;      (** Original file name without .fb extension *)
  encoding: string;
}

