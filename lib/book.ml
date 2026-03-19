type person = {
  first_name: string option;
  middle_name: string option;
  last_name: string option;
}

type book = {
  id: string;            (** Book external ID, required *)
  title: string;         (** Book title, required *)
  authors: person list;  (** Book authors, at least one *)
  lang: string option;   (** Book language, unverified *)
  genre: string option;  (** Book genre, unverified *)
  filename: string;
  encoding: string;
}

