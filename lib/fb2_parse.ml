(*
  Simplified FB2 parser using xmlm's built-in encoding detection.
  
  xmlm automatically:
  - Detects encoding from XML declaration
  - Converts to UTF-8 internally
  - Provides SAX-style event streaming
 *)

open Base
open Core
open Xmlm

exception Fb2_parse_error of string

let rec parse input handle path =
  let signal = Xmlm.input input in
  match signal with
  | `Dtd _ ->
    parse input handle path
  | `El_start ((_, tag), _) ->
    let path' = tag::path in
    handle None path' || parse input handle path'
  | `El_end ->
    (match path with
     | [_] -> false (* Closing the root element, exiting *)
     | hd :: tl ->
       parse input handle tl
     | _ ->
       failwith "Invalid XML: END without start")
  | `Data txt ->
    handle (Some txt) path || parse input handle path

let locate input path = parse input (fun txt path' -> List.equal String.equal path path')
    
let () =
  In_channel.with_file "/tmp/books/incoming/701300.fb2" ~binary:true ~f:(fun ic ->
      let input = Xmlm.make_input (`Channel ic) in
      let success = 
        parse input (fun txt path ->
            (* Printf.printf "%s at [%s]\n" txt (String.concat ~sep:"; " path); *)
            match path with
            | ["title-info"; "description"; "FictionBook"] -> true
            | _ -> false) [] in
      printf "Parse result %b\n" success
    )

type extraction_state = {
  mutable found_title: string option;
  mutable found_author: string option;
  mutable depth: int;
  mutable in_title_info: bool;
  mutable in_author: bool;
  mutable first_name: string;
  mutable middle_name: string;
  mutable last_name: string;
}

(** [parse_title_author path] reads an FB2 file with automatic encoding detection.
    
    Uses xmlm which automatically:
    - Detects encoding from <?xml encoding="..."?>
    - Converts to UTF-8 internally
    - Provides streaming (SAX-style) event parsing
    
    Returns (author_name, title, path) triple.
 *)
let parse_title_author (path : string) : string * string * string =
  In_channel.with_file path ~binary:true ~f:(fun ic ->
    try
      (* xmlm automatically handles encoding detection from XML declaration *)
      let input = Xmlm.make_input (`Channel ic) in
      
      (* Skip DTD signal *)
      (match Xmlm.input input with
       | `Dtd _
         -> ()
       | _ ->
           raise (Fb2_parse_error (
             Printf.sprintf "%s: invalid XML start" path
           ))
      );
      
      (* Validate FictionBook root element *)
      (match Xmlm.input input with
       | `El_start ((_, "FictionBook"), _) -> ()
       | `El_start ((_, tag), _) ->
           raise (Fb2_parse_error (
             Printf.sprintf "%s: root element is <%s>, expected <FictionBook>" path tag
           ))
       | _ ->
           raise (Fb2_parse_error (
             Printf.sprintf "%s: invalid FB2 structure" path
           ))
      );
      
      let state = {
        found_title = None;
        found_author = None;
        depth = 0;
        in_title_info = false;
        in_author = false;
        first_name = "";
        middle_name = "";
        last_name = "";
      } in
      
      (* Process SAX events *)
      let rec process_events () =
        if Option.is_some state.found_title && Option.is_some state.found_author then
          ()
        else
          match Xmlm.input input with
          | `El_start ((_, tag), _) ->
              state.depth <- state.depth + 1;
              (match tag with
               | "title-info" -> state.in_title_info <- true
               | "author" when state.in_title_info -> state.in_author <- true
               | "book-title" when state.in_title_info && Option.is_none state.found_title ->
                   (match Xmlm.input input with
                    | `Data text ->
                        state.found_title <- Some (String.strip text);
                        process_events ()
                    | _ -> process_events ())
               | "first-name" when state.in_author && String.is_empty state.first_name ->
                   (match Xmlm.input input with
                    | `Data text ->
                        state.first_name <- String.strip text;
                        process_events ()
                    | _ -> process_events ())
               | "middle-name" when state.in_author && String.is_empty state.middle_name ->
                   (match Xmlm.input input with
                    | `Data text ->
                        state.middle_name <- String.strip text;
                        process_events ()
                    | _ -> process_events ())
               | "last-name" when state.in_author && String.is_empty state.last_name ->
                   (match Xmlm.input input with
                    | `Data text ->
                        state.last_name <- String.strip text;
                        process_events ()
                    | _ -> process_events ())
               | _ -> process_events ())
          | `El_end ->
              state.depth <- state.depth - 1;
              if state.in_author && state.depth < 3 then
                state.in_author <- false;
              if state.in_title_info && state.depth < 2 then
                state.in_title_info <- false;
              process_events ()
          | `Data _ | `Dtd _ ->
              process_events ()
      in
      
      process_events ();
      
      let title = Option.value state.found_title ~default:"" in
      let author_parts = [state.first_name; state.middle_name; state.last_name]
        |> List.filter ~f:(fun s -> not (String.is_empty s))
      in
      let author = match author_parts with
        | [] -> "Unknown Author"
        | parts -> String.concat ~sep:" " parts
      in
      
      (author, title, path)
    with Fb2_parse_error _ as e ->
      raise e
    | e ->
      raise (Fb2_parse_error (
        Printf.sprintf "Error parsing %s: %s" path (Exn.to_string e)
      ))
  )