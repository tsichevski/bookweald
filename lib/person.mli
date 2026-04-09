(** Representation of a person (author, translator, etc.) in the book library. *)

type person = {
  id : string;
  first_name : string option;
  middle_name : string option;
  last_name : string option;
}

val normalize : string option -> string option -> string option -> string option
(** [normalize last_name first_name middle_name] concatenates the non-empty name parts
    after applying [Normalize.normalize_name] to each.
    Raises [Failure] if all parts are empty. *)

val person_create_exn : string option -> string option -> string option -> person
(** [person_create_exn last_name first_name middle_name] creates a new [person] record.
    The [id] field is set to the normalized name.
    Throws error if name normalized to None.
*)