#!/bin/bash
##
# Author: Florian Mayer
# Date: 08.10.2014
# Downloads the file list (IS_LINKS) naming them
# as specified in IS_NAMES. Then starts the 
# scripts bootstrap and chrootstrap (in this order).
##

IS_LINKS=(
	"https://raw.githubusercontent.com/forflo/archfai/master/src/bootstrap.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/chrootstrap.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/crypt.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/lvm.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/fstab.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/net.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/initrd.sh"
)

IS_NAMES=(
	"bootstrap"
	"chrootstrap"
	"crypt_hook"
	"lvm_hook"
	"fstab_hook"
	"net_hook"
	"initrd"
)

ENV="https://raw.githubusercontent.com/forflo/archfai/master/src/env.conf"

##
# Load environment
##
is_loadEnv(){
	echo Downloading env file $ENV
	curl -o env.conf -L $ENV > /dev/null 2>&1 || {
		echo Download failed!
		return 1
	}
	
	chmod 750 env.conf || {
		echo Chmod failed1
		return 1
	}
	
	echo Load env.conf...
	. env.conf
	
	clog 2 "[is_loadEnv()]" Loading finished successfully.
	
	return 0
}

##
# Downloads the needed scripts
##
is_download(){
	for ((i=0; i<${#IS_LINKS[*]}; i++)); do
		clog 2 "[is_download()]" Downloading ${IS_LINKS[$i]:0:20} ...
		curl -o ${IS_NAMES[i]} -L ${IS_LINKS[$i]} > /dev/null 2>&1 || {
			clog 1 "[is_download()]" Download of file ${IS_NAMES[i]} failed!
			return 1
		}
		
		chmod 750 ${IS_NAMES[i]} || {
			clog 1 "[is_download()]" Chmod failed!
			return 1
		}
	done
	
	clog 2 "[is_download()]" Finished all downloads successfully.

	return 0
}

##
# Runs the bootstrapping files
##
is_startStrapping(){
	clog 2 "[is_startStrappig()]" Starting ${IS_NAMES[0]}

	bash -- ${IS_NAMES[0]} || {
		clog 1 "[is_startStrapping()]" Initial Bootstrapping failed!
		return 1
	}

	# copy env to chroot-environment
	cp env.conf /mnt/ || {
		clog 1 "[is_startStrapping()]" Could not copy env.conf to /mnt
		return 1
	}
	for i in $HOOKS; do
		[ -f $i ] && {
			clog 2 "[is_startStrapping()]" Copying hook $i.
			cp $i /mnt/ || {
				clog 1 "[is_startStrapping()]" Copying failed!
				return 1
			}
		} || {
			clog 1 "[is_startStrapping()]" Invalid file name of hook: $i!
			return 1
		}
	done
	
	clog 2 "[is_startStrapping()]" Starting ${IS_NAMES[1]}
	cat ${IS_NAMES[1]} | arch-chroot /mnt/ /bin/bash || {
		clog 1 "[is_startStrapping()]" Arch-chroot strapping failed!
		return 1
	}
	
	clog 2 "[is_startStrapping()]" Finished bootstrapping! "You're good to go!"

	return 0
}

##
# Deletes each downloaded file
##
is_clean(){
	for ((i=0; i<${#IS_NAMES[*]}; i++)); do
		rm ${IS_NAMES[i]} > /dev/null 2>&1 || {
			clog 1 "[is_clean()]" Deletion of ${IS_NAMES[i]} failed!
			return 1 
		}
	done
	
	rm env.conf > /dev/null 2>&1 || {
		clog 1 "[is_clean()]" Deletion of env.conf failed!
		return 1
	}
	return 0
}

##
# Starting point
##
is_start(){
	is_loadEnv || {
		clog 1 "[is_start()]" Could not download environment file.
		exit 1
	}
	is_download || {
		clog 1 "[is_start()]" Could not download bootstrapping files.
		exit 1
	}
	is_startStrapping || {
		clog 1  "[is_start()]" Could not start bootstrapping.
		is_clean || {
			clog 1 "[is_start()]" Could not clean environment.
			exit 1
		}
		exit 1
	}
	is_clean || {
		clog 1 "[is_start()]" Could not clean environment.
		exit 1
	}
	exit 0
}

is_start