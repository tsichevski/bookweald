(* Pluggable database backend for book library, using Caqti.
   Adapted for the book type with multiple authors.
   Handles many-to-many via junction table for efficient grouping/lookups.
   Assumes SQLite or PostgreSQL; queries are portable.
*)

open Book
open Postgresql

(* Internal normalized person key - computed from structured person *)
let normalize_person (a : person) : string =
  let parts = List.filter_map Fun.id [a.last_name; a.first_name; a.middle_name] in
  let full = String.concat " " parts |> String.trim |> String.lowercase_ascii
  in
  (* String.map (function 'ё' | 'Ё' -> 'е' | c -> c) full *)
  full

type connection = Postgresql.connection

let opt_to_param = function
  | None   -> Postgresql.null
  | Some s -> s

(** Delete existing book record by id+title *)
let delete_book (c : connection) (b : book) =
  Printf.printf "delete_book\n%!";
  let new_id = c#exec {|DELETE FROM books WHERE id=$1 AND title=$2, $3, $4) RETURNING id|}
    ~params:[| b.id; b.title; opt_to_param b.lang; opt_to_param b.genre |]
    ~expect:[Tuples_ok]
  in
     if new_id#ntuples = 0 then
       failwith "Cannot delete book"
     else
       new_id#getvalue 0 0
       
(** Insert new book record *)
let insert_book (c : connection) (b : book) =
  Printf.printf "insert_book\n%!";
  let new_id = c#exec {|INSERT INTO books (book_id, title, encoding, lang, genre, filename) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id|}
    ~params:[| b.id; b.title; b.encoding; opt_to_param b.lang; opt_to_param b.genre; b.filename |]
    ~expect:[Tuples_ok]
  in
     if new_id#ntuples = 0 then
       failwith "Cannot insert new book"
     else
       new_id#getvalue 0 0
       
let find_person_opt (c : connection) (norm : string) =
  Printf.printf "find_person_opt\n%!";
  let existing = c#exec
    "SELECT id FROM persons WHERE normalized_name=$1"
    ~params:[| norm |]
    ~expect:[Tuples_ok]
  in
  match existing#ntuples with
  | 0 -> None
  | 1 -> Some (existing#getvalue 0 0)
  | _ -> failwith ("More than one person with id: " ^ norm)

let insert_person (c : connection) norm a =
  Printf.printf "insert_person\n%!";
  let new_id = c#exec {|INSERT INTO persons (first_name, middle_name, last_name, normalized_name) VALUES ($1, $2, $3, $4) RETURNING id|}
    ~params:[| opt_to_param a.first_name; opt_to_param a.middle_name; opt_to_param a.last_name; norm |]
  in
  if new_id#ntuples = 0 then
    failwith "No person inserted"
  else
    new_id#getvalue 0 0

let find_or_insert_person (c : connection) a =
  Printf.printf "find_or_insert_person\n%!";
  let norm = normalize_person a in
  match find_person_opt c norm with
  | Some id -> id
  | None ->
    insert_person c norm a

let insert_crossref (c : connection) book_id person_id =
  Printf.printf "insert_crossref\n%!";
  ignore(c#exec {|INSERT INTO book_authors (book_id, person_id) VALUES ($1, $2)|}
    ~params:[| book_id; person_id |]
    ~expect:[Command_ok])

let find_or_insert_book (c : connection) (b : book) =
  let title = b.title in
  let authors = b.authors in
  let id = b.id in
  (* Existing books with given book title *)
  let existing = c#exec
    "SELECT person.normalized_name FROM books, book_authors, persons WHERE books.id = $1 AND books.title = $2 AND book_authors.book_id=books.id AND book_authors.person_id=person.id"
    ~params:[| id; title |] in
  let new_book_id, persons_to_add =
    match existing#ntuples with
    | 0 ->
      (* Book is new, insert the book, return new book id and all book authors *)
      let book_id = insert_book c b in
      (book_id, authors)
    | 1 ->
      (* Book exist, collect missing persons, add missing links *)
      let book_id = existing#getvalue 0 0 in
      (* Get book authors *)
      let existing = c#exec
        "SELECT person.normalized_name FROM books, book_authors, persons WHERE books.id = $1 AND book_authors.person_id=persons.id AND book_authors.book_id=books.id"
        ~params:[| book_id |] in
      let ntuples = existing#ntuples in
      
      (* Collect existing normalized person names *)
      let rec collect accu i =
        if i = ntuples then
          accu
        else
          let existing_norm = existing#getvalue i 0 in
          collect (existing_norm::accu) (i + 1) in
      let existing_norms = collect [] 0 in
      
      (* Collect missing persons *)
      (book_id, List.filter (fun a -> List.exists (fun n -> not ((normalize_person a) = n)) existing_norms) authors)
      
    | _ -> failwith "More than one book with same id and title found"
  in
  let person_ids_to_add = List.map (fun a -> find_or_insert_person c a) persons_to_add in
  ignore(List.iter (fun person_id -> insert_crossref c new_book_id person_id) person_ids_to_add);
  new_book_id
  
let connect
  ?(host = "localhost")
  ?(port = 5432)
  ?(user = "books")
  ?(password = "books")
  ?(dbname = "books")
  ()
  =
  new Postgresql.connection
    ~host
    ~dbname
    ~user
    ~password
    ~port:(string_of_int port)
    ()

let close c = c#finish

let drop_schema (c : connection) =
  let queries = [
    {sql| DROP TABLE IF EXISTS persons CASCADE|sql};
    {sql| DROP TABLE IF EXISTS books CASCADE|sql};
    {sql| DROP TABLE IF EXISTS book_authors CASCADE|sql};
  ]
  in
  List.iter (fun q -> ignore (c#exec ~expect:[Command_ok] q)) queries
  
let init_schema (c : connection) =
  let queries = [
    {sql| CREATE TABLE IF NOT EXISTS books (
            id SERIAL PRIMARY KEY,
            book_id TEXT NOT NULL,
            title TEXT,
            encoding TEXT,
            lang TEXT,
            genre TEXT,
            filename TEXT,
            UNIQUE(book_id, title)
          ) |sql};
    {sql| CREATE TABLE IF NOT EXISTS persons (
            id SERIAL PRIMARY KEY,
            first_name TEXT,
            middle_name TEXT,
            last_name TEXT,
            normalized_name TEXT UNIQUE
          ) |sql};
    {sql| CREATE TABLE IF NOT EXISTS book_authors (
            book_id INTEGER,
            person_id INTEGER,
            PRIMARY KEY (book_id, person_id),
            FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
            FOREIGN KEY (person_id) REFERENCES persons(id) ON DELETE CASCADE
          ) |sql};
    {sql| CREATE INDEX IF NOT EXISTS idx_person_norm ON persons(normalized_name) |sql};
  ]
  in
  List.iter (fun q -> ignore (c#exec ~expect:[Command_ok] q)) queries;

