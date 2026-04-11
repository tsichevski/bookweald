.. _schema_init_cmd:

================================
DB Schema Initialization Command
================================

The ``schema-init`` command creates or re-creates the PostgreSQL database tables
required to store book, author, and relationship data.

**Key features**

- Creates the necessary tables for books, authors, and the many-to-many links between them.
- Adds appropriate indexes and constraints.
- Uses the admin credentials defined in your configuration file.

**Options**

- ``--config <file>`` or ``-c <file>`` — use a specific configuration file instead of the default one.
- ``--force`` or ``-f`` — drop any existing schema before creating a new one.

**Examples**

#. Create a fresh database schema (fails if any tables already exist)::

     bookweald schema-init

#. Re-create the database schema, dropping any existing tables first::

     bookweald schema-init --force