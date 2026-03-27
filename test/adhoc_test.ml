open Bookweald.Book
open Bookweald.Person
open Bookweald.Normalize

let person_create last_name first_name middle_name : person = { id=(normalize last_name first_name middle_name); first_name; middle_name; last_name}

let person1 = person_create (Some " Лёва /! ") (Some "Николаёвич") (Some "Тол,ст.ой 1.")
let person2 = person_create (Some "Fedor") None (Some "Dostoevski")

let b : book = {
  ext_id=Some "some ID";
  version=None;
  title="Book title";
  authors=[person1; person2];
  lang=None;
  genre=None;
  filename="12345";
  encoding="utf8";
}

