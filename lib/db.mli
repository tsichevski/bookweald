val normalize_person : Book.person -> string
type connection
val connect :
  ?host:string ->
  ?port:int ->
  ?user:string ->
  ?password:string ->
  ?dbname:string ->
  unit ->
    connection
val close : connection -> unit
val init_schema : connection -> unit
val drop_schema : connection -> unit
val find_or_insert_person : connection -> Book.person -> string
(** Find existing book by external id and title, or insert the book into DB. Return book internal ID *)
val find_or_insert_book : connection -> Book.book -> string

