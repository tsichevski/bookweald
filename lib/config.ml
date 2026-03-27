(* Configuration loading and saving for the OCaml Books tool.
   Handles JSON-based config files with fallback to defaults.
   Uses yojson for parsing/serialization and ppx_deriving_yojson for type-safe conversions.

   Dependencies: yojson, ppx_deriving_yojson, sys, filename, printf (standard library).
   No external non-OPAM dependencies.

   Config locations checked in order:
   1. ./config.json (local, for project-specific overrides)
   2. ~/.config/bookweald/config.json (user-global, standard XDG location)

   All functions are pure except for I/O side-effects in load/create_default. *)

(** Configuration type with all settings used by the tool. *)
type t = {
  library_dir     : string;             (* Source directory with ZIPs or raw FB2 files *)
  target_dir      : string;             (* Destination directory for organized books *)
  invalid_dir     : string;             (* Destination directory for files failded validation *)
  dry_run         : bool;               (* If true: simulate actions without changes *)
  verbose         : bool;               (* If true: print detailed progress info *)
  max_component_len: int;               (* Maximum length of one filename component or 0 (default) for no limit *)
  jobs: int;                            (* Number of jobs domain pool, 1 to disable parallelism *)
  log_file        : string option;      (* Path to the log file or None to log to stdout *)
  log_level       : string option;      (* Logging level or None for default INFO or Some ("quiet"|"app"|"error"|"warning"|"info"| "debug") *)
  alias_file      : string option;      (* Location of optional person alias JSON file *)

  (* PostgreSQL connection *)
  
  db_host:string;                       (* Connection hostname *)
  db_port:int;
  db_user:string;
  db_passwd:string;
  db_name:string;
  db_admin:string;
  db_admin_passwd:string
  
} [@@deriving yojson { strict = false }]

(** [default ()] returns the hardcoded default configuration values. *)
let default () : t = {
  library_dir      = Filename.concat (Sys.getenv "HOME") "books/incoming";
  target_dir       = Filename.concat (Sys.getenv "HOME") "books/organized";
  invalid_dir      = Filename.concat (Sys.getenv "HOME") "books/invalid";
  alias_file       = None;
  dry_run          = false;
  verbose          = true;
  max_component_len = 0;
  jobs             = 1;
  log_file         = None;  
  log_level        = None;
  
  (* PostgreSQL connection *)
  db_host          = "localhost";
  db_port          = 5432;
  db_user          = "books";
  db_passwd        = "books";
  db_name          = "books";
  db_admin         = "admin";
  db_admin_passwd  = "admin"
}

let load path : t =
  try
    match of_yojson (Yojson.Safe.from_file path) with
    | Ok cfg -> cfg
    | Error e ->
      failwith (Printf.sprintf "Invalid config %s: %s" path e)
  with e ->
    Printf.eprintf "Cannot read config %s: %s\n" path (Printexc.to_string e);
    raise e

(** [create_default path] writes a default configuration to [path] in pretty-printed JSON.
    Creates parent directories if needed using Fs.mkdir_p.
    Overwrites the file if it already exists.
    Prints success message to stdout.

    @raise Sys_error on file creation/write failure
    @raise Failure from Fs.mkdir_p if directory creation fails *)
let create_default (path : string) : unit =
  let cfg = default () in
  let json = to_yojson cfg in
  let pretty = Yojson.Safe.pretty_to_string ~std:true json in

  let dir = Filename.dirname path in
  if not (Sys.file_exists dir) then begin
      Fs.mkdir_p dir ~perm:0o755
    end;

  let oc = open_out path in
  Fun.protect ~finally:(fun () -> close_out_noerr oc)
    (fun () ->
      output_string oc (pretty ^ "\n");
      flush oc);

  Printf.printf "Default configuration written to %s\n" path