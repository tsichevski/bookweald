(** Unzip utilities for handling .fb2.zip archives.

    This module extracts .fb2 files from ZIP archives.

    - For archives ≤ 4.5 GB it uses the pure OCaml [Zipc] library.
    - For archives > 4.5 GB it falls back to the external [7z] tool to avoid memory exhaustion.
*)

val extract_fb2_files :
  ?overwrite:bool -> string -> string -> (string list, string) result
(** [extract_fb2_files ?overwrite zip_path target_dir] extracts all files
    ending with [.fb2] from the given ZIP archive into [target_dir].

    - Creates necessary parent directories using [Fs.mkdir_p].
    - If [overwrite] is false (default is true), existing files are skipped.
    - For large archives (> 4.5 GB) it runs `7z x ...` and returns Ok [] (caller must scan target_dir).
    - Returns the list of extracted full paths on success (for normal-sized archives).
*)

val unzip_fb2_file : char Seq.t -> char Seq.t
(** [unzip_fb2_file src] extracts the single .fb2 file from a ZIP byte stream (used internally when processing .fb2.zip files).

    Raises [Failure] if:
    - The archive contains no .fb2 file,
    - The archive contains more than one .fb2 file,
    - ZIP parsing or decompression fails.
*)