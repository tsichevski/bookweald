=====================================
Recoding Channel for Legacy Encodings
=====================================

.. contents::
   :depth: 2
   :local:


Purpose
-------

Many legacy Russian FB2 files use non-Unicode encodings such as:

- ``windows-1251`` (CP1251) — most common
- ``koi8-r`` — another popular legacy encoding

The standard ``xmlm`` parser expects Unicode input (UTF-8 / UTF-16 / ISO-8859-1).  
When fed CP1251 or KOI8-R bytes directly it will fail or produce garbage.

This module provides a **recoding channel** — a wrapper around ``In_channel.t`` that:

- reads bytes from the source
- applies a per-byte recoding table for the upper half (0x80–0xFF)
- outputs UTF-8 bytes on demand
- keeps memory usage low (small internal buffer)

The lower half (0x00–0x7F) is passed through unchanged (ASCII identity).

Supported encodings (2025)
--------------------------

- ``windows-1251`` (CP1251) — full mapping table provided
- ``koi8-r`` — full mapping table provided
- ``direct`` (no recoding) — for already UTF-8 files

Usage pattern
-------------

.. code-block:: ocaml

   let ic = In_channel.open_text path in
   let rindex = Recoding_channel.create_cp1251 ic in
   let input = Xmlm.make_input (`Fun (Recoding_channel.input_byte rindex)) in
   (* parse with xmlm ... *)

Implementation details
----------------------

The recoder maintains a small internal buffer (up to 4 bytes) that holds UTF-8 bytes
produced from a single CP1251/KOI8-R input byte.

When the buffer is empty, it reads one byte from the source channel and:

- if < 128 → passes it through
- if ≥ 128 → looks up the corresponding Unicode scalar value in the table,
  encodes it as UTF-8 into the buffer, and returns bytes one by one

This ensures:

- zero-copy for ASCII range
- minimal memory overhead (buffer ≤ 4 bytes)
- correct UTF-8 output for xmlm

Mapping tables
--------------

Both tables are taken from standard sources (RFC 1489 for KOI8-R, Microsoft CP1251 spec).

**CP1251 table** (0x80–0xFF):

::

   Uchar.of_int 0x0402; (* Ђ *)
   Uchar.of_int 0x0403; (* Ѓ *)
   Uchar.of_int 0x201A; (* ‚ *)
   Uchar.of_int 0x0453; (* ѓ *)
   Uchar.of_int 0x201E; (* „ *)
   Uchar.of_int 0x2026; (* … *)
   Uchar.of_int 0x2020; (* † *)
   Uchar.of_int 0x2021; (* ‡ *)
   Uchar.of_int 0x20AC; (* € *)
   Uchar.of_int 0x2030; (* ‰ *)
   Uchar.of_int 0x0409; (* Љ *)
   Uchar.of_int 0x2039; (* ‹ *)
   Uchar.of_int 0x040A; (* Њ *)
   Uchar.of_int 0x040C; (* Ќ *)
   Uchar.of_int 0x040B; (* Ћ *)
   Uchar.of_int 0x040F; (* Џ *)
   (* ... full 128 entries ... *)

**KOI8-R table** (0x80–0xFF):

::

   Uchar.of_int 0x2500; (* ─ *)
   Uchar.of_int 0x2502; (* │ *)
   Uchar.of_int 0x250C; (* ┌ *)
   (* ... full 128 entries ... *)

Usage in FB2 parsing
--------------------

::

   let ic = In_channel.open_text path in
   let rindex = Recoding_channel.create_cp1251 ic in
   let input = Xmlm.make_input (`Fun (Recoding_channel.input_byte rindex)) in
   (* now use xmlm streaming parser *)

   (* When finished, close the original channel *)
   In_channel.close ic

Notes & limitations
-------------------

- The recoder only handles **single-byte encodings** (CP1251, KOI8-R).
- Multi-byte encodings (UTF-16, etc.) are not supported.
- Assumes the XML declaration correctly specifies the encoding.
- For very large files the original file is still opened and read byte-by-byte — memory usage stays low.
- If the declared encoding is not supported, the recoder raises an exception.

Future extensions
-----------------

- Add more tables (CP866, ISO-8859-5, etc.)
- Automatic encoding detection from XML declaration
- Streaming conversion without full file read (currently reads on demand)

See also
--------

- xmlm documentation — streaming XML parser
- Camomile / Uutf — alternative Unicode handling (if needed later)
  