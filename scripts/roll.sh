#!/bin/bash

input="$@"
counting="1"

: ${input:=1d6}

roll_dice() {
	local count="$1"
	local size="$2"

	if [ "$TERM" != "linux" ]&&[ "$TERM" != "screen.linux" ]; then
		local color="38;5;$(( size % 211 + 20 ))"
	else
		local color="3$(( size % 8 ))"
	fi

	echo -e "\e[${color};1;7mRolling ${count}d${dsize}\e[0m"
	for (( r = 0; r < $count; r++ )); do
		echo -en "\e[${color};1m"
		echo "d${dsize} #$((r + 1)): $(( RANDOM % size + 1))"
		echo -en "\e[0m"
	done
	 
	echo ""
}

for ((i = 0; i < ${#input}; i++)); do

	#echo "$((i + 1)) / ${#input}"

	#continue
	if [[ ${input:i:1} =~ [0-9] ]]; then
		# Interperet numeric input
		if [ "$counting" ]; then
			count+="${input:i:1}"
		else
			dsize+="${input:i:1}"
		fi
	elif [ "${input:i:1}" = "d" -o "${input:i:1}" = "D" ]; then
		# We have a D, next characters are dsize!!

		: ${count:=1} # If we have no die count specified, default to 1

		if [ ! "$counting" ]; then
			echo "Invalid syntax! Use only one \"d\" such as in 2d6 or 1d20 only!" >&2
			exit 1
		fi

		unset counting

	elif [ "${input:i:1}" = " " ]; then
		# If input is a space, or is last character, execute roll
		roll_dice "$count" "$dsize"

		unset count dsize
		counting="1"
	else
		echo "Invalid Syntax!" >&2
		cat <<- EOF >&2
			Roll dice like so
			roll 1d20
			roll 2d6
			
			OR
			roll 1d20 2d6
		EOF
		exit 1
	fi

	if [ ! "$counting" ] && [ "$(( i + 1))" = "${#input}" ]; then 
		roll_dice "$count" "$dsize"
		unset count dsize counting
	fi
done
