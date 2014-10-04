#!/bin/bash

. env.conf

cs_configLocale(){
	sed --in-place -e "s/^#${CS_LOCPRE}\\(.*\\)/${CS_LOCPRE}\\1/g" ${CS_LOCFILE} || return 1
	sed --in-place -e "s/^#${CS_SYSLOC}\\(.*\\)/${CS_SYSLOC}\\1/g" ${CS_LOCFILE} || return 1
	locale-gen || return 1
	echo LANG=${CS_SYSLOC} > ${CS_LOCCONF}
	export LANG=${CS_SYSLOC}
	return 0
}

cs_configConsoleFont(){
	echo "KEYMAP=de-latin1" >> /etc/vconsole.conf
	echo "FONT=lat9w-16" >> /etc/vconsole.conf
	return 0
}

cs_configTime(){
	ln -s /usr/share/zoneinfo/${CS_TIMEZONE} /etc/localtime || return 1
	hwclock --systohc --utc || return 1
	return 0
}

cs_setHost(){
	echo ${CS_HOSTNAME} > /etc/hostname
	cat > /etc/hosts << EOF
#
# /etc/hosts: static lookup table for host names
#

#<ip-address>	<hostname.domain.org>	<hostname>
127.0.0.1	localhost.localdomain	localhost ${CS_HOSTNAME}
::1		localhost.localdomain	localhost

# End of file
EOF
}

cs_configNetwork(){
	if [ ${CS_WIRED} -eq 0 ]; then
		systemctl enable dhcpcd@${CS_WDEV}.service || return 1
	else
		systemctl enable dhcpcd@${CS_EDEV}.service || return 1
	fi
	return 0
}

cs_makeInitRd(){
	mkinitcpio -p linux || return 1
	return 0
}

cs_configBootloader(){
	pacman -S grub || return 1
	grub-install --target=i386-pc --recheck /dev/sda || return 1
	grub-mkconfig -o /boot/grub/grub.cfg || return 1
	return 0
}

cs_installProgs(){
	for i in ${CS_PROGS[*]}; do
		pacman -S $i || {
			echo could not install package $i
			return 1
		}
	done
	return 0
}

cs_install(){
	cs_configLocale || {
		echo Could not configurate the locale
		return 1
	}
	cs_configConsoleFont || {
		echo Could not change the console font
		return 1
	}
	cs_configTime || {
		echo Could not configure the time
		return 1
	}
	cs_setHost || {
		echo Could not set Hostname
		return 1
	}
	cs_configNetwork || {
		echo Could not configure the network
		return 1
	}
	cs_makeInitRd || {
		echo Could not recreate the initial ramdisk
		return 1
	}
	cs_configBootloader || {
		echo Could neither install nor configure the bootloader
		return 1
	}
	cs_installProgs || {
		echo Could not install required progs
		return 1
	}
}

cs_install || {
	echo Chbootstrap failed
	exit 1
}

passwd
exit 0
