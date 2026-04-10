===========================
Download, Build and Install
===========================

.. index:: build, install, dune, opam

.. contents::
   :depth: 1
   :local:

Prerequisites
-------------

- OCaml compiler (>= 5.3.0)
- opam (OCaml package manager)
- Dune build system

Installation
------------

1. Clone the repository::

      git clone https://github.com/tsichevski/bookweald.git
      cd bookweald

2. Install dependencies::

      opam install . --deps-only

   This ensures the following dependencies are resolved:

   - zipc
   - cmdliner (>= 1.2.0)
   - miou (>= 0.5.4)
   - postgresql
   - xmlm
   - yojson
   - ppx_deriving_yojson
   - uucp
   - uutf
   - logs
   - fmt

3. Build the project::

     dune build

4. Install the binaries and library::

     dune install

5. Run tests to verify the build::

     dune runtest

This executes the test suite using Alcotest.

Executable Location
~~~~~~~~~~~~~~~~~~~

After installation the main binary is available as ``bookweald`` in your PATH.

Documentation
-------------

Full documentation is available in the ``docs/`` directory and can be built with Sphinx if needed.
