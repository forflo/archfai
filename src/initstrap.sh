#!/bin/bash
#
# Author: Florian Mayer
# Date: 08.10.2014
# Downloads the file list (IS_LINKS) naming them
# as specified in IS_NAMES. Then starts the 
# scripts bootstrap and chrootstrap (in this order).
##
VERSION="beta-rc1.1"
OPT_SETTINGS="settings.conf"
OPTSTR="hvl"

IS_LINKS=(
	"https://raw.githubusercontent.com/forflo/archfai/master/src/bootstrap.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/chrootstrap.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/crypt_hook.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/lvm_hook.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/fstab_hook.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/net_hook.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/initrd_hook.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/boot_hook.sh"
)

ENV="https://raw.githubusercontent.com/forflo/archfai/master/src/env.conf"

IS_NAMES=(
	"bootstrap.sh"
	"chrootstrap.sh"
	"crypt_hook.sh"
	"lvm_hook.sh"
	"fstab_hook.sh"
	"net_hook.sh"
	"initrd_hook.sh"
	"boot_hook.sh"
)

LOCAL_NAMES=(
	"bootstrap.sh"
	"chrootstrap.sh"
	"hooks/crypt_hook.sh"
	"hooks/lvm_hook.sh"
	"hooks/fstab_hook.sh"
	"hooks/net_hook.sh"
	"hooks/initrd_hook.sh"
	"hooks/boot_hook.sh"
)


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
# Param:
#   $1: "local" or ""
# Return:
#   <void>
##
is_startStrapping(){
	env_loadHooks "[is_start()]" "$1"

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
is_startOnline(){
	is_loadEnv || {
		clog 1 "[is_startOnline()]" Could not download environment file.
		exit 1
	}
	
	# look for additional local settings
	[ -f "${OPT_SETTINGS}" ] && {
		clog 3 "[is_startOnline()]" Found local settings File! Will now load it.
		. ${OPT_SETTINGS} || {
			clog 1 "[is_startOnline()]" Something failed while sourcing ${OPT_SETTINGS}
			exit 1
		}
		clog 3 "[is_startOnline()]" Loading finished successfully!
	}

	is_download || {
		clog 1 "[is_startOnline()]" Could not download bootstrapping files.
		exit 1
	}
	
	is_startStrapping || {
		clog 1  "[is_startOnline()]" Could not start bootstrapping.
		is_clean || {
			clog 1 "[is_startOnline()]" Could not clean environment.
			exit 1
		}
		exit 1
	}
	
	is_clean || {
		clog 1 "[is_startOnline()]" Could not clean environment.
		exit 1
	}
	
	exit 0
}

is_startLocal(){
	# 1) Checking for primary files
	for i in ${LOCAL_NAMES[*]}; do
		echo "[is_startLocal()]" Checking for file $i.
		[ -f $i ] && {
			echo "[is_startLocal()]" File $i OK.
		} || {			
			[ "$i" = "bootstrap" -o "$i" = "chrootstrap" ] && {
				echo "[is_startLocal()]" Mandatory file not found: $i.
				exit 0
			}
		}
	done
	
	# 2) Loading env.conf
	[ -f env.conf ] && {
		echo "[is_startLocal()]" Loading env.conf.
		chmod 750 env.conf || {
			echo "[is_startLocal()]" Chmod failed1
			exit 1
		}
		
		. env.conf || {
			echo "[is_startLocal()]" Something failed while sourcing env.conf!
			exit 1
		}
	} || {
		echo "[is_startLocal()]" env.conf is missing!
		exit 1
	}
	
	# 3) Loading additional settings
	[ -f "${OPT_SETTINGS}" ] && {
		clog 3 "[is_startOnline()]" Found local settings File! Will now load it.
		. ${OPT_SETTINGS} || {
			clog 1 "[is_startOnline()]" Something failed while sourcing ${OPT_SETTINGS}
			exit 1
		}
		clog 3 "[is_startOnline()]" Loading finished successfully!
	}
	
	# 4) Start bootstrap.sh
	is_startStrapping local || {
		clog 1  "[is_startOnline()]" Could not start bootstrapping.
		is_clean || {
			clog 1 "[is_startOnline()]" Could not clean environment.
			exit 1
		}
		exit 1
	}
	
	is_clean || {
		clog 1 "[is_startOnline()]" Could not clean environment.
		exit 1
	}
	
	exit 0
}

is_help(){
	cat << EOF
Archfai help
============
usage: $0 	[ -h | -l | -v ]
	v := Puts the current version on the console
	h := Displays help
	l := Toggles the local mode 
		 (see https://github.com/forflo/archfai)
EOF
	return 0
}

is_version(){
	cat << EOF
Version: ${VERSION}
===================
Archfai aims to provide a shell script package
specific for archlinux which makes it possible
to automate the  complete installation process
with just one command.
EOF
	return 0
}

[ "$#" -ne "0" ] && {
	# TODO: parse commandline arguments
	while getopts ${OPTSTR} input; do
		case ${input} in
			(h) 
				is_help
				exit 0
				;;
			(v) 
				is_version
				exit 0
				;;
			(l)
				echo Starting local...
				is_startLocal
				;;
			(*)
				echo Invalid commandline argument!
				is_help
				exit 1
				;;
		esac
	done
} || {
	is_startOnline
}