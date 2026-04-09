type t = {
  library_dir : string;
  target_dir : string;
  dry_run : bool [@default false];
  max_component_len : int [@default 0];
  jobs : int [@default 1];
  log_file : string option [@default None];
  blacklist : string option [@default None];
  drop_existing_log_file_on_start : bool [@default false];
  log_level : string option [@default None];
  alias_file : string option [@default None];
  database : database_config;
} [@@deriving yojson]

and database_config = {
  host : string   [@default "localhost"];
  port : int [@default 5432];
  user : string [@default "books"];
  passwd : string [@default "books"];
  name : string [@default "books"];
  admin : string [@default "admin"];
  admin_passwd : string [@default "admin"];
} [@@deriving yojson]

let default_database () : database_config =
  {
    host         = "localhost";
    port         = 5432;
    user         = "books";
    passwd       = "books";
    name         = "books";
    admin        = "admin";
    admin_passwd = "admin"
  }

let default () : t =
  let home = Sys.getenv "HOME" in
  {
    library_dir      = Filename.concat home "books/incoming";
    target_dir       = Filename.concat home "books/organized";
    alias_file       = None;
    dry_run          = false;
    max_component_len = 0;
    jobs             = 1;
    log_file         = None;
    log_level        = None;
    drop_existing_log_file_on_start = false;
    blacklist = None;
    
    database         = default_database ()
  }

let load path : t =
  try
    match of_yojson (Yojson.Safe.from_file path) with
    | Ok cfg -> cfg
    | Error e ->
        failwith (Printf.sprintf "Invalid configuration in %s: %s" path e)
  with e ->
    Printf.eprintf "Cannot read configuration file %s: %s\n" path (Printexc.to_string e);
    raise e

let create_default (path : string) (overwrite : bool) =
  let dir = Filename.dirname path in
  if not (Sys.file_exists dir) then
    Fs.mkdir_p dir ~perm:0o755;

  if not (Sys.file_exists path) || overwrite then
    begin
      let cfg = default () in
      let json = to_yojson cfg in
      let pretty = Yojson.Safe.pretty_to_string ~std:true json in

      Out_channel.with_open_gen [Open_wronly; Open_creat] 0o644 path
        (fun oc -> output_string oc (pretty ^ "\n"));
      true
    end else false