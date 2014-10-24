#!/bin/bash

####
##
# Color functions
##
####
export FG_BLACK=$(tput setaf 0)
export FG_RED=$(tput setaf 1)
export FG_GREEN=$(tput setaf 2)
export FG_YELLOW=$(tput setaf 3)
export FG_BLUE=$(tput setaf 4)
export FG_PURPLE=$(tput setaf 5)
export FG_CYAN=$(tput setaf 6)
export FG_WHITE=$(tput setaf 7)
export FG_ARR=(FG_BLACK FG_RED FG_GREEN FG_YELLOW FG_BLUE FG_PURPLE FG_CYAN FG_WHITE)

#Background
export BG_BLACK=$(tput setab 0)
export BG_RED=$(tput setab 1)
export BG_GREEN=$(tput setab 2)
export BG_YELLOW=$(tput setab 3)
export BG_BLUE=$(tput setab 4)
export BG_PURPLE=$(tput setab 5)
export BG_CYAN=$(tput setab 6)
export BG_WHITE=$(tput setab 7)
export BG_ARR=(BG_BLACK BG_RED BG_GREEN BG_YELLOW BG_BLUE BG_PURPLE BG_CYAN BG_WHITE)

#Extended Color-Values
export TERM_COLORS=$(tput colors)
export TERM_COLORS_VALUES=
for ((i=0; i<$TERM_COLORS; i++)); do
	TERM_COLORS_VALUES[i]="$(tput setaf $i)" 
		# innerhalb von [] müssen variablen nicth
		# mit $ gekennzeichnet werden, da es sich
		# hier um einen arithmetischen ausdruck handelt!
done

#Formatting
export TERM_BOLD=$(tput bold)
export TERM_DIM=$(tput dim)
export TERM_UNDERLINE=$(tput smul)
export TERM_NEGATIVE=$(tput setab 7)
export TERM_BLINK=$(tput blink)

#Special Functions
export TERM_RESET=$(tput sgr0)

##
# Functions
##
random_color(){
	colorname=${FG_ARR[$(random_simple 8)]}
	echo -n ${!colorname}
}

random_color_extended(){
	echo -n "${TERM_COLORS_VALUES[$(random_simple 255)]}"
}

term_reset(){
	echo -n $TERM_RESET
}

print_blue(){
	echo -ne $FG_BLUE "$1" $TERM_RESET 
}

print_red(){
	echo -ne $FG_RED "$1" $TERM_RESET 
}

print_black(){
	echo -ne $FG_BLACK "$1" $TERM_RESET 
}

print_green(){
	echo -ne $FG_GREEN "$1" $TERM_RESET 
}

print_yellow(){
	echo -ne $FG_YELLOW "$1" $TERM_RESET 
}

print_purple(){
	echo -ne $FG_PURPLE "$1" $TERM_RESET 
}

print_cyan(){
	echo -ne $FG_CYAN "$1" $TERM_RESET 
}

print_white(){
	echo -ne $FG_WHITE "$1" $TERM_RESET 
}

####
##
# Misc functions used by bootstrap.sh and chrootstrap.sh
##
####
env_loadHooksOnline(){
	##
	# Downloading necessary hooks
	for i in ${AF_HOOKS}; do
		clog 2 "[archfai_init()]" Downloading and sourcing hook: ${i} ... 
		eval "$(curl -L ${AF_HOOK_LINKS[$i]} 2> /dev/null)" || {
			clog 1 "[archfai_init()]" Sourcing of hook ${i} failed!
			return 1
		}
	done
	
	return 0
}

##
# Loads hooks if running with $ initstrap.sh -l
##
env_loadHooksLocal(){
	for i in ${AF_HOOK_FILES[*]}; do
		clog 2 "[env_loadHooksLocal()]" Sourcing hook: ${i} ... 
		. ${i} || {
			clog 1 "[env_loadHooksLocal()]" Sourcing of hook ${i} failed!
			return 1
		}
	done

	return 0
}

