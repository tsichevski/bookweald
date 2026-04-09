open Person

(** [person_from_string_exn s] parses a string into a {!Person.person} record.

    Expected format: space-separated parts in the order
    last_name first_name middle_name.

    - At least the last name must be present.
    - First name and middle name are optional.
    - Extra spaces around parts are trimmed automatically.

    Raises [Failure] with a descriptive message if the string cannot be parsed
    according to the rules (wrong number of parts after splitting, or empty name).

    Example (successful):

    {[
      person_from_string_exn "Толстой Лев Николаевич"
      (* returns person with id = "толстой лев николаевич" *)
    ]}

    Example (failure):

    {[
      person_from_string_exn ""
      (* raises Failure with message containing the empty string *)
    ]}
*)
let person_from_string_exn s : person =
  let parts = String.split_on_char ' ' s
    |> List.map String.trim
    |> List.filter (fun p -> p <> "") in
  match parts with
  | [last_name; first_name; middle_name] ->
      person_create_exn (Some last_name) (Some first_name) (Some middle_name)
  | [last_name; first_name] ->
      person_create_exn (Some last_name) (Some first_name) None
  | [last_name] ->
      person_create_exn (Some last_name) None None
  | _ ->
      failwith (Printf.sprintf
        "Cannot parse string to person: [%s]\n\
         Expected format: \"Last First Middle\" (middle name optional)" s)

let load_aliases path : (string, person) Hashtbl.t =
  let json = Yojson.Safe.from_file path in
  let table = Hashtbl.create 512 in
  begin match json with
  | `Assoc obj ->
      List.iter (fun (canonical, aliases_json) ->
        match aliases_json with
        | `List alias_list ->
            List.iter (function
              | `String alias ->
                  let trimmed_alias = String.trim alias in
                  let canonical_person = person_from_string_exn (String.trim canonical) in
                  Hashtbl.add table trimmed_alias canonical_person
              | _ -> ()
            ) alias_list
        | _ -> ()
      ) obj
  | _ ->
      failwith (Printf.sprintf
        "aliases.json must be a JSON object (got wrong root type).\n\
         File: %s" path)
  end;
  table