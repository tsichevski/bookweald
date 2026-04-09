(** Logging setup for BookWeald.

    This module configures the [Logs] library to output structured messages
    with level, source, and thread identifier.

    When a log file is provided, messages are appended to that file.
    Otherwise, the default reporter (usually stderr) is left unchanged.

    Output format for file logging:

    [LEVEL][SOURCE][THREAD] message

    Example line:

    [INFO][fb2_parse][main] Parsed book: Война и мир

    Thread ID is "main" for the main domain or the domain index for parallel workers.
*)

open Logs

val setup : bool -> string -> unit
(** [setup truncate path] configures the Logs reporter to write to the given file.

    - Opens the file in append or truncate mode (creates it if it does not exist).
    - Uses a custom reporter that prefixes every message with:
      - Log level
      - Source name
      - Thread identifier ("main" or domain index)
    - The original reporter is replaced for the whole program.

    If the file cannot be opened, raises [Failure].
*)