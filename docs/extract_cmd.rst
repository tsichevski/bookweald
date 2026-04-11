================
Extract Command
================

.. index:: extract command, bookweald extract

The ``extract`` command extracts FB2 books from a ZIP archive into your incoming library folder (``library_dir``).

**Key features**

- Supports both regular ZIP files and very large archives (larger than 4.5 GB).
- For archives larger than 4.5 GB, it automatically switches to the external ``7z`` tool (which must be installed on your system) and displays a notice.
- Automatically creates any required folders.

**Options**

- ``--config <file>`` or ``-c <file>`` — use a specific configuration file instead of the default.
- ``--dry-run`` — simulate the extraction and show what would be done without making any actual changes (especially useful before running ``group``).
- ``--force`` or ``-f`` — overwrite existing files if they already exist.

**Examples**

1. Extract books from an archive::

      bookweald extract my_books.zip

2. Extract books and overwrite any existing files::

      bookweald extract my_books.zip --force

3. Simulate extraction without writing any files (dry run)::

      bookweald extract my_books.zip --dry-run