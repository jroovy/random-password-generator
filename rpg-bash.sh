#!/usr/bin/env bash

# This script is compatible with zsh
# Replace 'bash' above with 'zsh'

scriptName="${0##*/}"

help_message() {
echo "Options:
  -t<type>
    Type of characters included in generated password(s)
      Types:
        1   =  hexadecimal
        1u  =  hexadecimal, uppercase
        1o  =  hexadecimal, lowercase
        2   =  alphanumeric
        2u  =  alphanumeric, uppercase
        2o  =  alphanumeric, lowercase
        3   =  ascii
  -l<integer>
    Length of generated password(s)
  -q<integer>
    Quantity of generated password(s)
  -h
    This help message
  -i
    Show hidden help message

Default parameters:
  -t2, -l64, -q1

Usage: $scriptName <options>
Example: $scriptName -t2u -l64 -q10"
}
hidden_help() {
echo "List of variables that can be passed to this script:
  USE_SHELL=<bash|zsh>
    Force use of a specific shell (bash or zsh)
  THREADS=<integer>
    Use # of system threads

Default values:
  USE_SHELL = prefer zsh if available
  THREADS = available threads / 2

Usage: <variables> $scriptName ...
Example: USE_SHELL=zsh THREADS=2 $scriptName ..."
}

# https://linuxsimply.com/bash-scripting-tutorial/functions/script-argument/bash-getopts/
while getopts 't:l:q:hi' flag; do
	case $flag in
		t)
			Type=$OPTARG
		;;
		l)
			Length=$OPTARG
		;;
		q)
			Quantity=$OPTARG
		;;
		h)
			help_message
			exit
		;;
		i)
			hidden_help
			exit
		;;
	esac
done

if [[ -z $readyMT ]]; then
	readyMT=1
	if [[ -z $Type ]]; then
		Type=2
	fi
	if [[ -z $Length ]]; then
		Length=64
	fi
	if [[ -z $Quantity ]]; then
		Quantity=1
	fi
	if [[ -z $1 ]]; then
		echo "Using default parameters; '$scriptName -h' for help"
	fi

	# https://stackoverflow.com/a/677212
	if [[ -n $USE_SHELL ]]; then
		useShell=$USE_SHELL
	else
		for i in zsh bash; do
			if command -v $i > /dev/null; then
				useShell=$i
				break
			fi
		done
	fi
	if [[ -z $useShell ]]; then
		echo "Bash and Zsh not found! Aborting."
		exit
	fi

	if [[ -z $THREADS ]]; then
		# Get amount of threads on system
		# Threads=$(nproc)
		Threads=$(( $(nproc) / 2 ))
		if (( Threads == 0 )); then
			Threads=1
		fi
	else
		Threads=$THREADS
	fi

	# Divide total rows by available threads
	Slice=$(( Quantity / Threads ))

	# If total rows is odd,
	# assign remainder to last thread
	Remainder=$(( Quantity % Threads ))
	lastThread=$(( Threads - 1 ))

	# Export required variables
	export readyMT useShell

	# https://stackoverflow.com/questions/360201/how-do-i-kill-background-processes-jobs-when-my-shell-script-exits
	trap 'trap - SIGTERM && kill -- -$$' SIGINT

	# Main logic function
	for (( threadLoop = 0; threadLoop < Threads; threadLoop ++ )); do
		if (( threadLoop == lastThread )); then
			# https://askubuntu.com/a/385532
			(( Slice += Remainder ))
		fi
		"$useShell" "$0" $Type $Length $Slice &

		# Reinitialize seed to prevent duplicate output
		"$useShell" -c 'echo $RANDOM' > /dev/null
	done; wait
else
	# https://unix.stackexchange.com/questions/38172/are-all-bash-scripts-compatible-with-zsh
	if [[ "$useShell" == zsh ]]; then
		emulate sh
	fi

	Type=$1
	Length=$2
	Quantity=$3

	# Base arrays of characters
	numeric=(
	\0	\1	\2	\3	\4	\5	\6	\7	\8	\9
	)
	alphabetLower=(
	\a	\b	\c	\d	\e	\f	\g	\h	\i	\j
	\k	\l	\m	\n	\o	\p	\q	\r	\s	\t
	\u	\v	\w	\x	\y	\z
	)
	alphabetUpper=(
	\A	\B	\C	\D	\E	\F	\G	\H	\I	\J
	\K	\L	\M	\N	\O	\P	\Q	\R	\S	\T
	\U	\V	\W	\X	\Y	\Z
	)
	symbols=(
	\!	\"	\#	\$	\%	\&	\'	\(	\)	\*
	\+	\,	\-	\.	\/	\:	\;	\<	\=	\>
	\?	\@	\[	\\	\]	\^	\_	\`	\{	\|
	\}	\~
	)

	# Arrays containing character ranges for each type
	case "$Type" in
		1 | 1o)
			charArray=("${numeric[@]}" "${alphabetLower[@]:0:6}")
		;;
		1u)
			charArray=("${numeric[@]}" "${alphabetUpper[@]:0:6}")
		;;
		2o)
			charArray=("${numeric[@]}" "${alphabetLower[@]}")
		;;
		2u)
			charArray=("${numeric[@]}" "${alphabetUpper[@]}")
		;;
		2)
			charArray=("${numeric[@]}" "${alphabetLower[@]}" "${alphabetUpper[@]}")
		;;
		3)
			charArray=("${numeric[@]}" "${alphabetLower[@]}" "${alphabetUpper[@]}" "${symbols[@]}")
		;;
	esac; arrayLength=${#charArray[@]}

	# Main generation function
	for (( rowLoop = 0; rowLoop < Quantity; rowLoop ++ )); do
		for (( lengthLoop = 0; lengthLoop < Length; lengthLoop ++ )); do
			tempLength+=${charArray[ (( RANDOM % arrayLength )) ]}
		done
		echo "$tempLength"
		unset tempLength
	done
fi
