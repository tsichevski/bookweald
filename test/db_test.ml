(** Warning: this test resets the default DB *)
open Bookweald.Db
open Bookweald.Book
open Bookweald.Person

let person1 = person_create_exn (Some " Лёва /! ") (Some "Николаёвич") (Some "Тол,ст.ой 1.")
let person2 = person_create_exn (Some "Fedor") None (Some "Dostoevski")
let person3 = person_create_exn (Some "Аркадий") None (Some "Стругацкий")

let () =
  try
    let admconn = connect ~user:"admin" ~password:"admin" () in
    drop_schema admconn;
    init_schema admconn;
    close admconn;
    let conn = connect () in
    let id = find_or_insert_person conn person1 in
    Printf.printf "Id %s\n%!" id;
    let id = find_or_insert_person conn person2 in
    Printf.printf "Id %s\n%!" id;

    let id = find_or_insert_book conn
      { ext_id = Some "12345";
        version = None;
        title = "Book Title";
        encoding = "utf8";
        authors = [person3];
        lang=(Some "ru");
        genre=(Some "sf");
        filename="bla-bla.fb2"}      
    in
    Printf.printf "New book Id %s\n%!" id

  with Postgresql.Error pe ->
    failwith (Postgresql.string_of_error pe)
  
