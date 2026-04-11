.. _index_cmd:

===============
 Index Command
===============

The ``index`` command reads all valid FB2 files and adds their details (title, authors, language, genre, etc.) into the database.

**Key features**

- Skips any files listed in the blacklist.
- Can process multiple books in parallel (controlled by the ``jobs`` setting).

**Options**

- ``--config <file>`` or ``-c <file>`` — use a specific configuration file instead of the default one.
- ``--path <path>`` — path to the source directory; defaults to the configured ``library_dir``.
- ``--dry-run`` — do not update the blacklist.
- ``--jobs <number>`` or ``-j <number>`` — number of books to process in parallel (controls concurrency).

**Examples**

#. Index all FB2 files in the configured ``library_dir``::

     bookweald index

#. Index FB2 files in a custom directory::

     bookweald index --path /some/custom/path/

#. Index without adding to the blacklist::

     bookweald index --dry-run

#. Index using 12 parallel jobs::

     bookweald index --jobs 12
