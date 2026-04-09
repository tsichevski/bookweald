(** Author alias handling for book metadata normalization.

    This module provides utilities to load and apply author aliases from a JSON file.
    Aliases allow mapping variant spellings, pseudonyms, or different transliterations
    of the same person to a single canonical [Person.person] record.

    The resulting hash table is used during FB2 parsing (in [Fb2_parse]) to replace
    alias names with their canonical form, ensuring correct grouping of books by author.
*)
open Person

(** [load_aliases path] loads an author alias table from a JSON file at [path].

    Expected JSON structure:

    {[
      {
        "Canonical Last First Middle": ["alias1", "alias2", ...],
        "Another Author Last First": ["nick1", "nick2"]
      }
    ]}

    * Each key is a canonical person string (passed to [person_from_string_exn]).
    * Each value is a JSON array of alias strings.

    All strings (keys and aliases) are automatically trimmed.
    Duplicate aliases are allowed (later ones overwrite earlier ones in the table).

    Returns a hash table where:
    - key   = trimmed alias string
    - value = canonical {!Person.person} record

    Raises:
    - [Failure] if the root JSON value is not an object.
    - Failures from [person_from_string_exn] if a canonical string is malformed.
    - Malformed entries inside the object (non-string aliases or non-list values)
      are silently ignored.

    Example usage in configuration:

    The table is typically loaded once at startup and passed to [Fb2_parse.parse_book_info].

    Example JSON snippet for aliases:

    {[
      {
        "Толстой Лев Николаевич": ["Толстой Л.Н.", "Leo Tolstoy", "Толстой Л Н"]
      }
    ]}
*)
val load_aliases : string -> (string, person) Hashtbl.t
