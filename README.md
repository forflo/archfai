archfai
=======

Archfai stands for Archlinux fully automatic installation. This little project
aims to provide a shell script package specific for archlinux which makes it
possible to automate the complete installation process with just one command.

Usage
=====
1) Upload the files in src to a webspace of your choice
2) Change the links in initstrap.sh appropriately
3) Adjust the settings in env.conf according to your taste
	but be aware of what you change.
4) Shorten the link of your new initstrap.sh location
5) Start the Archlinux live cd and establish a working internet connection
6) Execute the command:
	$ curl -L <shortened_link> | bash

That's all.
You should have a working base installation of Archlinux in about
3 minutes or less (if your internet connection is fast enough).

Bugs
====
Please report a bug as soon as you find one!


