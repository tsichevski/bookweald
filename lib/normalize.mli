(** String normalization utilities for book metadata and filenames.

    This module provides functions to clean and normalize names and titles extracted
    from FB2 files (especially Russian-language books). It:

    - Keeps only alphabetic Unicode characters (discards punctuation, digits, symbols).
    - Replaces both Ё and ё with е (standard practice in Russian book indexing).
    - Applies title-case.
    - Returns [None] for strings that become blank after cleaning.

    These functions are used when building stable [Person.id] and [Book.id] values,
    as well as for creating filesystem-safe directory names.
*)

val normalize_name : string -> string option
(** [normalize_name s] normalizes a full name or title.

    It:
    - Splits [s] on the hyphen character '-',
    - Applies [normalize_chunk] to each part,
    - Filters out empty results,
    - Joins surviving parts back with a single space,
    - Trims the final string.

    Returns [None] if the entire result would be empty (e.g. only punctuation or whitespace).

    Example:

    {[
      normalize_name "Лев Николаевич Толстой" = Some "Лев Николаевич Толстой"
      normalize_name "Толстой, Л. Н."         = Some "Толстой Л Н"
      normalize_name "!!!   "                 = None
      normalize_name "War and Peace"          = Some "War And Peace"
    ]}

*)