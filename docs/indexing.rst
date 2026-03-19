============
 Book index
============

Book validation
---------------

All books in the repository must match these conditions:

#. Have valid XML format with one of the following encodings:

   #. ``utf8``
   #. ``windows-1251``
   #. ``koi8-r``

#. Have title at the ``FictionBook/description/title-info/book-title`` path
#. Have at least one author at the ``FictionBook/description/title-info/author`` or  ``FictionBook/description/document-info/author`` paths
#. Have unique ID string at the ``FictionBook/description/document-info/id`` path

All autors in the repository must match these conditions:

#. Have at least one of ``last_name`` or ``first_name`` defined.
