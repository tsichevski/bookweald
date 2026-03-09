==================================
Handling Non-Unicode FB2 Encodings
==================================

Problem
=======

The FB2 parser uses ``xmlm`` for XML parsing, which natively supports only Unicode encodings (UTF-8, UTF-16, ISO-8859-1). However, many legacy FB2 files—particularly Russian publications—declare non-Unicode encodings such as ``windows-1251`` (CP1251) in their XML declarations:

.. code-block:: xml

   <?xml version="1.0" encoding="windows-1251"?>
   <FictionBook>...</FictionBook>

When ``xmlm`` encounters such files, it attempts to parse from the beginning, but fails with a decoding error because the file bytes are not in a Unicode encoding. This happens **before** we have a chance to read the encoding declaration.

Why Not Use Xmlm to Detect Encoding?
====================================

``xmlm`` validates character encoding **while parsing**. If the input bytes are CP1251, ``xmlm`` will raise:

.. code-block:: ocaml

   Xmlm.Error (pos, `Unexpected_eoi | `Invalid_char | ...)

This occurs before the ``Dtd`` signal is emitted, making it impossible to extract the encoding declaration using ``xmlm``.

Solution
========

Implement a **manual, non-validating parser** for the XML declaration only:

1. **Extract Raw Declaration Bytes**

   Read bytes from the file until we find ``?>`` (end of declaration marker).
   This is safe because:
   
   - The declaration is ASCII-compatible (``<?xml ... encoding="..."?>``)
   - We only scan for the ``?>`` marker, which is valid ASCII in all encodings
   - We stop reading as soon as we find it (no fixed buffer size)

2. **Parse Encoding Attribute**

   From the raw declaration bytes, extract the encoding using simple string matching:
   
   .. code-block:: ocaml
   
      encoding="windows-1251"
   
   This substring is also ASCII-safe in all encodings.

3. **Convert Entire File**

   Convert the entire file content from detected encoding to UTF-8.

4. **Parse with Xmlm**

   Now ``xmlm`` can safely parse the UTF-8 content.

Architecture
============

**Fb2_parse.ml** (public API)
   Main entry point: ``parse_title_author : string -> (string * string * string)``
   
   Orchestrates the pipeline: detect → convert → parse

**Xml_declaration.ml** (internal)
   Handles raw (non-validating) XML declaration parsing
   
   Functions:
   
   - ``read_declaration : In_channel.t -> string``
     
     Reads raw bytes from channel until ``?>`` marker is found.
     Safe for any encoding because ``?>`` is ASCII-safe.
     Handles any file size (no fixed buffer).
   
   - ``extract_encoding : string -> string``
     
     Parses ``encoding="value"`` from declaration bytes.
     Returns encoding name (lowercase).
     Defaults to ``"utf-8"`` if not found.

**Xml_encoding_convert.ml** (internal)
   Handles character encoding conversion to UTF-8
   
   Functions:
   
   - ``to_utf8 : string -> string -> string``
     
     Converts content from source encoding to UTF-8
   
   - ``convert_cp1251_to_utf8 : string -> string`` (built-in table)
     
     Fast conversion using pre-computed Cyrillic byte map
   
   - ``convert_with_iconv : string -> string -> string`` (system utility)
     
     Falls back to system ``iconv`` for other encodings

How It Works
============

