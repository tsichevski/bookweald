=================================
Home Book Library Management Tool
=================================

Introduction
------------

Bookweald is a command-line tool and OCaml library for managing, indexing, and processing FictionBook (FB2) digital libraries.

It provides fast parsing, normalization, recoding, searching, and database-backed organization of FB2 files, with support for compression, character encoding conversion, and metadata handling.

The primary location is https://github.com/tsichevski/bookweald.git

Key Features
------------

- FB2 2.1 parsing and validation support
- Character encoding support (UTF-8, CP1251, KOI8-R, etc.)
- Streaming decompression for zipped archives
- Efficient indexing
- Blacklist and author alias management

.. toctree::
   :maxdepth: 1

   install   
   quickstart
   configuration
   author-aliases
   blacklisting
   reference
   programming

Indices and tables
------------------

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
