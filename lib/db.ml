(* Pluggable database backend for book library, using Caqti.
   Adapted for the book type with multiple authors.
   Handles many-to-many via junction table for efficient grouping/lookups.
   Assumes SQLite or PostgreSQL; queries are portable.
*)

open Book
open Person
open Postgresql
open Normalize

module Log = (val Logs.src_log (Logs.Src.create "db" ~doc:"Database access") : Logs.LOG)

type book_id = string     (** DB internal book serial id *)
type connection = Postgresql.connection

let opt_to_param = function
  | None   -> null
  | Some s -> s

let opt_to_string = function
  | None   -> "<unknown>"
  | Some s -> s

let log_book (b : book) op =
  Log.debug (fun m -> m "%s book: digest=%s title=%s file=%s encoding=%s" op (digest b) b.title b.filename b.encoding)
  
let log_person ?(level = Logs.Debug) (p : person) op =
  Log.msg level (fun m -> m "%s person: l:%s f:%s m:%s (%s)"
    op
    (opt_to_string p.last_name)
    (opt_to_string p.first_name)
    (opt_to_string p.middle_name)
    p.id
  )
  
(** Insert new book record *)
let insert_book (c : connection) (b : book) =
  log_book b "Inserting";
  let new_id = c#exec {|INSERT INTO books (digest, ext_id, version, title, encoding, lang, genre, filename) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id|}
    ~params:[| digest b; opt_to_param b.ext_id; opt_to_param b.version; b.title; b.encoding; opt_to_param b.lang; opt_to_param b.genre; b.filename |]
    ~expect:[Tuples_ok]
  in
     if new_id#ntuples = 0 then
       failwith "Cannot insert new book"
     else
       new_id#getvalue 0 0
       
let find_person_opt (c : connection) (norm : string) =
  Log.debug (fun m -> m "Lookup person opt: %s" norm);
  let existing = c#exec
    "SELECT id FROM persons WHERE normalized_name=$1"
    ~params:[| norm |]
    ~expect:[Tuples_ok]
  in
  match existing#ntuples with
  | 0 ->
    Log.debug (fun m -> m "No person found: %s" norm);
    None
  | 1 ->
    let book_id = existing#getvalue 0 0 in
    Log.debug (fun m -> m "Found: %s for %s" book_id norm);
    Some book_id
  | _ -> failwith ("More than one person with id: " ^ norm)

(** [insert_person c norm a] atomically registers an author in the
    [persons] table and returns its primary key [id].

    If a person with the same [normalized_name] already exists, the
    existing [id] is returned. Otherwise a new row is inserted.

    This UPSERT pattern guarantees exactly-once semantics under
    concurrent execution from multiple indexing threads.

    @param c      PostgreSQL connection (Postgresql.connection)
    @param norm   Unicode-normalized name used for uniqueness
    @param a      Author record containing optional first/middle/last names
                  (original spelling, possibly containing legacy Russian
                  charset characters already converted to Unicode)

    @return       The integer person [id] (as string, per Postgresql API)

    @raise Failure if the query unexpectedly returns zero rows
*)
let insert_person (c : connection) norm a =
  log_person a "Inserting";
  let new_id = c#exec {sql|
INSERT INTO persons (first_name, middle_name, last_name, normalized_name)
VALUES ($1, $2, $3, $4)
ON CONFLICT (normalized_name)
DO UPDATE SET id = persons.id   -- true no-op
RETURNING id
|sql}
    ~params:[| opt_to_param a.first_name; opt_to_param a.middle_name; opt_to_param a.last_name; norm |]
  in
  if new_id#ntuples = 0 then begin
    log_person ~level:Error a "No person inserted";
    failwith "No person inserted"
  end
  else
    new_id#getvalue 0 0

let find_or_insert_person (c : connection) a =
  let norm = normalize_person_key a in
  log_person a "Find or Insert";
  match find_person_opt c norm with
  | Some id -> id
  | None ->
    insert_person c norm a

