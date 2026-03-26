open Logs

let setup_logs path =
  let oc = open_out_gen [Open_wronly; Open_append; Open_creat] 0o644 path in
  let f = Format.formatter_of_out_channel oc in
  let report src level ~over k msgf =
    let k _ = over (); k () in
    let pp_header ppf () =
      let level_str = Logs.level_to_string (Some level) in
      let thread_id = if Domain.is_main_domain () then
        "main"
      else        
        Domain.self_index () |> string_of_int
      in
      Format.fprintf ppf "[%s][%s][%s] "
        level_str
        (Logs.Src.name src)
        thread_id
    in

    msgf @@ fun ?header ?tags fmt ->
      Format.kfprintf k f
        ("%a" ^^ fmt ^^ "@.")
        pp_header ()
  in

  let reporter = { report } in
  Logs.set_reporter reporter
