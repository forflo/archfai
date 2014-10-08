#!/bin/bash

. env.conf

##
# Traverses the PART_CMD array and runs
# every command that's inside of it
##
bs_part(){
	for ((i=0; i<${#BS_PARTCMDS[*]}; i++)); do
		clog 2 "[bs_part()]" Running partition command ${BS_PARTCMDS[i]:0:20} "..."
		${BS_PARTCMDS[i]} || {
			clog 1 "[bs_part()]" error in command":"
			clog 1 "[bs_part()]    " ${BS_PARTCMDS[i]}
			return 1
		}
	done
	
	for i in crypt_hook lvm_hook; do
		clog 2 "[bs_part()]" running hook function":" $i
		${i} || {
			clog 1 "[bs_part()]" hook $i failed
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
		clog 2 "[bs_mkfs()]" Running filesystem command":" 
		clog 2 "[bs_mkfs()]    " ${BS_FILESYS[i]} "..."
		${BS_FILESYS[i]} || {
			clog 1 "[bs_mkfs()]" error in command":"
			clog 1 "[bs_mkfs()]    " ${BS_FILESYS[i]}
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
		clog 2 "[bs_mount()]" Running mount command":" 
		clog 2 "[bs_mount()]    " ${BS_MOUNT[i]} "..."
		${BS_MOUNT[i]} || {
			clog 1 "[bs_mount]" error in command
			clog 1 "[bs_mount]    " "${BS_MOUNT[i]}"
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
	clog 2 "[bs_selMirror()]" Download mirrorlist from archlinux web server
	curl -o /etc/pacman.d/mirrorlist "$BS_MIRRORLINK" > /dev/null 2>&1 || { 
		clog 1 "[bs_selMirror()]" Download failed!
		return 1
	}
	mv /etc/pacman.d/mirrorlist /etc/pacman.d/old || return 1
	cut -c 2- /etc/pacman.d/old > /etc/pacman.d/mirrorlist 
	rm /etc/pacman.d/old
	return 0
}

##
# Installs the base system
##
bs_instBaseSys(){
	echo -e "\n\nY\n" | pacstrap -i /mnt base base-devel || { 
		curl 1 "[bs_instBaseSys()]" Could not finish pacstrapping!
		return 1
	}
	
	return 0
}

##
# Generates an initial fstab
##
bs_genFstab(){
	clog 2 "[bs_genFstab()]" generating fstab...
	genfstab -U -p /mnt >> /mnt/etc/fstab || {
		clog 1 "[bs_instBaseSys()]" Generation of the fstab file failed!
		return 1
	}
	
	clog 2 "[bs_genFstab]" Running hook: fstab_hook.
	fstab_hook || {
		clog 1 "[bs_genFstab]" Hook fstab_hook failed!
		return 1
	}
	
	return 0
}

##
# Echoes some messages
##
bs_finish(){
	echo finished installing your base system.
	echo now chrootstrapping starts
	
	return 0
}

##
# Unmounts the disks still mounted
##
bs_cleanup(){
	clog 2 "[bs_cleanup()]" Starting cleanup.
	umount ${BS_DISK}1 ${BS_DISK}2 || {
		clog 1 "[bs_cleanup()]" Cleanup failed!
		return 1
	}
	
	return 0
}

##
# Traverses the CS_ORDER array which contains
# the names of the functions that should be run.
# You can, of course, modify this list to fit this
# program to your needs
##
bs_install(){
	# insert hooks
	env_loadHooks "bs_install"


	for i in $BS_ORDER; do
		clog 2 "[bs_install()]" Running function $i.
		${i} || {
			clog 1 "[bs_install()]" Function $i failed!
			return 1
		}
	done
	return 0
}

bs_install || {
	clog 1 "[bs_install()]" Script bootstrap failed!
	bs_cleanup
	exit 1
}
exit 0