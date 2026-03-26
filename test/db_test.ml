open Ocaml_books.Db

let () =
  try
    let admconn = connect ~user:"admin" ~password:"admin" () in
    drop_schema admconn;
    init_schema admconn;
    close admconn;
    let conn = connect () in
    let id = find_or_insert_person conn {first_name=(Some "First");middle_name=(Some "Middle");last_name=(Some "Last");} in
    Printf.printf "Id %s\n%!" id;
    let id = find_or_insert_person conn {first_name=(Some "First");middle_name=None;last_name=(Some "Last");} in
    Printf.printf "Id %s\n%!" id;

    let id = find_or_insert_book conn
      { digest = "12345";
        title="Book Title";
        encoding="utf8";
        authors=[{first_name=(Some "Arcady");middle_name=None;last_name=(Some "Strugatski");}];
        lang=(Some "ru");
        genre=(Some "sf");
        filename="bla-bla.fb2"}
      
    in
    Printf.printf "New book Id %s\n%!" id

  with Postgresql.Error pe ->
    failwith (Postgresql.string_of_error pe)
  
