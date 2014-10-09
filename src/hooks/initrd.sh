
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
	local conf="/etc/mkinitcpio.conf.n"
	
	clog 2 "[initrd_hook()]" Generating temporary mkinitcpio.conf
	env_execChroot echo MODULES=\"\" '>>' ${conf}
	env_execChroot echo BINARIES=\"\" '>>' ${conf}
	env_execChroot echo FILES=\"\" '>>' ${conf}
	env_execChroot echo HOOKS=\"\"base udev autodetect modconf block encrypt filesystems keyboard fsck\"\" '>>' ${conf}
	
	env_execChroot mkinitcpio --config ${conf} -p linux || {
		clog 1 "[initrd_hook()]" Configuration of hooks failed
		
	}
}
