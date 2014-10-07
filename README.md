archfai
=======

Archfai stands for Archlinux fully automatic installation. This little project
aims to provide a shell script package specific for archlinux which makes it
possible to automate the complete installation process with just one command.
"One command" means just **one command**!! No mounting of additional removable
media and no curl orgies needed, just one command.

Usage
=====
* Upload the files in src to a webspace of your choice
* Change the links in initstrap.sh appropriately
* Adjust the settings in env.conf according to your taste,
	but be aware of what you're changing.
* Shorten the link of your new initstrap.sh location
* Start the Archlinux live cd and establish a working internet connection
* Execute the command:
	$ curl -L bit.ly/yourlink | bash

That's all.
You should have a working base installation of Archlinux in about
3 minutes or less (if your internet connection is fast enough).

Hooks
=====
The script can be extended by the use of hooks. Please consult the
(hopefully) very well documented source code. If you think some
portions of the code are poorly commented, please leave me a message
and i **will** fix that as soon as I can find the time!

Important Notes
===============
A working knowledge of how to write shellscripts and a extended
knowledge about installing and configuring an archlinux system from scratch
is strongly recommended.

This project represents **no zeroconf installer script**
where you just need to change two or three values and
everything works correctly. It just provides the framework for you
to add configuration specific commands that will be run in the correct
order. Of course there are still flat configuration variables you just
need to adjust to reach your goal (e.g. The time zone variable).

Bugs
====
Please report a bug as soon as you find one!


