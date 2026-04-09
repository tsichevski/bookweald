(** Configuration loading and management for BookWeald.

    This module defines the main configuration type [t] and provides functions
    to load it from JSON files with fallback to sensible defaults.

    Config files are searched in this order (first match wins):

    1. ``./config.json`` (local override, useful for development)
    2. ``~/.config/bookweald/config.json`` (user-wide, XDG-style)

    The configuration is serialized/deserialized using ``yojson`` and
    ``ppx_deriving_yojson`` for type safety.

    All optional fields default to [None] or sensible values when missing.
*)

(** Main configuration record.

    Fields control library paths, behavior flags, parallelism, logging,
    author aliases, and PostgreSQL connection settings.

    Example JSON snippet:

    {[
      {
        "library_dir": "/home/user/books/incoming",
        "target_dir": "/home/user/books/organized",
        "dry_run": false,
        "jobs": 4,
        "database": {
          "host": "localhost",
          "port": 5432,
          "user": "books",
          "passwd": "books",
          "name": "books",
          "admin": "admin",
          "admin_passwd": "admin"
        }
      }
    ]}
*)
type t = {
  (** Directory containing incoming FB2 files. *)
  library_dir : string;

  (** Destination directory for organized books (author-based structure). *)
  target_dir : string;

  (** If [true], simulate all operations without modifying the filesystem or database. *)
  dry_run : bool [@default false];

  (** Maximum allowed length of a single filename component (directory or file name).
      [0] means no limit (default). *)
  max_component_len : int [@default 0];

  (** Number of parallel jobs (domain pool). Set to [1] to disable parallelism. *)
  jobs : int [@default 1];

  (** Optional path to a log file. If [None], logs go to stdout. *)
  log_file : string option [@default None];

  (** Optional path to the file black list.
      If omitted in JSON or set to null → None.
      If [None], illegal files will not be managed. *)
  blacklist : string option [@default None];

  (** If [true] and [log_file] is set: truncate the log file on startup
      (drop existing content). Otherwise append (default).
      Has no effect when [log_file = None]. *)
  drop_existing_log_file_on_start : bool [@default false];

  (** Optional logging level override.
      Supported values: "quiet", "error", "warning", "info", "debug", "app".
      If [None], the default level (INFO) is used. *)
  log_level : string option [@default None];

  (** Optional path to author alias JSON file (see {!Alias.load_aliases}). *)
  alias_file : string option [@default None];

  (** Grouped PostgreSQL connection settings (preferred). *)
  database : database_config;
} [@@deriving yojson]

and database_config = {
  (** Database hostname. *)
  host : string   [@default "localhost"];

  (** Database port (default: 5432). *)
  port : int [@default 5432];

  (** Database username for normal operations. *)
  user : string [@default "books"];

  (** Password for the normal database user. *)
  passwd : string [@default "books"];

  (** Database name. *)
  name : string [@default "books"];

  (** Admin username (used for schema initialization). *)
  admin : string [@default "admin"];

  (** Admin password (used for schema initialization). *)
  admin_passwd : string [@default "admin"];
} [@@deriving yojson]

(** [default_database] returns sensible defaults for the database section. *)
val default_database : unit -> database_config

(** [default ()] returns the hardcoded default configuration.

    Paths are based on ``$HOME/books/...``. Most optional fields are [None].
    Useful as a fallback when no config file is found or when creating a new one.
*)
val default : unit -> t

(** [load path] loads and parses a configuration from the given JSON file.

    Uses strict=false deriver so unknown fields are ignored.
    Raises [Failure] with a descriptive message if the JSON is invalid or
    cannot be converted to type [t].
*)
val load : string -> t

(** [create_default path overwrite] writes a default configuration to [path] in pretty-printed JSON.

    - Creates parent directories if they do not exist (using {!Fs.mkdir_p}).
    - Overwrites the file if it already exists and [overwrite] is [true].
*)
val create_default : string -> bool -> bool
