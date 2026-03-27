(** Representation of a person (author, translator, etc.) in the book library. *)

type person = {
  (** Unique identifier for the person, automatically generated from normalized name parts.
      This ID is used as a key for grouping books by author. *)
  id : string;

  (** First name (optional) *)
  first_name : string option;

  (** Middle name / patronymic (optional, common in Russian names) *)
  middle_name : string option;

  (** Last name / surname (optional) *)
  last_name : string option;
}

(** [normalize last_name first_name middle_name] concatenates the non-empty name parts
    after applying [Normalize.normalize_name] to each.
    Raises [Failure] if all parts are empty. *)
let normalize last_name first_name middle_name : string =
  let parts = List.filter_map Fun.id [last_name; first_name; middle_name] in
  if List.is_empty parts then
    failwith "Person has no name"
  else
    List.map Normalize.normalize_name parts |> String.concat " "

(** [normalize_person_key p] returns a normalized string key for the person.
    Used for grouping books by author and for map/set keys. *)
let normalize_person_key {last_name; first_name; middle_name} : string =
  normalize last_name first_name middle_name

(** [person_create last_name first_name middle_name] creates a new [person] record.
    The [id] field is set to the normalized name. *)
let person_create last_name first_name middle_name : person =
  { id = normalize last_name first_name middle_name;
    first_name;
    middle_name;
    last_name }
    