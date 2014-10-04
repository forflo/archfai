#!/bin/bash

. env.conf

bs_format(){
	fdisk $BS_DISK <<EOF || return 1
o
n
p
1

+230G
n
p
2


w
EOF

	return 0
}

bs_mkfs(){
	mkfs.ext4 ${BS_DISK}1 || return 1
	mkfs.ext4 ${BS_DISK}2 || return 1
	return 0
}

bs_mount(){
	mount ${BS_DISK}1 /mnt || return 1

	mkdir /mnt/boot || return 1
	mount ${BS_DISK}2 /mnt/boot || return 1
	return 0
}

bs_selMirror(){
	echo $BS_MIRROR > /etc/pacman.d/mirrorlist
	return 0
}

bs_selMirrorDyn(){
	curl -o /etc/pacman.d/mirrorlist 'https://www.archlinux.org/mirrorlist/?country=DE&protocol=http&ip_version=4' || return 1
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
	echo now execute
	echo "$ arch-chroot /mnt /bin/bash"
	echo and run the second installer script
}

bs_cleanup(){
	umount ${BS_DISK}1 ${BS_DISK}2
}

install(){
	bs_format || {
		echo could not format the disks
		return 1
	}
	bs_mkfs || {
		echo could not create filesystems
		return 1
	}
	bs_mount || {
		echo could not mount the filesystems
		return 1
	}
	if [ $BS_MIRRORDYN -eq 1 ]; then
		echo select mirror dynamically
		bs_selMirrorDyn || {
			echo could not create the mirrorlist dynamically
			return 1
		}
	else
		echo select mirror statically
		bs_selMirror || {
			echo could not create the mirrorlist
			return 1
		}
	fi
	bs_instBaseSys || {
		echo could not install the base system using pacman
		return 1
	}
	bs_genFstab || {
		echo could not generate the fstab file
		return 1
	}
	bs_finish
	return 0
}

install || {
	echo Installation script failed!
	bs_cleanup
	exit 1
}

exit 0
