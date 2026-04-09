open Logs

let setup truncate path =
  try
    let append_trunc = if truncate then Open_trunc else Open_append in
    let oc = open_out_gen (append_trunc::[Open_wronly; Open_creat]) 0o644 path in
    let f = Format.formatter_of_out_channel oc in

    let report src level ~over k msgf =
      let k _ = over (); k () in
      let pp_header ppf () =
        let level_str = level_to_string (Some level) in
        let thread_id =
          if Domain.is_main_domain () then
            "main"
          else
            Domain.self_index () |> string_of_int
        in
        Format.fprintf ppf "[%s][%s][%s] " level_str (Src.name src) thread_id
      in
      msgf @@ fun ?header ?tags fmt ->
        Format.kfprintf k f ("%a" ^^ fmt ^^ "@.") pp_header ()
    in

    let reporter = { report } in
    Logs.set_reporter reporter;

    Logs.info (fun m -> m "Logging initialized to file: %s" path)
  with e ->
    failwith (Printf.sprintf
      "Cannot setup logging to file %s: %s" path (Printexc.to_string e))