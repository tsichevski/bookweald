(** Database interface for persistent book indexing.

    Uses PostgreSQL via the ``ocaml-postgresql`` library.
    Stores book metadata and normalized author information.
    All text is expected to be UTF-8.
*)

open Book

(** {1 Types} *)

type connection
(** Abstract type representing an open PostgreSQL connection. *)

(** {1 Connection management} *)

val connect : ?host:string -> ?port:int -> ?user:string -> ?password:string -> ?dbname:string -> unit -> connection
(** [connect ?host ?port ?user ?password ?dbname ()] establishes a connection
    to the PostgreSQL server using the given parameters (or defaults).

    @raise Failure if connection cannot be established
*)

val close : connection -> unit
(** [close conn] closes the database connection.

    Safe to call multiple times.
*)

(** {1 Schema management} *)

val init_schema : connection -> unit
(** [init_schema conn] creates the required tables and indexes if they do not exist.

    Currently creates tables for persons (authors) and books.
    Idempotent operation.
*)

val drop_schema : connection -> unit
(** [drop_schema conn] drops all tables created by [init_schema].

    Use with caution — irreversible data loss.
*)

(** {1 Person (author) operations} *)

val find_or_insert_person : connection -> person -> string
(** [find_or_insert_person conn p] looks up the person by normalized name;
    inserts a new record if not found.

    @return internal database ID of the person (as string)
    @raise Failure on database errors
*)

(** {1 Book operations} *)

val find_or_insert_book : connection -> book -> string
(** [find_or_insert_book conn b] looks for a book by its external id and title;
    inserts a new record if not found.

    Links the book to its authors via person IDs.

    @return internal database ID of the book (as string)
    @raise Failure on database errors
    *)


