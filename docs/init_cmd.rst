============
Init Command
============

.. index:: init command, bookweald init, configuration

The ``init`` command creates a default configuration file for you.

- Places the file in ``~/.config/bookweald/config.json``.
- You can edit this file later to set your library folders and other preferences.
- Use the ``--force`` option to overwrite an existing config file.

**Options**

- ``--force`` or ``-f`` — overwrite existing configuration file.
- ``--config <file>`` or ``-c <file>`` — use a specific configuration file.

**Examples**

#. Create ``~/.config/bookweald/config.json`` file, do not overwrite if exists::

    bookweald init

#. Create ``~/.config/bookweald/config.json`` file, silently **overwrite** if exists::

    bookweald init --force
    
#. Create custom ``/path/to/myconfig.json`` config file::

    bookweald init --config /path/to/myconfig.json
    