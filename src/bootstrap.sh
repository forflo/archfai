#!/bin/bash

. env.conf

##
# Traverses the PART_CMD array and runs
# every command that's inside of it
##
bs_part(){
	for ((i=0; i<${#BS_PARTCMDS[*]}; i++)); do
		${BS_PARTCMDS[i]} || {
			echo error in command
			echo ${BS_PARTCMDS[i]}
			return 1
		}
	done
	
	for i in $CS_HOOKS; do
		echo running hook function $i
		${i} || {
			echo hook $i failed
			return 1
		}
	done
	return 0
}

##
# Traverses the BS_FILESYS array and runs every
# command that's inside of it
##
bs_mkfs(){
	for ((i=0; i<${#BS_FILESYS[*]}; i++)); do
		${BS_FILESYS[i]} || {
			echo error in command
			echo ${BS_FILESYS[i]}
			return 1
		}
	done
	return 0
}

##
# Traverses the commands in the BS_MOUNT array
##
bs_mount(){
	for ((i=0; i<${#BS_MOUNT[*]}; i++)); do
		${BS_MOUNT[i]} || {
			echo error in command
			echo "${BS_MOUNT[i]}"
			return 1
		}
	done
	return 0
}

##
# Configures the pacman package manager by downloading
# the most current mirror list from the archlinux web server
##
bs_selMirror(){
	curl -o /etc/pacman.d/mirrorlist "$BS_MIRRORLINK" || return 1
	mv /etc/pacman.d/mirrorlist /etc/pacman.d/old
	cut -c 2- /etc/pacman.d/old > /etc/pacman.d/mirrorlist
	rm /etc/pacman.d/old
	return 0
}

##
# Installs the base system
##
bs_instBaseSys(){
	echo -e "\n\nY\n" | pacstrap -i /mnt base base-devel || return 1
	return 0
}

##
# Generates an initial fstab
##
bs_genFstab(){
	echo generating fstab...
	genfstab -U -p /mnt >> /mnt/etc/fstab || return 1
}

##
# Echoes some messages
##
bs_finish(){
	echo finished installing your base system.
	echo now chrootstrapping starts
}

##
# Unmounts the disks still mounted
##
bs_cleanup(){
	umount ${BS_DISK}1 ${BS_DISK}2
}

##
# Traverses the CS_ORDER array which contains
# the names of the functions that should be run.
# You can, of course, modify this list to fit this
# program to your needs
##
install(){
	# insert hooks
	for i in $CS_HOOKS; do
		[ -f $i ] && {
			echo loading hook $i
			. ${i}
		} || {
			echo could not find the hook
			return 1
		}
	done

	for i in $CS_ORDER; do
		echo Running function $i
		${i} || {
			echo function $i failed
			return 1
		}
	done
	return 0
}

install || {
	echo Installation script failed!
	bs_cleanup
	exit 1
}
exit 0