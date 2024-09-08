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

if [[ -z $3 ]]; then
	help_message
	exit
fi

if [[ -n $ZSH_VERSION ]]; then
	emulate sh
	# zsh will have duplicate output if multithreaded
	# for now, limit zsh to one thread
	THREADS=1
elif [[ -z $BASH_VERSION ]]; then
	echo "This script must be run with Bash or Zsh. Aborting."
	exit
fi

# Assign user inputs to variables
Type=$1
Length=$2
Rows=$3

if [[ -z $Rows ]]; then
	Rows=1
fi

if [[ -z $THREADS ]]; then
	# Get amount of threads on system
	# Threads=$(nproc)
	Threads=$(( $(nproc) / 2 ))
	if (( Threads == 0 )); then
		Threads=1
	fi
elif (( THREADS == 0 )); then
	Threads=1
else
	Threads=$THREADS
fi

# Divide total rows by available threads
Slice=$(( Rows / Threads ))

# If total rows is uneven,
# assign remainder to last thread
Remainder=$(( Rows % Threads ))
lastThread=$(( Threads - 1 ))

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

# Create arrays containing character ranges for each type
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
genString() {
	for (( rowLoop = 0; rowLoop < Slice; rowLoop ++ )); do
		for (( lengthLoop = 0; lengthLoop < Length; lengthLoop ++ )); do
			tempLength+=${charArray[ (( RANDOM % arrayLength )) ]}
		done
		echo "$tempLength"
		unset tempLength
	done
}

# https://stackoverflow.com/questions/360201/how-do-i-kill-background-processes-jobs-when-my-shell-script-exits
trap 'trap - SIGTERM && kill -- -$$' SIGINT

# Main logic function
for (( threadLoop = 0; threadLoop < Threads; threadLoop ++ )); do
	if (( threadLoop == lastThread )); then
		# https://askubuntu.com/a/385532
		(( Slice += Remainder ))
	fi
	genString &
done; wait
