open Book
open Re

(* Replace ё/Ё → е *)
let replace_yo (s : string) : string =
  let buf = Stdlib.Buffer.create (Stdlib.String.length s) in
  let decoder = Uutf.decoder ~encoding:`UTF_8 (`String s) in

  let rec loop () =
    match Uutf.decode decoder with
    | `Uchar u ->
        let cp = Uchar.to_int u in
        let u' =
          if cp = 0x0401 || cp = 0x0451 then  (* Ё or ё *)
            Uchar.of_int 0x0435                 (* е *)
          else
            u
        in
        Uutf.Buffer.add_utf_8 buf u';
        loop ()
    | `Malformed err ->
        (* Replace malformed sequence with replacement char *)
        Uutf.Buffer.add_utf_8 buf Uutf.u_rep;
        loop ()
    | `End -> ()
    | `Await -> assert false  (* not streaming *)
  in
  loop ();
  Stdlib.Buffer.contents buf

let cmap_utf_8 cmap s =
  let rec loop buf s i max =
    if i > max then Buffer.contents buf else
    let dec = String.get_utf_8_uchar s i in
    let u = Uchar.utf_decode_uchar dec in
    begin match cmap u with
    | `Self -> Buffer.add_utf_8_uchar buf u
    | `Uchars us -> List.iter (Buffer.add_utf_8_uchar buf) us
    end;
    loop buf s (i + Uchar.utf_decode_length dec) max
  in
  let buf = Buffer.create (String.length s * 2) in
  loop buf s 0 (String.length s - 1)

let lowercase_utf_8 s = cmap_utf_8 Uucp.Case.Map.to_lower s

(* Full normalization → key for grouping / subdirectories *)
let normalize_person_key (a : person) : string =
  let open Uucp in
  let parts = List.filter_map Fun.id [a.last_name; a.first_name; a.middle_name] in
  if List.is_empty parts then "unknown_person" else

  let full = String.concat " " parts |> String.trim in

  (* 1. Replace ё/Ё *)
  let no_yo = replace_yo full in

  (* 2. Unicode-aware case folding *)
  let folded = lowercase_utf_8 no_yo in

  (* 3. Collapse whitespace and remove typical punctuation that shouldn't split groups *)
  folded
    |> Str.global_replace (Str.regexp "[ \t\r\n]+") " "
    |> Str.global_replace (Str.regexp "[.,:;«»!?()\"'…—–-]+") ""
    |> String.trim
