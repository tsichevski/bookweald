(** [normalize_chunk s] processes a single "word" chunk.

    It:
    - Filters out anything that is not an alphabetic character (using [Uucp.Alpha.is_alphabetic]).
    - Replaces Ё (U+0401) and ё (U+0451) with е (U+0435).
    - Title-cases the result.
    - Returns [None] if the result is empty after trimming.

    Example:

    {[
      normalize_chunk "Лев Николаевич" = Some "Левниколаевич"   (* note: no space inside chunk *)
      normalize_chunk "!!! ТОЛСТОЙ !!!" = Some "Толстой"
      normalize_chunk "  " = None
    ]}
*)
let normalize_chunk s =
  let b = Buffer.create (String.length s) in
  Uutf.String.fold_utf_8
    (fun _ _ u ->
      match u with
      | `Uchar u ->
        if Uucp.Alpha.is_alphabetic u then
          begin
            let cp = Uchar.to_int u in
            let u =
              if cp = 0x0401 || cp = 0x0451 then  (* Ё or ё *)
                Uchar.of_int 0x0435                 (* е *)
              else
                u
            in
            let func =
              if Buffer.length b = 0 then
                Uucp.Case.Map.to_upper
              else
                Uucp.Case.Map.to_lower
            in
            match func u with
            | `Self -> Uutf.Buffer.add_utf_8 b u
            | `Uchars l -> List.iter (fun u -> Uutf.Buffer.add_utf_8 b u) l
          end
      | `Malformed e ->
          failwith (Printf.sprintf
            "Malformed UTF-8 character in normalize_chunk.\n\
             Input snippet: [%s]\n\
             Error: %s" (String.sub s 0 (min 30 (String.length s))) e)
    )
    () s;
  Buffer.contents b |> Utils.trim_opt

let normalize_name s : string option =
  Utils.filter_map_concat s '-' normalize_chunk