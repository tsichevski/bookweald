(* Misc utility functions missing in stdlib *)

(** [substring_index_from haystack needle start] searches for the first occurrence
    of substring [needle] in [haystack], starting the search at byte position [start]
    (inclusive, 0-based).

    Returns [Some pos] where [pos] is the starting byte index of the first match,
    or [None] if no match is found.

    @param haystack the string to search in
    @param needle   the substring to find (may be empty)
    @param start    starting search position (0 ≤ start ≤ String.length haystack)
    @return [Some pos] or [None]

    Performance note: O(n·m) worst-case (linear scan with substring comparison).
    Suitable for typical metadata/filename lengths in this project.

    Special case: if [needle] is empty string, returns [Some start] (standard convention).

    Raises nothing. *)
let substring_index_from haystack needle start =
  let n_len = String.length needle in
  if n_len = 0 then Some start
  else
    let rec loop pos =
      (* Check if remaining suffix is long enough to contain needle *)
      if pos + n_len > String.length haystack then None
      (* Compare substring starting at pos *)
      else if String.sub haystack pos n_len = needle then Some pos
      else loop (pos + 1)
    in loop start

(** [substring_index haystack needle] searches for the first occurrence
    of substring [needle] in [haystack], starting from position 0.

    Equivalent to [substring_index_from haystack needle 0].

    @param haystack the string to search in
    @param needle   the substring to find
    @return [Some pos] or [None] *)
let substring_index haystack needle =
  substring_index_from haystack needle 0