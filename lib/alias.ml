open Person

(** [person_from_string s] parses a string into a {!Book.person}.

    Expected format: [last_name first_name middle_name] delimited by
    exactly one space character.

    At least the last name must be present. First name and middle name
    are optional.

    Raises [Failure] if the string cannot be parsed according to the
    rules above.

    Examples:
    - ["Tolstoy Leo"] → person with last="Tolstoy", first="Leo"
    - ["Dostoevsky Fyodor Mikhailovich"] → full three-part name
    - ["Pushkin"] → person with only last name
*)
let person_from_string_exn s : person =
  match String.split_on_char ' ' s with
  | [last_name; first_name; middle_name] ->
      person_create_exn (Some last_name) (Some first_name) (Some middle_name)
  | [last_name; first_name] ->
      person_create_exn (Some last_name) (Some first_name) None
  | [last_name] ->
      person_create_exn (Some last_name) None None
  | _ ->
      failwith ("Cannot parse to person: " ^ s)

(** [load_aliases path] loads an author alias table from a JSON file.

    Expected JSON structure:

    {[
      {
        "Canonical Last First Middle": ["alias1", "alias2", ...],
        "Another Author": ["nick1", "nick2"]
      }
    ]}

    * Each key is a canonical person string (passed to [person_from_string_exn])
    * Each value is a JSON array of strings representing aliases

    All strings (both keys and alias values) are automatically trimmed.

    Returns a hash table where:
    - key   = alias string (trimmed)
    - value = canonical {!Book.person} record

    Raises [Failure] if the root JSON value is not an object.
    Malformed entries inside the object are silently ignored.

    This table is later used during book import to normalize
    author names and correctly group books by canonical author.
*)
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
                  Hashtbl.add table
                    (String.trim alias)
                    (person_from_string_exn (String.trim canonical))
              | _ -> ()
            ) alias_list
        | _ -> ()
      ) obj
  | _ ->
      failwith "aliases.json must be a JSON object"
  end;
  table