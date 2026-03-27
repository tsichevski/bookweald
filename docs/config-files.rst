==================================
Duplicate Books and Author Aliases
==================================

.. index:: duplicates, author aliases, illegal files, broken files, registry, postgresql, ocaml-postgresql

.. contents::
   :depth: 2
   :local:

Introduction
------------

This document specifies the handling of pure duplicate FB2 books, author name aliases, and a general illegal/broken file registry for the bookweald library manager.

Key Requirements
----------------

Illegal / Broken Files Registry
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- **Rule**: Files that should never be indexed (pure duplicates, broken XML, files with no title, etc.) are recorded in a single human-readable registry.
- **Rule**: The registry stores:
  - Relative file path (keeping absolute file path is no reliable: the files can be imported from any directory, including temporary directory)
  - Error type — one of a small fixed set of symbols (e.g. ``DUPLICATE``, ``BROKEN_XML``, ``NO_TITLE``, ``OTHER``)
  - Optional free-text comment (for user notes)
- **Rule**: The registry lives **only** in the human-editable text file ``illegal_files.txt``. No corresponding table exists in PostgreSQL.
- **Rule**: On every application start the tool loads ``illegal_files.txt`` into memory for fast lookups.
- **Rule**: The main PostgreSQL ``books`` table contains **only** successfully processed valid books.

Author Aliases
~~~~~~~~~~~~~~

- **Rule**: The same real author may appear under slightly different name strings in FB2 ``<author>`` blocks.
- **Rule**: Provide an alias table that maps each variant name to a single canonical author record.
- **Rule**: Canonical author data is used for grouping books and for naming author sub-directories.
- **Rule**: Books without authors are grouped under a special directory (to be decided, e.g. ``_No_Author_``).
- **Rule**: The alias mapping is maintained in a human-readable CSV file and loaded into the PostgreSQL database at startup.

Configuration
~~~~~~~~~~~~~

- **Rule**: All configuration, including PostgreSQL connection properties, is stored in a single file:
  ``~/.config/bookweald/config.json``

Configuration Directory Layout
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

::

   ~/.config/bookweald/
   ├── config.json              # All settings: PostgreSQL connection + paths
   ├── aliases.json             # canonical → [list of aliases]
   └── illegal_files.txt        # Human-editable: registry of files to ignore (loaded to memory)

Example ``aliases.json``
~~~~~~~~~~~~~~~~~~~~~~~~

::

   {
     "Иванов Иван Иванович": [
       "Иванов И. И.",
       "Иванов Иван",
       "Ivanov I.I.",
       "И.И. Иванов"
     ],
     "Петров Сергей Петрович": [
       "Петров С.",
       "Petrov S."
     ],
     "_No_Author_": []            // optional sentinel for books without author
   }

Example ``config.json``
~~~~~~~~~~~~~~~~~~~~~~~

::

   {
     "postgresql": {
       "host": "localhost",
       "port": 5432,
       "user": "ocamlbooks",
       "password": "secret",
       "dbname": "bookweald"
     },
     ...
     "no_author_dir": "_No_Author_"
   }

File Formats
~~~~~~~~~~~~

**illegal_files.txt**

Format (one entry per line, fields separated by ``|``):

::

   PATH|ERROR_TYPE|COMMENT

- ``FILENAME`` — broken file basename
- ``ERROR_TYPE`` — one of: ``DUPLICATE``, ``BROKEN_XML``, ``NO_TITLE``, ``OTHER``
- ``COMMENT`` — optional free text (``|`` inside comment escaped as ``\|``)

Lines starting with ``#`` are comments and ignored.

Example::

   # Manually decided duplicates (keep the better version)
   Book Title.fb2|DUPLICATE|keep the later version with better format
   broken.fb2|BROKEN_XML|xml parsing failed at line 42
   NoTitle.fb2|NO_TITLE

**aliases.csv**

Comma-separated values. First column = canonical name, seconf column = alias as it appears in FB2

Example::

   # canonical name, alias
   Иванов Иван Иванович, Иванов И. И.
   Иванов Иван Иванович, "Иванов Иван"
   Иванов Иван Иванович, Ivanov I.I.

Database Schema (PostgreSQL)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

::

   CREATE TABLE IF NOT EXISTS author_aliases (
       alias TEXT PRIMARY KEY,
       canonical TEXT NOT NULL
   );

Implementation Notes
--------------------

- Module ``lib/config.ml``:
  - Reads ``~/.config/bookweald/config.json`` using ``Yojson``.
  - Loads ``illegal_files.txt`` into an in-memory ``Hashtbl.t`` (path → (error_type, comment option)).
  - Loads ``aliases.csv`` and upserts into PostgreSQL ``authors`` and ``author_aliases`` tables.
  - Opens PostgreSQL connection using ``Postgresql`` module directly.
- During import / indexing (in ``lib/import.ml`` or main pipeline):
  - For each FB2 file:
    - If path is in the in-memory illegal registry → silently skip.
    - Otherwise parse (with legacy Russian charset conversion).
    - If title missing → add to illegal registry with ``NO_TITLE``.
