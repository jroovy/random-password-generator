#!/usr/bin/env bash

help_message() {

printf "
$0 <length>
$0 <options> <length>

Options:
  [ -c <num> | --count <num> ]   =  Generate N number of passwords
  [ -d <num> | --range <num> ]   =  Specify character range (see below)
  [ -f | --fast ]                =  Generate fast but less secure passwords
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

Generate a 64-character length password
$0 64

Generate 100 hexadecimal (lowercase) passwords of 64-character length
$0 -d1o -c100 64

"

}

ARGS=$(getopt -n random_password_generator -l count:,range:,fast,help -o c:d:fh -- "$@")
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
					charset_range='0-9A-Z'
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
			
		'-f' | '--fast')
			gen_type=1
			shift
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
	help_message && exit 1
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

# Check if OpenSSL is available
# (LibreSSL doesn't respond to "set -e"; excluding for now.)
if
	command -v openssl > /dev/null
then
	useSSL='openssl'
else
	printf 'No compatible SSL found!\nPlease install OpenSSL.\n'
	exit 1
fi

## Functions

infinite_gen() {
	while true; do
		$useSSL rand 2147483647
	done
}

gen_password() {
	# https://stackoverflow.com/questions/21732248/exit-from-bash-infinite-loop-in-a-pipeline
	if (( gen_type == 1 )); then
		(set -e; infinite_gen) \
		| tr -dc "$charset_range" \
		| head -c $(( password_length * total_count ))
	else
		for (( current_count = 0; current_count < total_count; current_count ++ )); do
			(set -e; infinite_gen) \
			| tr -dc "$charset_range" \
			| head -c "$password_length"
		done
	fi
}

## Condition checks

if (( total_count > 1 )); then
	gen_password | fold -w "$password_length"
	printf '\n'
else
	gen_password
	printf '\n'
fi
