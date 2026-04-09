(** Blacklist management for invalid or skipped FB2 files.

    The blacklist is a simple text file (default: [blacklist.txt]) that records
    paths of files that failed validation or should be ignored in future runs.
    Each line has the format [basename|comment].

    This module follows the style of other .mli files in the project (e.g. db.mli,
    fb2_parse.mli) and uses odoc markup. *)

val append : string -> string -> string -> unit
(** [append file path comment] appends a line [basename(path)|comment] to the blacklist file.
    Creates parent directories if needed. *)

val load : string -> (string, string) Hashtbl.t
(** [load path] reads the blacklist file into a hashtable (key = basename, value = comment).
    Lines starting with [#] are ignored.
    Malformed lines raise [Failure].
    If the file does not exist, logs a message and returns an empty table. *)