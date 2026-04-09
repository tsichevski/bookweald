(** Input channel with mark/reset capabilities.

    This module implements a buffering input channel on top of a [char Seq.t].
    It supports marking a position, recording bytes while reading, and later
    resetting to the mark (replaying the recorded bytes) or dropping the mark.

    Primarily used by the recoding and XML declaration parsers to support
    lookahead and backtracking without consuming the underlying stream twice.
*)

type t
(** Abstract type of a markable input channel. *)

val create : char Seq.t -> t
(** [create seq] creates a new input channel backed by the given character sequence. *)

val mark : t -> unit
(** [mark ch] starts recording all subsequent bytes read from the channel. *)

val reset : t -> unit
(** [reset ch] reverts the channel to the position of the last [mark].
    Future reads will replay the recorded bytes. *)

val drop_mark : t -> unit
(** [drop_mark ch] commits the current recording and clears the mark.
    The recorded bytes are discarded and the channel continues from the current position. *)

val to_seq : t -> char Seq.t
(** [to_seq ch] returns a fresh sequence that reads from the channel,
    respecting the current mark/recording state. *)

(** {1 Legacy functions (kept for compatibility)} *)

val take : int -> char Seq.t -> string * char Seq.t
(** [take n seq] consumes up to [n] characters from the sequence and returns
    them as a string together with the remaining sequence. *)
