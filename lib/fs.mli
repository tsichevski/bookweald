(** Filesystem utilities.

    Provides safe directory creation with parents, file type checks,
    filename sanitization for cross-platform use, and binary file reading.
*)

(** {1 Directory operations} *)

val mkdir_p : ?perm:int -> string -> unit
(** [mkdir_p ?perm path] creates the directory [path] and all missing parent
    directories. Behaves like [mkdir -p].

    Uses permission [0o755] by default. Raises [Failure] on errors.
*)

(** {1 File checks} *)

val is_regular_file : string -> bool
(** [is_regular_file path] returns [true] if the path exists and is a regular
    file (not a directory or special file).
*)

(** {1 Filename utilities} *)

val sanitize_filename : string -> int -> string
(** [sanitize_filename s max_len] sanitizes a string for safe use as a
    filename or directory name.

    - Replaces forbidden characters ([/ \ : * ? {|"|} < > |] and control chars) with [_].
    - Trims whitespace.
    - If [max_len > 0] and the result is longer than [max_len], truncates and adds […].
    - Returns ["unnamed"] if the result would be empty.
*)

(** {1 I/O helpers} *)

val read_file_binary : string -> string
(** [read_file_binary path] reads the entire file as binary and returns its
    contents as a string.
*)
    