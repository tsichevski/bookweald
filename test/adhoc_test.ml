open Bookweald.Book
open Bookweald.Person
open Bookweald.Normalize

let person1 = person_create_exn (Some " Лёва /! ") (Some "Николаёвич") (Some "Тол,ст.ой 1.")
let person2 = person_create_exn (Some "Fedor") None (Some "Dostoevski")

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

