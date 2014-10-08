
##
# Since these scripts are meant to be sourced
# by the script bootstrap.sh, you can, of course,
# use the library functions prodived inside of env.conf
# in this function.
##
crypt_hook(){
	local crypt_device="cryptroot"
	
	clog 2 "[crypt_hook()]" Doing cryptsetup with LUKS.
	clog 2 "[crypt_hook()]" Please provide your password.
	clog 2 "[crypt_hook()]" The current keyboard layout will be set to $load_keys

	
	# requires the user to break the unattendedness of this script package
	cryptsetup --verbose --key-size=512\
		--hash=sha512 --cipher=serpent-xts-plain64\
		--key-file - --use-urandom luksFormat ${BS_SP} || {

		clog 1 "[crypt_hook()]" Cryptsetup failed!
		return 1		
	}
	
	cryptsetup open ${BS_SP} ${crypt_device} || {
		clog 1 "[crypt_hook()]" Opening and creation of mapping device failed!
		return 1
	}
	
	# Sets the system partition to the new layer that
	# sits on top of the old BS_SP
	BS_SP="/dev/mapper/${crypt_device}"
	
	return 0
}
