#!/bin/bash

# Return Cursor to normal on sigint
trap 'tput cnorm; exit 130' SIGINT

# Trigger Modes
declare -A TMODES
declare -A CONS

TMODES=(

	["Rusty Trigger"]="feedback-raw 0 8 0 8 0 8 0 8 0 8"
	["Depth Resist"]="feedback-raw 0 1 2 3 4 5 6 7 8 0"
	["Depth Vibe"]="vibration-raw 0 1 2 3 4 5 6 7 8 8 100"
	["Heart"]="galloping 0 9 1 3 1"
	["Horse"]="galloping 0 9 2 3 2"
	["Vibe"]="machine 1 9 7 0 100 100"
	["Machine Gun"]="machine 1 9 7 7 9 1"
	["Machine Gun (Burst)"]="machine 1 9 7 0 18 12"
	["Gun Trigger"]="weapon 2 8 8"
	["Bow String"]="bow 1 8 8 1"
	["Gamecube (Strong)"]="feedback-raw 0 0 0 0 0 0 0 4 8 0"
	["Gamecube (Weak)"]="feedback-raw 0 0 0 0 0 0 0 2 4 0"

)

get-cons() {
	local x tcons=()
	mapfile -t tcons < <(dualsensectl -l 2>/dev/null)

	for x in "${!CONS[@]}"; do unset CONS["$x"]; done

	[ "${#tcons}" -gt 0 ] || return

	mapfile -t tcons < <( printf '%s\n' "${tcons[@]:1}" )
	mapfile -t tcons < <( printf '%s\n' "${tcons[@]# }" )


	for x in "${tcons[@]}"; do
		[[ $x =~ Bluetooth ]] && CONS[${x% *}]="Bluetooth" || CONS[${x% *}]="USB"
	done
}

menu() {
	local menu_index=${menu_index:-0}
	local menu_cursor=${menu_cursor:-$(echo -en "\e[32;1m>\e[0m")}
	local menu_indent=${menu_indent:-0}
	local menu_title=${menu_title:-Select An Option:}
	local index_hotkeys=( {0..9} {a..z} )
	local s i key nopt opts=()

	menu_indent=$( printf "%-${menu_indent}s" )

	# Handle Arguments
	for i in "$@"; do

		if [ ! "$nopt" ] && [[ $i =~ ^--$ ]]; then
			nopt=true

		elif [ ! "$nopt" ] && [[ $i =~ ^--title= ]]; then
			menu_title=${i#*=}

		elif [ ! "$nopt" ] && [[ $i =~ ^--cursor= ]]; then
			menu_cursor=${i#*=}

		elif [ ! "$nopt" ] && [[ $i =~ ^--index= ]]; then
			menu_index=${i#*=}
		else
			opts+=( "$i" )
		fi
	done

	tput civis >&2
	while true; do
		tput ed >&2
		[ "$menu_title" ] && echo "${menu_indent}${menu_title}" >&2

		# Draw menu
		for ((i=0; i < ${#opts[@]}; i++)); do
			s="$menu_indent"
			[ "$i" = "$menu_index" ] && s+="$menu_cursor" || s+="$( [ "$i" -lt "36" ] && printf "%s" "${index_hotkeys[$((i+1))]}" || printf " ")"

			echo " [$s] ${opts[$i]}" >&2
		done

		read -rsn1 key # get 1 character

		if [[ $key == $'\E' ]]; then
			read -rsn2 key # read 2 more chars
		fi

		case $key in
			'[A') key=up ;;
			'[B') key=down ;;
			'[D') key=left ;;
			'[C') key=right ;;
			$'\0a') key=return ;;
			*) key="${key,,}" ;;
		esac

		# What did we press?
		case "$key" in
			"up")
				[ "$menu_index" != "0" ] && : $((menu_index--)) || menu_index=$(( ${#opts[@]} -1))
				;;
			"down")
				[ "$menu_index" -lt "$(( ${#opts[@]} -1))" ] && : $((menu_index++)) || menu_index=0
				;;
			"left")
				menu_index=0
				;;
			"right")
				menu_index=$(( ${#opts[@]} -1 ))
				;;
			[1-9]|[a-z])
				[ "$(( 36#$key ))" -le "$(( ${#opts[@]} ))" ] && menu_index="$((36#$key - 1))"
				;;
			"return")
				[ ! -t 1 ] && echo "${opts[$menu_index]}" || menu_result="${opts[$menu_index]}"
				tput cnorm >&2

				[ "$menu_title" ] && echo -n $'\E'[A >&2
				for x in "${opts[@]}"; do
					echo -n $'\E'[A >&2
				done 
				tput ed >&2
				return
				;;
			*)
				:
				;;
		esac

		[ "$menu_title" ] && echo -n $'\E'[A >&2
		for x in "${opts[@]}"; do
			echo -n $'\E'[A >&2
		done 
	done
	tput cnorm >&2
}


while true; do
	get-cons

	if [ "${#CONS[@]}" = "0" ]; then
		# No Controllers
		con=$(menu --title="No Controllers Found" "Refresh Controllers" "Exit")

	elif [ "${#CONS[@]}" -ge "2" ]; then
		# Multiple Controllers
		con=$(menu --title="Select A Controller" "ALL" "${!CONS[@]}" "Refresh Controllers" "Exit")
	else
		# One Controller
		con=$(menu --title="Select A Controller" "${!CONS[@]}" "Refresh Controllers" "Exit")
	fi

	[ "$con" = "Refresh Controllers" ] && continue
	[ "$con" = "Exit" ] && exit

	while true; do
		main_opts=( "Player LEDs" "Adaptive Trigger Options" )
		[ "${CONS[$con]}" = "Bluetooth" ] && main_opts+=( "Power Off" )
		controller_opt=$(menu --title="Set Options for: $con ($(dualsensectl -d "$con" battery))" "${main_opts[@]}" "Back")

		[ "$con" = "ALL" ] && tcons=( "${!CONS[@]}" ) || tcons=( "$con" )

		case "$controller_opt" in
			"Player LEDs")
				leds=$(menu --title="Set Player LEDS for: $con ($(dualsensectl -d "$con" battery))" {0..5} "Cancel")
				[ "$leds" = "Cancel" ] && continue
				for x in "${tcons[@]}"; do
					dualsensectl -d "$x" player-leds $leds
					dualsensectl -d "$x" lightbar off
					dualsensectl -d "$x" lightbar on
				done
				;;
			"Adaptive Trigger Options")
				trigger=$(menu --title="Set option for which trigger of $con ($(dualsensectl -d "$con" battery))?" "Both" "Left" "Right" "Cancel" )
				[ "$trigger" = "Cancel" ] && continue
				tmode=$( menu --title="Set mode for $trigger Trigger$([ "$trigger" = "Both" ] && printf 's') of $con ($(dualsensectl -d "$con" battery))" "${!TMODES[@]}" "Normal" )
				
				[ "$tmode" = "Normal" ] && tmode="off" || tmode="${TMODES[$tmode]}"

				for x in "${tcons[@]}"; do
					dualsensectl -d "$x" trigger "${trigger,,}" $tmode
				done
				;;
			"Power Off")
				dualsensectl -d "$con" power-off
				break
				;;
			"Back") break ;;
		esac

	done
done
