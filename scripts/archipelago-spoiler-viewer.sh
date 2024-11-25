#!/bin/bash
shopt -s extglob
declare -r DEPENDS=( "fzf" )
declare SLOG=()
MODE=items

dep_check() {
	# Ensure the script's dependencies are available
	local dep missing=()
	for dep in "${DEPENDS[@]}"; do
		command -v "$dep" >/dev/null || missing+=( "$dep" )
	done

	if [ "${#missing[@]}" != 0 ]; then
		echo "You're missing ${#missing[@]} dependencies:"
		printf -- " - %s\n" "${missing[@]}" 
		exit 1
	fi
}

rlog() {
	# Read the spoiler log to popualte SLOG
	local tmp line
	mapfile -t tmp < "$1"
	ACTIVE_FILE="$1"

	# Log lines always rsembles
	#   LOCATION (PLAYER): ITEM (PLAYER)
	#

	echo "File: $1"
	echo -n "  Reading... "
	
	for line in "${tmp[@]}"; do
		[[ $line =~ \)$ ]] || continue # Must end with Parenthesis
		[[ $line =~ ^\  ]] && continue # Must NOT begin with space
		# Any line remaining is important
		#
		SLOG+=( "$line" )
	done

	echo -e "Complete!\n"
}

pause() {
	[ "${1,,}" = "-s" ] || echo "Press any key to continue."
	read -rsn1
}

menu() {
	local item items=() r i loc locs=() pad MODE=${MODE:-items}
	local fileopts=()

	[ "${!FILES[@]}" -gt 1 ] && mapfile -t fileopts < <(printf -- "/file %s\n" "${FILES[@]}")


	# Menu Loop
	while true; do
		local curFile=$ACTIVE_FILE

		echo -n "Loading Spoiler data... "

		# Determine how many 0s to pad with for looking nice
		pad=${#SLOG[@]} # Number of entries in log
		pad=${#pad}     # Number of digits in number

		# Prep Items Array
		i=0
		for item in "${SLOG[@]}"; do
			items+=( "$(printf "%0${pad}d" $i): ${item##*): }" )
			: $((i++))
		done

		# Prep Locations Array
		i=0
		for loc in "${SLOG[@]}"; do
			locs+=( "$(printf "%0${pad}d" $i): ${loc%%):*})" )
			: $((i++))
		done

		echo "Complete!"

		while [ "$curFile" = "$ACTIVE_FILE" ]; do
			if [ "$MODE" = "items" ]; then
				# View Items, reveal locations
				r=$(printf -- "%s\n" "${items[@]}" "${fileopts[@]}" "/quit" "/locations" | fzf --header="Select an Item to Reveal (FILE: ${curFile})")
				[ "$?" = "130" ]        && exit 130
				[ "$r" = "/quit" ]      && exit
				[ "$r" = "/locations" ] && MODE=locations && continue
				[[ $r =~ ^/file ]]      && rlog "${r#* }" && break

				i=${r%%:*}   # Isolate Item Index
				i=${i/#*(0)} # Remove 0 padding

				echo "ID       : $i"
				echo "ITEM     : ${r#*: }"
				echo "LOCATION : ${SLOG[i]%%):*})"
				pause -s
				echo ""
			else
				echo "LOCATIONS"
				# View Locations, reveal Items
				r=$(printf -- "%s\n" "${locs[@]}" "${fileopts[@]}" "/quit" "/items" | fzf --header="Select a Location to Reveal (FILE: ${curFile})")
				[ "$?" = "130" ]    && exit 130
				[ "$r" = "/quit" ]  && exit
				[ "$r" = "/items" ] && MODE=items && continue
				[[ $r =~ ^/file ]]  && rlog "${r#* }" && break

				i=${r%%:*}   # Isolate Item Index
				i=${i/#*(0)} # Remove 0 padding

				loc=${r%%:"$i"}
				echo "ID       : $i"
				echo "ITEM     : ${SLOG[i]##*): }"
				echo "LOCATION : ${r#*: }"
				pause -s
				echo ""
			fi
		done
	done
}

help_msg() {
	echo -e "\e[32;1m${0##*/}\e[39m - View Archipelago Spoiler Logs"

	echo -e "\nOPTIONS\e[0m"
	printf "  %-28s %s\n" \
		"--items, -i"       "Display Item Names (default)"
		"--locations, -l"   "Display Location Names"
		"--"                "Interperet any further Arguments as Files"
		"--help, -?"        "Display this message"
}

argp() {
	local a narg i=0 errors=()

	for a in "$@"; do
		case "$a" in
			--)
				[ "$narg" ] && FILES+=( "$a" ) && continue
				narg=1
				;;
			--items|-i)
				[ "$narg" ] && FILES+=( "$a" ) && continue
				MODE=items
				;;
			--locations|-l)
				[ "$narg" ] && FILES+=( "$a" ) && continue
				MODE=locations
				;;
			--help|-?)
				help_msg
				exit
				;;
			--*)
				# Default --
				[ "$narg" ] && FILES+=( "$a" ) && continue
				echo "Invalid"
				exit
				errors+=( "Invalid Option: $a" )
				;;
			-*)
				# Default -
				[ "$narg" ] && FILES+=( "$a" ) && continue
				# handle short opt
				for ((i=1; i > "${#a}"; i++)); do
					case "${a:"$i":1}" in
						i)
							MODE=items
							;;
						l)
							MODE=locations
							;;
						*)
							errors+=( "Invalid Short Option \"${a:"$i":1}\" in \"$a\"" )
							;;
					esac
				done
				;;
			*)
				FILES+=( "$a" )
				;;
		esac	
	done

	for f in "${FILES[@]}"; do
		[ -f "$f" ] || errors+=( "File does not exist: $f" )
	done

	[ "${#errors[@]}" = "0" ] && return
	echo "Error processing arguments:"
	for error in "${errors[@]}"; do
		echo "  $error"
	done
	exit 1
}

dep_check

argp "$@"

# If no files were provided, try to locate defaults
if [ ! "${FILES[0]}" ]; then
	for x in spoiler{s,}{,.log,.txt}; do
		[ -f "$x" ] && FILES+=( "$x" )
	done
fi

# Nothing could be found :O
if [ ! "${FILES[0]}" ]; then
	echo "No files were specified and none of the following exist in the current working directory."
	printf "  %s\n" spoiler{s,}{,.log,.txt}
	exit
fi

rlog "${FILES[0]}"
menu
