#!/usr/bin/env bash

# This script is compatible with zsh
# Replace 'bash' above with 'zsh'

# https://unix.stackexchange.com/questions/38172/are-all-bash-scripts-compatible-with-zsh
if [[ -n $ZSH_VERSION ]]; then
	emulate sh
fi

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

if [[ -z $@ ]]; then
	help_message
	exit
fi

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
hexLower=(
	"${numeric[@]}"
	"${alphabetLower[@]:0:6}"
)
hexUpper=(
	"${numeric[@]}"
	"${alphabetUpper[@]:0:6}"
)
alnumLower=(
	"${numeric[@]}"
	"${alphabetLower[@]}"
)
alnumUpper=(
	"${numeric[@]}"
	"${alphabetUpper[@]}"
)
alnum=(
	"${alnumLower[@]}"
	"${alphabetUpper[@]}"
)
ascii=(
	"${alnum[@]}"
	"${symbols[@]}"
)

# Delete base arrays to save memory
unset \
	numeric \
	alphabetLower \
	alphabetUpper \
	symbols

# Assign user inputs to variables
Type=${@:1:1}
Length=${@:2:1}
Rows=${@:3:1}

if [[ -z $Rows ]]; then
	Rows=1
fi

# Get amount of threads on system
# Threads=$(nproc)
Threads=$(( $(nproc) / 2 ))

if [[ Threads -eq 0 ]]; then
	Threads=1
fi

# Divide total rows by available threads
Slice=$(( Rows / Threads ))

# If total rows is uneven,
# assign remainder to last thread
Remainder=$(( Rows % Threads ))
LastThread=$(( Threads - 1 ))

# Main generation functions
hexLower() {
	for (( rowLoop = 0; rowLoop < Slice; rowLoop ++ )); do
		for (( lengthLoop = 0; lengthLoop < Length; lengthLoop ++ )); do
			tempLength+="${hexLower[ (( RANDOM % 16 )) ]}"
		done
		echo "${tempLength}"
		unset tempLength
	done
}
hexUpper() {
	for (( rowLoop = 0; rowLoop < Slice; rowLoop ++ )); do
		for (( lengthLoop = 0; lengthLoop < Length; lengthLoop ++ )); do
			tempLength+="${hexUpper[ (( RANDOM % 16 )) ]}"
		done
		echo "${tempLength}"
		unset tempLength
	done
}
alnumLower() {
	for (( rowLoop = 0; rowLoop < Slice; rowLoop ++ )); do
		for (( lengthLoop = 0; lengthLoop < Length; lengthLoop ++ )); do
			tempLength+="${alnumLower[ (( RANDOM % 36 )) ]}"
		done
		echo "${tempLength}"
		unset tempLength
	done
}
alnumUpper() {
	for (( rowLoop = 0; rowLoop < Slice; rowLoop ++ )); do
		for (( lengthLoop = 0; lengthLoop < Length; lengthLoop ++ )); do
			tempLength+="${alnumUpper[ (( RANDOM % 36 )) ]}"
		done
		echo "${tempLength}"
		unset tempLength
	done
}
alnum() {
	for (( rowLoop = 0; rowLoop < Slice; rowLoop ++ )); do
		for (( lengthLoop = 0; lengthLoop < Length; lengthLoop ++ )); do
			tempLength+="${alnum[ (( RANDOM % 62 )) ]}"
		done
		echo "${tempLength}"
		unset tempLength
	done
}
ascii() {
	for (( rowLoop = 0; rowLoop < Slice; rowLoop ++ )); do
		for (( lengthLoop = 0; lengthLoop < Length; lengthLoop ++ )); do
			tempLength+="${ascii[ (( RANDOM % 94 )) ]}"
		done
		echo "${tempLength}"
		unset tempLength
	done
}

# https://stackoverflow.com/questions/360201/how-do-i-kill-background-processes-jobs-when-my-shell-script-exits
trap "trap - SIGTERM && kill -- -$$" SIGINT

# Main logic function
for (( threadLoop = 0; threadLoop < Threads; threadLoop ++ )); do
	if (( threadLoop = LastThread )); then
		# https://askubuntu.com/a/385532
		(( Slice += Remainder ))
	fi
	case $Type in
		'1' | '1o')
			hexLower &
		;;
		'1u')
			hexUpper &
		;;
		'2')
			alnum &
		;;
		'2o')
			alnumLower &
		;;
		'2u')
			alnumUpper &
		;;
		'3')
			ascii &
		;;
	esac
done
wait
