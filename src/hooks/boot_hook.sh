
##
# Hook for configuring the bootloader
##
boot_hook(){
	local partnum="1"
	local dev_uuid=$(lsblk --output "NAME,UUID" | grep ${BS_DISK:5:3}${partnum} | awk '{print $2}')
	
	[ "${dev_uuid}" = "" ] && {
		clog 1 "[boot_hook]" Could not query the UUID for ${BS_DISK:5:3}${partnum}
		return 1
	}
	
	clog 2 "[boot_hook]" Adding parameter to kernel command line
	env_execChroot echo "GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${dev_uuid}\":${CRYPT_DEV}" '>>' /etc/default/grub
	
	return 0
}
