#!/usr/bin/env bash

# This script is compatible with zsh
# Replace 'bash' above with 'zsh'

help_message() {
echo "Types:
   1  =  hexadecimal
  1u  =  hexadecimal, uppercase
  1o  =  hexadecimal, lowercase
   2  =  alphanumeric
  2u  =  alphanumeric, uppercase
  2o  =  alphanumeric, lowercase
   3  =  ascii

Usage: $0 <type> <length> <count>
Example: $0 2u 64 100"
}

if [[ -z $readyMT ]]; then
	if [[ -z $3 ]]; then
		help_message
		exit
	fi
	
	readyMT=1
	
	# https://stackoverflow.com/a/677212
	if [[ -n $USE_SHELL ]]; then
		useShell="$USE_SHELL"
	elif command -v zsh > /dev/null; then
		useShell='zsh'
	elif command -v bash > /dev/null; then
		useShell='bash'
	else
		echo "Bash and Zsh not found! Aborting."
		exit
	fi

	# Assign user inputs to variables
	Type=$1
	Length=$2
	Rows=$3

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
	Slice=$(( Rows / Threads ))

	# If total rows is odd,
	# assign remainder to last thread
	Remainder=$(( Rows % Threads ))
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
		# Reinitialize seed to prevent duplicate output
		if [[ "$useShell" == zsh ]]; then
			zsh -c 'echo $RANDOM' > /dev/null
		fi
		$useShell "$0" $Type $Length $Slice &
	done; wait
else
	# https://unix.stackexchange.com/questions/38172/are-all-bash-scripts-compatible-with-zsh
	if [[ "$useShell" == zsh ]]; then
		emulate sh
	fi

	Type=$1
	Length=$2
	Rows=$3

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
	for (( rowLoop = 0; rowLoop < Rows; rowLoop ++ )); do
		for (( lengthLoop = 0; lengthLoop < Length; lengthLoop ++ )); do
			tempLength+=${charArray[ (( RANDOM % arrayLength )) ]}
		done
		echo "$tempLength"
		unset tempLength
	done
fi
