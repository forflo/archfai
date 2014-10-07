#!/bin/bash

. env.conf

bs_part(){
	for ((i=0; i<${#BS_PARTCMDS[*]}; i++}; do
		${BS_PARTCMDS[i]} || {
			echo error in command
			echo ${BS_PARTCMDS[i]}
			return 1
		}
	done
	
	for i in $CS_HOOKS; do
		echo running hook $i
		
	done
	return 0
}

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

bs_selMirror(){
	curl -o /etc/pacman.d/mirrorlist "$BS_MIRRORLINK" || return 1
	mv /etc/pacman.d/mirrorlist /etc/pacman.d/old
	cut -c 2- /etc/pacman.d/old > /etc/pacman.d/mirrorlist
	rm /etc/pacman.d/old
	return 0
}

bs_instBaseSys(){
	echo -e "\n\nY\n" | pacstrap -i /mnt base base-devel || return 1
	return 0
}

bs_genFstab(){
	echo generating fstab...
	genfstab -U -p /mnt >> /mnt/etc/fstab || return 1
}

bs_finish(){
	echo finished installing your base system.
	echo now chrootstrapping starts
}

bs_cleanup(){
	umount ${BS_DISK}1 ${BS_DISK}2
}

install(){
	# insert hooks
	for i in $CS_HOOKS; do
		[ -f lvm ] && {
			echo loading hook $i
			. ${i}.sh
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