.. code-block:: ocaml

   (* Step 1: Open file *)
   In_channel.with_file path ~binary:true ~f:(fun ic ->
     
     (* Step 2: Read raw XML declaration bytes (safe for any encoding) *)
     let declaration = Xml_declaration.read_declaration ic in
     let encoding = Xml_declaration.extract_encoding declaration in
     
     (* Step 3: Reset channel and read entire file *)
     In_channel.seek ic Int64.zero;
     let raw_content = In_channel.input_all ic in
     
     (* Step 4: Convert to UTF-8 *)
     let utf8_content = Xml_encoding_convert.to_utf8 raw_content encoding in
     
     (* Step 5: Now xmlm can safely parse UTF-8 *)
     let input = Xmlm.make_input (`String (0, utf8_content)) in
     parse_with_xmlm input
   )

Why This Works
==============

1. **Declaration Reading is Encoding-Agnostic**
   
   The XML declaration syntax is always ASCII:
   
   .. code-block:: text
   
      <?xml version="1.0" encoding="..."?>
   
   Even in CP1251, these bytes are identical to ASCII. Only the **content** uses the declared encoding.

2. **No Fixed Buffer Sizes**
   
   Read byte-by-byte until ``?>`` is found. Works for:
   
   - Empty files (no declaration found, default to UTF-8)
   - Minimal declarations (1-line)
   - Large declarations (multiple attributes, long encoding names)

3. **Single File Pass**
   
   - Read and parse declaration (small)
   - Reset channel
   - Read entire file once
   - Convert
   - Parse with xmlm

Benefits
========

- **Correctness**: Handles legacy Russian FB2 files without corruption
- **Robustness**: Works with files of **any size**:
  
  - Empty files
  - Files without declaration
  - Truncated declarations (graceful default to UTF-8)
  
- **Spec-compliant**: Follows XML 1.0 specification for declaration syntax
- **No arbitrary limits**: No fixed buffer sizes
- **No xmlm errors**: Declaration is read before xmlm touches the bytes
- **Compatibility**: Supports ``windows-1251``, ``cp1251``, and ISO-8859-1 via iconv
- **Performance**: Built-in CP1251 converter avoids external process overhead
- **Maintainability**: Separated concerns (detection, conversion, parsing)

Implementation Notes
====================

Declaration Reading Algorithm
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: ocaml

   let read_declaration ic =
     let buf = Buffer.create 256 in
     let rec read_until_marker () =
       match In_channel.input_char ic with
       | None -> 
           (* EOF without ?>: incomplete or no declaration *)
           Buffer.contents buf
       | Some '?' ->
           Buffer.add_char buf '?';
           (match In_channel.input_char ic with
            | Some '>' ->
                Buffer.add_char buf '>';
                Buffer.contents buf  (* Found ?>, stop *)
            | Some c ->
                Buffer.add_char buf c;
                read_until_marker ()
            | None ->
                Buffer.contents buf)
       | Some c ->
           Buffer.add_char buf c;
           read_until_marker ()
     in
     read_until_marker ()

- Reads one byte at a time (no arbitrary limit)
- Stops at ``?>`` marker
- Gracefully handles EOF
- Initial buffer size (256) is just an optimization hint, grows as needed

Encoding Extraction
~~~~~~~~~~~~~~~~~~~

.. code-block:: ocaml

   let extract_encoding declaration =
     match String.substr_index declaration ~pattern:"encoding=\"" with
     | None -> "utf-8"  (* No encoding attribute *)
     | Some pos ->
         let start = pos + String.length "encoding=\"" in
         (match String.index_from declaration start '"' with
          | None -> "utf-8"  (* Malformed *)
          | Some end_pos ->
              String.sub declaration ~pos:start ~len:(end_pos - start)
              |> String.lowercase)

- Uses Base.String utilities (already available)
- Simple substring matching (ASCII-safe)
- Robust error handling (defaults to UTF-8)

Example XML Declarations
=========================

UTF-8 (no conversion needed):

.. code-block:: xml

   <?xml version="1.0" encoding="UTF-8"?>

CP1251 (legacy Russian, raw bytes):

.. code-block:: text

   <?xml version="1.0" encoding="windows-1251"?>
   [... rest of file in CP1251 bytes ...]

No declaration (defaults to UTF-8):

.. code-block:: xml

   <FictionBook>...</FictionBook>

Testing
=======

Test files should include:

- UTF-8 encoded FB2 with declaration
- UTF-8 encoded FB2 without declaration
- CP1251 encoded FB2 with Cyrillic author/title and declaration
- Minimal files (just declaration, no content)
- Large declaration (many attributes)
- Truncated or malformed declaration
- Empty file