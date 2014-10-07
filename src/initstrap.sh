#!/bin/bash

IS_LINKS=(
	"https://raw.githubusercontent.com/forflo/archfai/master/src/bootstrap.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/chrootstrap.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/crypt.sh"
	"https://raw.githubusercontent.com/forflo/archfai/master/src/hooks/lvm.sh"
)

IS_NAMES=(
	"step_0.sh"
	"step_1.sh"
	"crypt.sh"
	"lvm.sh"
)

ENV="https://raw.githubusercontent.com/forflo/archfai/master/src/env.conf"

##
# Downloads the needed scripts
##
is_download(){
	for ((i=0; i<${#IS_LINKS[*]}; i++)); do
		echo Downloading ${IS_LINKS[$i]}
		curl -o ${IS_NAMES[i]} -L ${IS_LINKS[$i]} > /dev/null 2>&1 || {
			echo Download failed! ...
			return 1
		}
		
		chmod 750 ${IS_NAMES[i]} || {
			echo Chmod failed
			return 1
		}
	done

	echo Downloading env file $ENV
	curl -o env.conf -L $ENV > /dev/null 2>&1 || {
		echo Download failed! ...
		return 1
	}
	
	chmod 750 env.conf || {
		echo Chmod failed
		return 1
	}

	return 0
}

##
# Runs every
##
is_startStrapping(){
	bash -- step_0 || {
		echo Initial Bootstrapping failed
		return 1
	}

	# copy env to chroot-environment
	cp env.conf /mnt/ || return 1
	arch-chroot /mnt/ /bin/bash < step_1 || {
		echo Arch-chroot strapping failed
		return 1
	}

	rm /mnt/env.conf || return 1
	return 0
}

##
# Deletes each downloaded file
##
is_clean(){
	for ((i=0; i<${#IS_NAMES[*]}; i++)); do
		rm ${IS_NAMES[i]} > /dev/null 2>&1 || {
			echo Deletion of step_$i failed
			return 1 
		}
	done
	return 0
}

##
# Starting point
##
is_start(){
	is_download
	is_startStrapping || {
		echo Could not execute inistrap
		is_clean
		exit 1
	}
	is_clean
	exit 0
}

is_start