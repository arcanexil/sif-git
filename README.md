# imprimer.sh - User Friendly's menu to print in UPSUD's SIF

CONTENTS OF THIS FILE
---------------------

 * Introduction
 * Requirements
 * Recommended modules
 * Installation
 * Configuration
 * Troubleshooting
 * FAQ
 * Maintainers

INTRODUCTION
------------

The script is created to be an user's friendly interface to print a document on
printers at Orsay's University (SIF Dpt.). It provides procedures to help
students who are afraid of The Terminal. The interaction with system pass trough
a newt interface (ncurses' like).

REQUIREMENTS
------------

This module requires the following packages :

 * whiptail - newt interface (http://linux.die.net/man/1/whiptail)
 * lp - send files to printer or similar system (http://linux.die.net/man/1/lp)

  - we have our internal system

 * pdftops - convert pdf files (http://linux.die.net/man/1/pdftops)

INSTALLATION
------------

The script could be put everywhere. It is expected to be launched when the user
sign in the printer's computer.

CONFIGURATION
-------------

 * Default action, the script is looking for pdf or ps files in the HOME folder.
 * If you prefer any other folder, just put the one after Procedure() or
 Convert() (look for $1)

TROUBLESHOOTING
---------------

 * If the menu does not display, check the following:

   - Are the permissions enabled for the appropriate roles? (chmod +x)

   - Does whiptail is installed ?

<!-- FAQ
---

Q:  Is this normal?

A: Yes, this is the intended behavior. -->

MAINTAINERS
-----------

Current maintainers:
 * Lucas Ranc (arcanexil)
 * (Moon)

<!-- This project has been sponsored by:
 * someone -->
