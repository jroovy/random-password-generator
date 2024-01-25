#!/usr/bin/env bash
#!/usr/bin/bash

goto_help() {
printf "
No arguments specified.
Run \"$0 -h\" for instructions.

"
}

help_message() {

printf "
$0 <length>
$0 <options> <length>

Options:
  [ -c <num> | --count <num> ]   =  Generate N number of passwords
  [ -d <num> | --range <num> ]   =  Specify character range (see below)
  [ -h | --help ]                =  Display this help message


Character ranges:
   1  =  Hexadecimal
  1o  =  Hexadecimal (lowercase)
  1u  =  Hexadecimal (uppercase)
   2  =  Alphabetic
  2u  =  Alphabetic (uppercase)
  2o  =  Alphabetic (lowercase)
   3  =  Alphanumeric
  3o  =  Alphanumeric (lowercase)
  3u  =  Alphanumeric (uppercase)
   4  =  ASCII (Default)


Examples:

Generate 100 hexadecimal (lowercase) passwords of 64-character length
$0 -d1o -c100 64

"

}

ARGS=$(getopt -n random_password_generator -l count:,range:,help -o c:d:h -- "$@")
eval set -- "$ARGS"

while :
do
	case "$1" in
		'-c' | '--count')
			re='^[0-9]+$'
			if ! [[ $2 =~ $re ]] ; then
				printf "error: Not a number\n" >&2; exit 1
			else
				total_count="$2"
			fi
			shift 2
			;;

		'-d' | '--range')
			charset_range="$2"

			case $2 in
				'1' | '1o')
					#hexadecimal (lowercase, default)
					charset_range='0-9a-f'
					;;
				'1u')
					#hexadecimal (uppercase)
					charset_range='0-9A-F'
					;;
				'2')
					#alphabetic
					charset_range='a-zA-Z'
					;;
				'2u')
					#alphabetic (uppercase)
					charset_range='A-Z'
					;;
				'2o')
					#alphabetic (lowercase)
					charset_range='a-z'
					;;
				'3')
					#alphanumeric
					charset_range='[:alnum:]'
					;;
				'3o')
					#alphanumeric (lowercase)
					charset_range='0-9a-z'
					;;
				'3u')
					#alphanumeric (uppercase)
					charse_range='0-9A-Z'
					;;
				'4')
					#base94 (all chars on keyboard)
					charset_range='[:graph:]'
					;;
				*)
					printf "Option '-d${2}' does not exist. Aborting\n"
					exit
			esac
			shift 2
			;;
			
		'-h' | '--help')
			help_message && exit 0
			shift
			;;
			
		--)
			shift
			break
			;;
	esac
done

## Empty arguments check

if [[ -z $@ ]]; then
	goto_help && exit 1
fi

if [[ -z $password_length ]]; then
	re='^[0-9]+$'
	if ! [[ ${@:1:1} =~ $re ]] ; then
		printf "Password length should be number. Aborting.\n" >&2; exit 1
	else
		password_length="${@:1:1}"
	fi
fi

if [[ -z $charset_range ]]; then
	charset_range='[:graph:]'
fi

if [[ -z $total_count ]]; then
	total_count=1
fi

## Functions

gen_password() {
	while true; do
		openssl rand 2147483647
	done
}

## Condition checks

#https://stackoverflow.com/questions/21732248/exit-from-bash-infinite-loop-in-a-pipeline

final_num=$(( password_length * total_count ))

if [[ total_count -gt 1 ]]; then
	(set -e; gen_password) \
		| tr -dc "$charset_range" \
		| head -c "$final_num" \
		| fold -w "$password_length"
	printf '\n'
else
	(set -e; gen_password) \
		| tr -dc "$charset_range" \
		| head -c "$final_num"
	printf '\n'
fi