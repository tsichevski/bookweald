(* Unzip file support *)
(*
  utop:
#require "zip";;
 *)
open Zip
open Fs

(** {1 ZIP utilities}

    Helpers for safe and exception-safe handling of ZIP archives using the camlzip library.
*)

(** [with_zip_in zip_path f] opens the ZIP archive located at [zip_path],
    passes the resulting [Zip.in_file] handle to the user-provided function [f],
    and guarantees that the archive is properly closed when [f] terminates —
    whether normally or by raising an exception.

    This function follows the RAII (Resource Acquisition Is Initialization) pattern
    using [Fun.protect], making it the preferred way to work with ZIP files in this project.

    @param zip_path Absolute or relative path to a valid ZIP file
    @param f A function that takes an opened [Zip.in_file] and returns a value of type ['a]
    @return The result of applying [f] to the opened ZIP handle
    @raise Sys_error if the file cannot be opened (e.g. does not exist, permission denied)
    @raise Zip.Error if the file is not a valid ZIP archive or is corrupted

    Example — list all entries in an archive:
    {[
      let entries =
        with_zip_in "library.zip" @@ fun zip ->
        Zip.entries zip
    ]}

    Example — process only FB2 files (used internally by [extract_fb2_files]):
    {[
      with_zip_in archive_path @@ fun zip ->
      List.iter (fun entry ->
        if Filename.check_suffix entry.filename ".fb2" then
          (* process entry *)
      ) (Zip.entries zip)
    ]}
*)
let with_zip_in zip_path f =
  let zip = ref None in
  Fun.protect
    ~finally:(fun () ->
      match !zip with
      | Some z -> Zip.close_in z
      | None   -> ())
    (fun () ->
      let z = Zip.open_in zip_path in
      zip := Some z;
      f z)
;;

(** [extract_fb2_files zip_path target_dir] extracts all files with the
    extension [.fb2] from the ZIP archive at [zip_path] into [target_dir].

    Requirements:
    - The archive **must** contain at least one regular file ending with [.fb2].
    - If no [.fb2] files are found, raises [Invalid_argument].

    Behaviour:
    - Only regular files (not directories) ending in [.fb2] are processed.
    - Parent directories are created automatically using [Fs.mkdir_p].
    - Existing files in [target_dir] will be overwritten.
    - Extraction progress is printed to stdout; errors during single-file
      extraction are printed to stderr but do not stop the whole process.

    @param zip_path Path to the source ZIP archive
    @param target_dir Directory where extracted .fb2 files will be placed
    @return List of full paths to successfully extracted .fb2 files
            (in the order they appeared in the archive)

    @raise Invalid_argument if the archive contains no [.fb2] files
    @raise Sys_error / Unix.Unix_error on file system errors preventing extraction
    @raise Zip.Error on ZIP format or reading errors

    Example:
    {[
      let paths = extract_fb2_files "books.zip" "/tmp/raw-fb2" in
      List.iter (Printf.printf "Extracted: %s\n") paths;
      Printf.printf "Total: %d files\n" (List.length paths)
    ]}
*)
let extract_fb2_files zip_path target_dir =
  with_zip_in zip_path @@ fun zip ->

  let fb2_entries =
    Zip.entries zip
    |> List.filter (fun entry ->
         not entry.is_directory && Filename.check_suffix entry.filename ".fb2")
  in

  if fb2_entries = [] then
    raise (Invalid_argument
             (Printf.sprintf "No .fb2 files found in archive: %s" zip_path));

  (* Folding function: acc is list of successful paths, entry is current Zip.entry *)
  let extract_one acc entry =
    try
      let basename = Filename.basename entry.filename in
      let out_path = Filename.concat target_dir basename in

      let dir = Filename.dirname out_path in
      if not (Sys.file_exists dir) then Fs.mkdir_p dir;

      Zip.copy_entry_to_file zip entry out_path;

      Printf.printf "Extracted: %s\n" basename;

      out_path :: acc          (* prepend → we reverse later *)
    with e ->
      Printf.eprintf "Error extracting %s: %s\n"
        entry.filename (Printexc.to_string e);
      acc                      (* keep going, don't add failed file *)
  in

  List.fold_left extract_one [] fb2_entries
  |> List.rev