env_execChroot(){
	clog 2 "[env_execChroot()]" Exec command in arch-chroot:
	clog 2 "[env_execChroot()]    " "$@"

	echo "$@" | arch-chroot /mnt/ /bin/bash || {
		clog 1 "[env_execChroot()]" Exec in chroot failed!
		return 1
	}
	
	return 0
}

env_execChrootH(){
	clog 2 "[env_execChroot()]" Exec commandblock in arch-chroot:

	arch-chroot /mnt/ /bin/bash || {
		clog 1 "[env_execChroot()]" Exec in chroot failed!
		return 1
	}
	
	return 0
}

####
##
# Logging functions
##
####

LOG_DATEOPTS="+%d.%h.%Y-%H:%M:%S"
LOG_POPEN="["
LOG_PCLOSE="]"

##
# Variables for this module
##
LOG_PROMPT=""
LOG_PROMPT_FUNC="log_prompt"

log_reset_prompt(){
	LOG_PROMPT_FUNC="log_prompt"
}

log_no_prompt(){
	:
}

log_simple_prompt(){
	echo [log message:]" "
}

log_prompt(){
	echo "$LOG_PROMPT"
}

##
# Loggs without color
# Param:
#   $1 .. $n: Strings to log on one line
#   | <stdin>: Lines to log
# Return: 
#   0: on success
#   1: on failure
##
blog(){
	if [ "$#" -eq 0 ]; then
		mapfile TEXT 
		for ((i=0; i<${#TEXT[@]}; i++)); do
			echo -n "$($LOG_PROMPT_FUNC)${TEXT[i]}"
		done
	else
		echo "$($LOG_PROMPT_FUNC)$@"
	fi
	return 0
}

##
# Loggs with color
# Param:
#   $1: Color code (see tput)
#   $2 .. $n: Strings to log on one line
#   | <stdin>: Lines to log
#   - $1 has to be between $ tput colors
#   - clog uses blog if it's output isn't connected
#		to a terminal/pseudo-terminal
#   - If only the color code is used, every further
#		arguments are ignored and stdin is considered to be
#		the log message provider
#   - If the number of positional parameters is greater than 1
#		they are considered as log messages
# Return: 
#   0: on success
#   1: on fawithoutilure
##
clog(){
	[ "$#" = "0" ] && {
		is_int "$1" || {
			echo You have to provide a color code
			return 1
		}
	}

	# only colorization if stdout referes to a terminal!
	if [ -t 1 ]; then
		# stdin is used as log message provider
		if [ "$#" = 1 ]; then
			# color code valid?
			if [ "$1" -ge 0 -a "$1" -lt $TERM_COLORS ]; then
				mapfile TEXT
				for ((i=0; i<${#TEXT[@]}; i++)); do
					echo -n "$($LOG_PROMPT_FUNC)${TERM_COLORS_VALUES[$1]}${TEXT[i]}$TERM_RESET"
				done
				return 0
			else
				mapfile TEXT
				for ((i=0; i<${#TEXT[@]}; i++)); do
					echo -n "$($LOG_PROMPT_FUNC)${TEXT[i]}$TERM_RESET" # -n weil \n schon in text!
				done
				return 0
			fi
		# use positional parameters as log messages
		else 
			if [ "$1" -ge 0 -a "$1" -lt $TERM_COLORS ]; then
				temp="$1"
				shift 1
				echo "$($LOG_PROMPT_FUNC)${TERM_COLORS_VALUES[$temp]}${@}$TERM_RESET"
				return 0
			else
				echo "$($LOG_PROMPT_FUNC)${@}"
				return 1
			fi
		fi
	else
		shift 1
		blog $@
	fi
}

##
# Loggs with color and formatting like underlines or
# italic/bold-fonts
# Param:
#   $1: Color code (see tput)
#   $2 .. $n: Strings to log on one line
#   | <stdin>: Lines to log
#   - $1 has to be between $ tput colors
#   - flog uses blog if it's output isn't connected
#		to a terminal/pseudo-terminal
#   - If only the color code is used, every further
#		arguments are ignored and stdin is considered to be
#		the log message provider
#   - If the number of positional parameters is greater than 1
#		they are considered as log messages
# Return: 
#   0: on success
#   1: on failure
##
flog(){
	[ "$#" = "0" ] && {
		is_int "$1" || {
			echo You have to provide a color code
			return 1
		}
	}
	
	local color="${TERM_COLORS_VALUES[$1]}"
	local format=""
	local count=0

	# check color code
	if [ "$1" -ge 0 -a "$1" -lt $TERM_COLORS ]; then
		shift 1
	else
		color=""
		shift 1
		# error no color output
	fi

	if [ "$#" -gt 0 ]; then
		# parse format codes, no error detection 
		for i in $@; do
			case "$i" in
				(bold) 
					format=${format}$TERM_BOLD ;;
				(blink) 
					format=${format}$TERM_BLINK ;;
				(under) 
					format=${format}$TERM_UNDERLINE ;;
				(dim) 
					format=${format}$TERM_DIM ;;
				(neg) 
					format=${format}$TERM_NEGATIVE ;;
				(*) 	
					break ;;
			esac
			((count++))
		done
		shift $count
	fi
	
	# only color sequences if stdin outputs to a terminal
	if [ -t 1 ]; then 
		if [ "$#" = 0 ]; then
			# take arguments from stdin
			mapfile TEXT
			for ((i=0; i<${#TEXT[@]}; i++)); do
				echo -n "$($LOG_PROMPT_FUNC)${color}${format}${TEXT[i]}$TERM_RESET"
			done
			return 0
		elif [ "$#" -gt 0 ]; then
			# take arguments from $3 - $#
			echo "$($LOG_PROMPT_FUNC)${format}${color}${@}$TERM_RESET"
		else
			echo Sie müssen einen Farbcode und einen Formatcode angeben >&2 
			return 1
		fi
	else
		blog $@
	fi
}

qlog(){
:
}


####
##
# Typecheck functions
##
####

##
# Checks if the parameter is an integer
# Param:
#   $1: Value for checking
# Return:
#   0: Its an int
#   1: Its not an int
##
is_int(){
	if [ $# -ne 1 ]; then
		return 1
	fi
	echo " $1 " | grep -e '\<[0-9]+\>' > /dev/null
	return $? 
}

##
# 0 if $1 matches [a-zA-Z0-9]+
##
is_alnum_only(){
	if [ $# -ne 1 ]; then
		return 1
	fi
	echo "$1" | grep -e '\<[a-zA-Z0-9]+\>'  > /dev/null
	return $? 
}

##
# until now just the following regex is matched against
# the string lying inside of $1: [0-9]+(,[0-9]+)?
##
is_decimal(){
	if [ $# -ne 1 ]; then
		return 1
	fi
	echo "$1" | grep -e '\<[1-9][0-9]*(,[0-9]+)?\>'  /dev/null
	return $? 
}

is_ip_address(){
	if [ $# -ne 1 ]; then
		return 1
	fi
	echo "$1" | grep -e '([0-9]|[0-9][0-9]|[1-2][0-5][0-5]\.){3}[0-9]|[0-9][0-9]|[1-2][0-5][0-5]'
	return $? 
}

is_mac_address(){
	if [ $# -ne 1 ]; then
		return 1
	fi
	echo "$1" | grep -e '([0-9a-fA-F][0-9a-fA-F]:){5}[a-fA-F0-9][A-Fa-f0-9]'
	return $? 
}

##
# Checks if a variable denotes a positive
# truth value
# Params:
#   $1: The variable to check
# Return
#   0 on truth
#   1  on false
#   2 if no valid truth value has 
#		been provided
##
is_yes(){
	case ${1} in
		([Yy][Ee][Ss]|[Tt][Rr][Uu][Ee]|[Oo][Nn]|1)
			return 0
			;;
		([Nn][Oo]|[Ff][Aa][Ll][Ss][Ee]|[Oo][Ff][Ff]|0)
			return 1
			;;
		(*)
			return 2
			;;
	esac
}
