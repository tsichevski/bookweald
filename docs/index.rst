====================================
Home Book Library Management Project
====================================

.. contents::
   :depth: 2
   :local:

Programming Language
--------------------

OCaml

Location
--------

https://github.com/tsichevski/ocaml-books.git

Goals
-----

- Import ZIPed library archives
- Partially parse books in FB2 format: extract title and author information. Convert legacy Russian character code sets to unicode
- Group books by author
- Make books accessible by author, either:
  
  - Put files into the sub-directories named by authors
  - Create an index file and a tool, which navigates library by author

Challenges and Solutions
------------------------

Dealing with Unicode in OCaml
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

OCaml's standard library has limited Unicode support. The most commonly used library for proper Unicode handling (including UTF-8 strings and conversion from legacy encodings) is **Camomile**.

Alternative modern choices include:

- **Uutf** + **Uucp** + **Uunf** (for UTF decoding/encoding, character properties and normalization)
- **uucd** / **uuseg** ecosystem packages

For converting legacy Russian encodings (CP1251 / windows-1251, KOI8-R, ISO-8859-5, etc.) to Unicode/UTF-8, **Camomile** provides the most straightforward recoding facilities.

Finding an Appropriate Index Format
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Recommended options (persistent / on-disk indices):

1. **index** library (opam package: index)
   
   - Designed exactly for persistent key-value indices in OCaml
   - Supports different backends (pack, layered, etc.)
   - Good performance for this kind of use-case

2. **irmin** (very powerful, git-like versioned store)
   
   - Overkill for simple author → books mapping, but excellent if you later want versioning, branching, or replication

3. **sqlite3** + **caqti** / **sqlite3-ocaml**
   
   - Very simple and widely understood
   - Easy to query with SQL

4. Plain text / JSON / S-expressions + in-memory cache
   
   - Simplest, but scales poorly and requires re-parsing on every start

For most book library use-cases **index** or **sqlite3** are the best balance of simplicity and performance.

Implementation Overview
-----------------------

Required Libraries (OPAM packages)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- camlzip                — reading ZIP archives
- xml-light or ezxmlm    — lightweight XML parsing for FB2
- camomile               — Unicode support & legacy encoding conversion
- index                  — persistent on-disk index (recommended)
- or: sqlite3            — if you prefer SQL
- cmdliner or argparse   — for command-line interface (optional)
- fmt / logs             — better logging and output

Project Structure Suggestion
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

::

  home-book-library/
  ├── dune-project
  ├── dune
  ├── lib/
  │   ├── import.ml           # ZIP + FB2 extraction & parsing
  │   ├── unicode.ml          # encoding detection & conversion helpers
  │   ├── index.ml            # author → book entries storage
  │   └── organization.ml     # moving files or building index
  ├── bin/
  │   └── main.ml             # command-line tool
  ├── opam
  ├── README.rst


Example Code Snippets
~~~~~~~~~~~~~~~~~~~~~

ZIP import (very simplified)

::

   open Zip

   let import_zip path target_dir =
     let zip = open_in path in
     let entries = entries zip in
     List.iter (fun e ->
       if not e.is_directory && Filename.check_suffix e.filename ".fb2" then
         let content = input zip e in
         let out_path = Filename.concat target_dir e.filename in
         let oc = open_out_bin out_path in
         output_string oc content;
         close_out oc
     ) entries;
     close_in zip

FB2 partial parse + encoding conversion (using camomile)

::

   open CamomileLibraryDefault.Camomile
   open Xml

   let fb2_get_title_author path =
     let raw = really_input_string (open_in_bin path) (Unix.stat path).st_size in
     (* Very naive encoding guess — improve with uutf / xml header *)
     let utf8 =
       try CharEncoding.recode_string (CharEncoding.of_name "windows-1251") CharEncoding.utf8 raw
       with _ -> raw (* fallback *)
     in
     let doc = parse_string utf8 in
     let title =
       try get_pcdata (find (tag "book-title") doc)
       with Not_found -> "Untitled"
     and author =
       try
         let a = find (tag "author") doc in
         String.concat " " [
           get_pcdata_opt (find (tag "first-name") a) ~default:"";
           get_pcdata_opt (find (tag "last-name") a) ~default:""
         ] |> String.trim
       with Not_found -> "Unknown Author"
     in
     (author, title, path)

.. note::
   Real-world FB2 parsing should handle multiple authors, transliteration, empty fields, XML namespaces, etc.
   The encoding detection should be more robust (look at <?xml encoding="..."?>, meta tags, statistical detection).
