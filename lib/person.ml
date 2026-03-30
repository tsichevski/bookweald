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
let normalize last_name first_name middle_name : string option =
  Utils.filter_map_concat_list (List.filter_map Fun.id [last_name; first_name; middle_name]) ' ' Normalize.normalize_name

(** [person_create_exn last_name first_name middle_name] creates a new [person] record.
    The [id] field is set to the normalized name.
    Throws error if name normalized to None.
*)
let person_create_exn last_name first_name middle_name : person =
  match normalize last_name first_name middle_name with
  | None -> failwith "Attempt to create person with empty normalized name"
  | Some id -> 
  { id;
    first_name;
    middle_name;
    last_name }
    