Internals
=========
You'll usually start the installation
by doing the command $ curl <link to initstrap.sh> | bash.

initstrap.sh itself will then download the
following files in the given order
- env.conf
- bootstrap.sh
- chrootstrap.sh
- hooks/boot.sh
- hooks/crypt.sh
- hooks/fstab.sh
- hooks/initrd.sh
- hooks/lvm.sh
- hooks/net.sh

If you want to migrate this package to another
webspace you just need to change the links in
the list IS_LINKS (still in initstrap.sh)

If the downloads finished successfully, initstrap
will source the files bootstrap and chrootstrap.
(all downloaded files will have the names corresponding
to the position in IS_NAMES)
After that, the script will execute the entry
function of bootstrap and and the equivalent to that
in chrootstrap.

env.conf
========
This file can be seen as library file with
global configuration values included. These
values will be visible by all hooks, bootstrap.sh
and chrootstrap.sh

Variables mostly used inside of bootstrap.sh are
prefixed with BS_ and variables for chrootstrap.sh
have the prefix CS_

Hook specific variables are located underneath the
"Global values" comment.

bootstrap.sh
============
This file implements functions which will be called
in the order BS_ORDER specifies. They will accomplish
the following tasks for you:
* Partitioning
* Filesystem creation
* Mounting
* Mirror configuration (pacman)
* Installation of the base system
* Generation of the fstab file
* Unmounting

chrootstrap.sh
==============
Like bootstrap.sh this file implements useful functions
whose tasks are listed below
* Configuration of the system wide locale
* Configuration of the virtual console
* Time configuration
* Hostname config
* Network preconfiguration
* Initrd adjustment
* Bootloader adjustments
* Installation of programs not included by pacstrap

Every function runs commands using the function
env_execChroot (or env_execChrootH which reads commands
from stdin) which is defined in env.conf.

Hooks
=====
This bootstrap package allows you to control the
flow of the installation by the use of many
hooks. Here is a list of all hooks linked with
the functions where they'll be called.

bootstrap.sh
------------
- hooks/crypt.sh => called by bs_part()
- hooks/lvm.sh => called by bs_part()
- hooks/fstab.sh => called by bs_genFstab()

chrootstrap.sh
--------------
- hooks/boot.sh => called by cs_configBootloader()
- hooks/initrd.sh => called by cs_makeInitRd()
- hooks/net.sh => called by cs_configNetwork()

