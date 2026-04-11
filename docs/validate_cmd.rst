.. _validate_cmd:

==================
 Validate Command
==================

The ``validate`` command checks all FB2 files in your incoming library folder for basic correctness.

**Key features**

- Scans recursively for ``*.fb2`` and ``*.fb2.zip`` files.
- Performs a quick check that each file is well-formed XML.
- Automatically adds any invalid or broken files to the blacklist so they are ignored in future runs.
- This is a fast sanity check only — it does not perform deep validation of the book content.

**Options**

- ``--config <file>`` or ``-c <file>`` — use a specific configuration file instead of the default.
- ``--dry-run`` — simulate the validation and show what would be done without making any actual changes or updating the blacklist.
- ``--jobs <number>`` or ``-j <number>`` — number of books to process in parallel (controls concurrency).
- ``--path <path>`` — path to the source directory; defaults to the configured ``library_dir``.
- ``--reverse`` or ``-r`` — validate only the files that are currently blacklisted. This is useful after you have manually fixed broken files. Note that files which pass validation are **not** automatically removed from the blacklist — you must edit the blacklist file manually if desired.

**Examples**

1. Validate all FB2 files in the configured ``library_dir``::

      bookweald validate

2. Validate FB2 files in a custom directory::

      bookweald validate --path /some/custom/path/

3. Simulate validation without updating the blacklist (dry run)::

      bookweald validate --dry-run

4. Validate using 12 parallel jobs::

      bookweald validate --jobs 12

5. Re-validate only the currently blacklisted files::

      bookweald validate --reverse