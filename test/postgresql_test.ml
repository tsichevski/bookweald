(* Experimenting with posgresql library *)

let schema_create () =
  Printf.printf "About to admin connect\n%!";
  let db = new Postgresql.connection ~host:"localhost" ~dbname:"books" ~user:"admin" () in
  Printf.printf "Connected\n%!";

  ignore(db#exec ~expect:[Command_ok] {|
  CREATE TABLE IF NOT EXISTS books (
  id          SERIAL PRIMARY KEY,
  filename    TEXT NOT NULL,
  title       TEXT,
  author      TEXT,
  author_norm TEXT GENERATED ALWAYS AS (lower(author)) STORED,
  zip_path    TEXT
  );
  CREATE INDEX IF NOT EXISTS idx_author_norm ON books (author_norm);
  CREATE INDEX IF NOT EXISTS idx_title     ON books USING gin (to_tsvector('russian', title));
  |});
  db#finish

let () =
  try 
    ignore(schema_create ());  
    Printf.printf "About to connect 'books' user\n%!";
    let db = new Postgresql.connection ~host:"localhost" ~dbname:"books" ~user:"books" () in
    Printf.printf "Connected\n%!";

    (* Insert one book *)
    ignore (db#prepare "insert_book" {|INSERT INTO books (filename, title, author, zip_path) VALUES ($1, $2, $3, $4)|});
    ignore (db#exec_prepared ~expect:[Command_ok] ~params:[| "book.fb2.zip"; "Война и мир"; "Лев Толстой"; Postgresql.null |] "insert_book");

    Printf.printf "Book inserted\n%!";
    (* Query by author prefix *)
    let res = db#exec
      (* ~expect:[Tuples_ok] *)
      "SELECT title, author FROM books WHERE author ILIKE $1 ORDER BY author_norm, title" ~params:[| "%Толст%"; |] in
    Printf.printf "Select executed, %d tuples\n%!" res#ntuples;

    for i = 0 to res#ntuples - 1 do
      Printf.printf "%s — %s\n" (res#getvalue i 0) (res#getvalue i 1)
    done;

    db#finish
    
  with Postgresql.Error s ->
    Printf.printf "Error %s\n%!" (Postgresql.string_of_error s);
