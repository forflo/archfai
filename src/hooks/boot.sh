
##
# Hook for configuring the bootloader
##
boot_hook(){
	local dev_uuid=$(lsblk --output "NAME,UUID" | grep ${BS_SP:5:4} | awk '{print $2}')
	
	[ "${dev_uuid}" = "" ] && {
		clog 1 "[boot_hook]" Could not query the UUID for ${BS_SP:5:4}
		return 1
	}
	
	clog 2 "[boot_hook]" Adding parameter to kernel command line
	env_execChroot echo "GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${dev_uuid}\"" '>>' /etc/default/grub
	
	return 0
}




