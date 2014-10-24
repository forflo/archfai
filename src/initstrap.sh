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
AF_OPTSTR="hvl"
AF_RUNLOCAL="false"
AF_VERSION="false"
AF_HELP="false"

AF_LINKS=(
	"https://raw.githubusercontent.com/forflo/archfai/master/src/env.conf"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/lib.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/bootstrap.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/chrootstrap.sh"
)

declare -A AF_HOOK_LINKS
AF_HOOK_LINKS=(
	["crypt_hook"]="https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/crypt_hook.sh"
	["lvm_hook"]="https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/lvm_hook.sh"
	["fstab_hook"]="https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/fstab_hook.sh"
	["net_hook"]="https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/net_hook.sh"
	["initrd_hook"]="https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/initrd_hook.sh"
	["boot_hook"]="https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/boot_hook.sh"
)

AF_FILES=(
	"bootstrap.sh"
	"chrootstrap.sh"
	"hooks/crypt_hook.sh"
	"hooks/lvm_hook.sh"
	"hooks/fstab_hook.sh"
	"hooks/net_hook.sh"
	"hooks/initrd_hook.sh"
	"hooks/boot_hook.sh"
)

archfai_help(){
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

archfai_version(){
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

##
# Downloads and sources the needed scripts
##
archfai_init(){
	##
	# Downloading critical files
	for i in ${AF_LINKS[*]}; do
		clog 2 "[archfai_init()]" Downloading and sourcing ${i:0:20} ...
		eval "$(curl -L ${i} > /dev/null 2>&1)" || {
			clog 1 "[archfai_init()]" Sourcing failed!
			return 1
		}
	done

	##
	# Downloading necessary hooks
	for i in ${AF_HOOKS}; do
		clog 2 "[archfai_init()]" Downloading and sourcing hook: ${i} ... 
		eval "$(curl -L ${AF_HOOK_LINKS[$i]} > /dev/null 2>&1)" || {
			clog 1 "[archfai_init()]" Sourcing of hook ${i} failed!
			return 1
		}
	done

	##
	# Sourcing optional File 
	[ -f "${OPT_SETTINGS}" ] && {
		clog 3 "[archfai_init()]" Found local settings File! Will now load it.
		. ${OPT_SETTINGS} || {
			clog 1 "[archfai_init()]" "Something failed while sourcing ${OPT_SETTINGS}"
			exit 1
		}
		clog 3 "[archfai_init()]" Loading finished successfully!
	}
	clog 2 "[archfai_init()]" Finished successfully.

	return 0
}

##
# Runs the bootstrapping files
# Param:
#   $1: "local" or ""
# Return:
#   <void>
##
archfai_startStrapping(){
	[ "$1" = "local" ] && {
		env_loadHooksLocal
	} || {
		env_loadHooks
	}
	
	# bs_install is the function that's been sourced by IS_NAMES[0]
	bs_install || {
		clog 1 "[bs_install()]" Script bootstrap failed!
		return 1
	}
	
	cs_install || {
		clog 1 "[cs_install]" Chrootstrap failed!
		return 1
	}
	
	flog 2 bold under "[archfai_startStrapping()]" Finished bootstrapping! "You're good to go!"

	return 0
}

##
# Starting point
##
archfai_startOnline(){
	archfai_startStrapping || {
		clog 1  "[is_startOnline()]" Could not start bootstrapping.
		return 1
	}

	return 0
}

archfai_startLocal(){
	# 1) Checking for primary files
	for i in ${AF_FILES[*]}; do
		echo "[archfai_startLocal()]" Checking for file $i.
		[ -f $i ] && {
			echo "[archfai_startLocal()]" File $i OK.
		} || {			
			[ "$i" = "bootstrap" -o "$i" = "chrootstrap" ] && {
				echo "[archfai_startLocal()]" Mandatory file not found: $i.
				exit 0
			}
		}
	done

	# 2) Loading env.conf
	[ -f env.conf ] && {
		echo "[archfai_startLocal()]" Loading env.conf.
		chmod 750 env.conf || {
			echo "[archfai_startLocal()]" Chmod failed!
			return 1
		}
		
		. env.conf || {
			echo "[archfai_startLocal()]" Something failed while sourcing env.conf!
			return 1
		}
	} || {
		echo "[archfai_startLocal()]" env.conf is missing!
		return 1
	}

	# 3) Loading additional settings
	[ -f "${OPT_SETTINGS}" ] && {
		clog 3 "[archfai_startLocal()]" Found local settings File! Will now load it.
		. ${OPT_SETTINGS} || {
			clog 1 "[archfai_startLocal()]" "Something failed while sourcing ${OPT_SETTINGS}!"
			return 1
		}
		clog 3 "[archfai_startLocal()]" Loading finished successfully!
	}

	# 4) Start bootstrap.sh
	archfai_startStrapping "local" || {
		clog 1  "[archfai_startLocal()]" Could not start bootstrapping.
		return 1
	}

	return 0
}

archfai_parseArgs(){
	while getopts ${AF_OPTSTR} input; do
		case ${input} in
			(h) HELP="true" 
				;;
			(v) VERSION="true"
				;;
			(l) RUNLOCAL="true"
				;;
			(*) clog 1 "[archfai_parseArgs()]" Option not allowed!
				return 1
				;;
		esac
	done

	return 0
}

archfai_main(){
	##
	# Simple logging function used before env.conf
	# is evaluated
	function clog(){
		if [ "$#" -eq "1" ]; then
			cat
			return 0
		fi
		shift
		echo "$@"
		return 0
	}

	archfai_parseArgs $@ || {
		clog 1 "[archfai_main()]" Could not parse arguments!
		return 1
	}

	archfai_init || {
		clog 1 "[archfai_main()]" Archfai could not be initialized!
		return 1
	}


	##
	# Evaluate the option values
	[ "$AF_VERSION" = "true" ] && {
		archfai_version
		return 0
	}

	[ "$AF_HELP" = "true" ] && {
		archfai_help
		return 0
	}

	[ "$AF_RUNLOCAL" = "true" ] && {
		archfai_startLocal || {
			clog 1 "[archfai_main()]" archfai_startLocal failed!
			return 1
		}
	} || {
		archfai_startOnline || {
			clog 1 "[archfai_main()]" archfai_startOnline failed!
			return 1
		}
	}

	return 0
}

archfai_main $@ && exit 0 || exit 1