let insert_link (c : connection) book_id person_id =
  Log.debug (fun m -> m "Add link: %s %s" book_id person_id);
  ignore(c#exec {|INSERT INTO book_authors (book_id, person_id) VALUES ($1, $2)|}
    ~params:[| book_id; person_id |]
    ~expect:[Command_ok])
  
(** Delete existing book record by id+title *)
let delete_book (c : connection) (b : book) =
  log_book b "Deleting";
  let new_id = c#exec {|DELETE FROM books WHERE id=$1 AND title=$2, $3, $4) RETURNING id|}
    ~params:[| digest b; b.title; opt_to_param b.lang; opt_to_param b.genre |]
    ~expect:[Tuples_ok]
  in
     if new_id#ntuples = 0 then
       failwith "Cannot delete book"
     else
       new_id#getvalue 0 0
       
let find_or_insert_book (c : connection) (b : book) : book_id =
  let title = b.title in
  let authors = b.authors in
  let digest = digest b in
  let filename = b.filename in
  (* Existing books with given book id and title *)
  log_book b "Looking for existing";
  let existing_book = c#exec
    "SELECT books.id FROM books, book_authors, persons WHERE books.digest = $1 AND book_authors.book_id=books.id AND book_authors.person_id=person.id"
    ~params:[| digest |] in
  let new_book_id, persons_to_add =
    match existing_book#ntuples with
    | 0 ->
      log_book b "Will insert";
      let book_id = insert_book c b in
      Log.debug (fun m -> m "Created new book: digest=%s, title=%s new id=%s, file=%s" digest title book_id filename);
      (book_id, authors)
    | 1 ->
      log_book b "Existing";
      (* collect missing persons, add missing links *)
      let book_id = existing_book#getvalue 0 0 in
      (* Get book authors *)
      let existing = c#exec
        "SELECT person.normalized_name FROM books, book_authors, persons WHERE books.id = $1 AND book_authors.person_id=persons.id AND book_authors.book_id=books.id"
        ~params:[| digest |] in
      let ntuples = existing#ntuples in
      Log.debug (fun m -> m "Will update existing book: digest=%s, title=%s, id=%s, %d authors" digest title book_id ntuples);
      
      (* Collect existing normalized person names *)
      let rec collect accu i =
        if i = ntuples then
          accu
        else
          let existing_norm = existing#getvalue i 0 in
          collect (existing_norm::accu) (i + 1) in
      let existing_norms = collect [] 0 in
      
      (* Collect missing persons *)
      (book_id, List.filter (fun a -> List.exists (fun n -> not ((normalize_person_key a) = n)) existing_norms) authors)
      
    | n ->
      Log.warn (fun m -> m "More than one book (%d) with same id and title found" n);
      failwith "Multiple books with same id and title found"
  in
  let person_ids_to_add = List.map (fun a -> find_or_insert_person c a) persons_to_add in
  ignore(List.iter (fun person_id -> insert_link c new_book_id person_id) person_ids_to_add);
  new_book_id
  
let connect
  ?(host = "localhost")
  ?(port = 5432)
  ?(user = "books")
  ?(password = "books")
  ?(dbname = "books")
  ()
  =
  new connection
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
            digest TEXT UNIQUE NOT NULL,
            ext_id TEXT,
            version TEXT,
            title TEXT,
            encoding TEXT,
            lang TEXT,
            genre TEXT,
            filename TEXT
          ) |sql};
    {sql| CREATE TABLE IF NOT EXISTS persons (
            id SERIAL PRIMARY KEY,
            first_name TEXT,
            middle_name TEXT,
            last_name TEXT,
            normalized_name TEXT UNIQUE NOT NULL
          ) |sql};
    {sql| CREATE TABLE IF NOT EXISTS book_authors (
            book_id INTEGER,
            person_id INTEGER,
            PRIMARY KEY (book_id, person_id),
            FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
            FOREIGN KEY (person_id) REFERENCES persons(id) ON DELETE CASCADE
          ) |sql};
  ]
  in
  List.iter (fun q -> ignore (c#exec ~expect:[Command_ok] q)) queries;

