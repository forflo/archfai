##
# Contains operations that can only be
# executed using arch-chroot
##

##
# Configures the system wide locale settings
##
cs_configLocale(){
	clog 2 "[cs_configLocale()]" Uncommenting specified lines in ${CS_LOCFILE}.
	
	env_execChrootH << EOF
	sed --in-place -e "s/^#${CS_LOCPRE}\\\\(.*\\\\)/${CS_LOCPRE}\\\\1/g" ${CS_LOCFILE} || {
		clog 1 "[cs_configLocale()]" Uncommenting failed!
		return 1
	}
	sed --in-place -e "s/^#${CS_SYSLOC}\\\\(.*\\\\)/${CS_SYSLOC}\\\\1/g" ${CS_LOCFILE} || {
		clog 1 "[cs_configLocale()]" Uncommenting failed!
		return 1
	}
EOF
	
	clog 2 "[cs_configLocale()]" Generating locales.
	env_execChroot locale-gen || {
		clog 1 "[cs_configLocale()]" Generation failed!
		return 1
	}
	env_execChroot echo LANG=${CS_SYSLOC} '>' ${CS_LOCCONF}
	env_execChroot export LANG=${CS_SYSLOC}
	
	return 0
}

##
# Remove magic values
##
cs_configConsoleFont(){
	clog 2 "[cs_configConsoleFont()]" Configuring console font.
	env_execChroot echo "KEYMAP=de-latin1" '>>' /etc/vconsole.conf
	env_execChroot echo "FONT=lat9w-16" '>>' /etc/vconsole.conf
	
	return 0
}

##
# Configures the time zone and sets the hardware clock
##
cs_configTime(){
	clog 2 "[cs_configTime()]" Configuring time.

	env_execChroot ln -s /usr/share/zoneinfo/${CS_TIMEZONE} /etc/localtime || {
		clog 1 "[cs_configTime()]" Setting time zone failed!
		return 1
	}
	
	env_execChroot hwclock --systohc --utc || {
		clog 1 "[cs_configTime()]" Setting hardware clock failed!
		return 1
	}
	
	return 0
}

##
# Overrides the /etc/hosts file
##
cs_setHost(){
	clog 2 "[cs_setHost()]" Setting hostname.

	env_execChroot echo ${CS_HOSTNAME} '>' /etc/hostname
	env_execChroot echo 127.0.0.1	localhost.localdomain	localhost ${CS_HOSTNAME} '>' /etc/hosts
	env_execChroot echo ::1		localhost.localdomain	localhost '>>' /etc/hosts

	return 0
}

##
# Provides network specific configuratioin
##
cs_configNetwork(){
	clog 2 "[cs_configNetwork()]" Setting network configuration.

	if [ ${CS_WIRED} -eq 0 ]; then
		env_execChroot systemctl enable dhcpcd@${CS_WDEV}.service || return 1
	else
		env_execChroot systemctl enable dhcpcd@${CS_EDEV}.service || return 1
	fi
	
	clog 2 "[cs_configNetwork]" Running net_hook.
	net_hook || {
		clog 1 "[cs_configNetwork]" net_hook failed!
		return 1
	}
	
	return 0
}

##
# TODO: provide init rd configuration hook
##
cs_makeInitRd(){
	clog 2 "[cs_makeInitRd()]" Recreate init ramdisk environment.
	initrd_hook || {
		clog 1 "[cs_makeInitRd]" initrd_hook failed!
		return 1
	}
	
	clog 2 "[cs_makeInitRd]" Running initrd_hook.
	env_execChroot mkinitcpio -p linux || {
		clog 1 "[cs_makeInitRd()]" Recreation failed!
		return 1
	}
	
	return 0
}

##
# Configures the grub bootloader
##
cs_configBootloader(){
	clog 2 "[cs_configBootloader()]" Install and configure bootloader.

	env_execChroot pacman -S grub || {
		clog 1 "[cs_configBootloader()]" Package installation failed!
		return 1
	}
	env_execChroot grub-install --target=i386-pc --recheck ${BS_DISK} || {
		clog 1 "[cs_configBootloader()]" Bootloader installation failed!
		return 1
	}
	
	clog 2 "[cs_configBootloader()]" Running bootloader configuration hook
	boot_hook || {
		clog 1 "[cs_configBootloader()]" boot_hook failed!
		return 1
	}
	
	env_execChroot grub-mkconfig -o /boot/grub/grub.cfg || {
		clog 1 "[cs_configBootloader()]" Bootloader configuration failed!
		return 1
	}
	
	return 0
}

##
# Traverses the CS_PROGS and installs
# every program that's listed there
##
cs_installProgs(){
	clog 2 "[cs_installProgs()]" Install useful packages!

	for i in ${CS_PROGS[*]}; do
		clog 2 "[cs_installProgs()]" Install package ${i}

		env_execChroot pacman -S --noconfirm $i || {
			clog 1 cs_install could not install package $i
			return 1
		}
	done
	
	return 0
}

cs_install(){
	for i in $CS_ORDER; do
		clog 2 "[cs_install()]" Running function $i.
		${i} || {
			clog 1 "[cs_install()]" Function $i failed!
			return 1
		}
	done
	
	return 0
}