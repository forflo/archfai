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
	"https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/boot.sh"
)

IS_NAMES=(
	"bootstrap"
	"chrootstrap"
	"crypt_hook"
	"lvm_hook"
	"fstab_hook"
	"net_hook"
	"initrd_hook"
	"boot_hook"
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
	env_loadHooks "[is_start()]"
	boot_hook
	
	clog 2 "[is_startStrappig()]" Loading ${IS_NAMES[0]}
	. ${IS_NAMES[0]}
	
	clog 2 "[is_startStrapping()]" Loading ${IS_NAMES[1]}
	. ${IS_NAMES[1]}
	
	# bs_install is the function that's been sourced by IS_NAMES[0]
	bs_install || {
		clog 1 "[bs_install()]" Script bootstrap failed!
		return 1
	}
	
	cs_install || {
		clog 1 "[cs_install]" Chrootstrap failed!
		return 1
	}
	
	flog 2 bold blink "[is_startStrapping()]" Finished bootstrapping! "You're good to go!"

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
