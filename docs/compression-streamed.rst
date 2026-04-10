=========================================================
Streaming Support for Compression Libraries (Future Plan)
=========================================================

.. index:: streaming, gzip, bzip2, camlzip, decompress, bz2, zipc

.. contents::
   :depth: 2
   :local:

Introduction
------------

This report evaluates which OCaml packages support **streaming decompression** for ``.gz`` and ``.bz2`` files. Streaming means processing data chunk-by-chunk without loading the entire compressed file into memory.

Streaming Support Overview
--------------------------

- **camlzip** (``Gzip`` module for ``.gz`` files)
  
  - **Yes**, it supports true streaming decompression.
  - ``Gzip.open_in`` (or ``Gzip.open_in_chan``) returns an abstract input channel.
  - Read incrementally with ``Gzip.input``, ``Gzip.really_input``, or line-by-line functions.
  - Memory usage remains low and controlled by buffer size.
  - Suitable for large files, pipes, or network streams.

- **decompress** (``decompress.gz`` sub-package for ``.gz``)
  
  - **Yes**, and it is explicitly designed for streaming.
  - Provides a **non-blocking streaming codec** (``Gz.Inf``, ``Gz.Def``, etc.).
  - Feed input chunks and receive output chunks.
  - Ideal for network streams, custom I/O, or very low-memory environments.
  - Pure OCaml implementation.

- **bz2** (CamlBZ2 for ``.bz2`` files)
  
  - **Yes**, it supports streaming decompression.
  - ``Bz2.open_in`` (or ``Bz2.open_in_chan``) returns a decompressing input channel.
  - Use standard channel functions (``input``, ``input_line``, ``really_input``, etc.).
  - Behaves like a normal ``in_channel`` while decompressing on the fly.

- **zipc**
  
  - **No** for standalone ``.gz`` or ``.bz2`` files (it does not support these formats).
  - For ZIP archives it is primarily **in-memory** (loads archive structure and entries).
  - Can handle deflate streams internally, but not oriented toward pure streaming of large archives.

.. note::
   For the most flexible low-level streaming, prefer the ``decompress`` library.
