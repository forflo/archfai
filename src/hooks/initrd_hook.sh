
##
# init rd configuration hook which can
# be used to manipulate the input of
# mkinitcpio.
# Please note that you have to use either
# env_execChroot or env_execChrootH (both
# defined in env.conf) to modify the configuration
# in the already bootstrapped environment!
##
initrd_hook(){
	local conf="/etc/mkinitcpio.conf"
	
	clog 2 "[initrd_hook()]" Generating temporary mkinitcpio.conf
	env_execChrootH << EOF
		echo MODULES=\"\" > ${conf}
		echo BINARIES=\"\" >> ${conf}
		echo FILES=\"\" >> ${conf}
		echo HOOKS=\"base udev autodetect modconf block encrypt filesystems keyboard fsck\" >> ${conf}
EOF

	env_execChroot mkinitcpio --config ${conf} -p linux || {
		clog 1 "[initrd_hook()]" Configuration of hooks failed
		return 1
	}
	
	return 0
}
