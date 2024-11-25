#!/bin/bash

if [ ! "$(command -v dualsensectl)" ]; then
	echo "No dualsensectl command." >&2
	exit 1
fi


COLORS=(
	"FF1131"
	"D13128"
	"A3521F"
	"747216"
	"46930D"
	"18B304"
	"10AF58"
	"08ABAB"
	"00A7FF"
	"00A7FF"
)

devs=()    # Array of DualSense IDS

get-cons() {
	local cons="$(dualsensectl -l)" # Get list of ids
	cons="${cons/#Devices:$'\n'}"   # Get rid of "devices" line
	cons="${cons/# }"               # Remove leading space
	cons="${cons/% *}"              # Remove trailing space

	mapfile -t devs < <(echo "$cons")
}

color-test() {
	local id="$1"
	local t=$(( ${#COLORS[@]} - 1))
	local x color R G B
	echo "Testing Colors"

	for ((x=$t; x >= 0; x--)); do
		color=${COLORS[$x]}
		echo "  Testing... $color"
		R=$(( 0x${color:0:2} ))
		G=$(( 0x${color:2:2} ))
		B=$(( 0x${color:4:2} ))

		for ((lvl=10; lvl >=0; lvl--)); do
			echo "    $lvl"
			dualsensectl -d "$id" lightbar "$R" "$G" "$B" "$((lvl * 20 + 55))"
			sleep .5s
		done
	done
	
}

updateLEDS() {
	local id="$1"
	local lvl="$(dualsensectl -d "$id" battery)"
	lvl=${lvl/% *}
	local color=$(( lvl / ${#COLORS[@]} ))
	color="${COLORS[$((color - 1 ))]}"

	echo "$id - $lvl"

	local R=$(( 0x${color:0:2} ))
	local G=$(( 0x${color:2:2} ))
	local B=$(( 0x${color:4:2} ))
	local A=$(( (lvl % 10) * 20 + 55 ))

	echo "  Choosing Color: $color @ $A Brightness"

	#dualsensectl -d "$id" lightbar on
	dualsensectl -d "$id" lightbar "$R" "$G" "$B" "$A"

}

updateLEDSold() {
	local id="$1"
	local lvl="$(dualsensectl -d "$id" battery)"
	lvl=${lvl/% *}

	echo "$id - $lvl"

	if [ "$lvl" -gt "75" ]; then
		# Blue
		dualsensectl -d "$id" lightbar "00" "167" "255"
	elif [ "$lvl" -gt "50" ]; then
		# Green
		dualsensectl -d "$id" lightbar "00" "255" "25"
	elif [ "$lvl" -gt "25" ]; then
		# Orange
		dualsensectl -d "$id" lightbar "255" "100" "0"
	else
		# Red
		dualsensectl -d "$id" lightbar "255" "0" "34"
	fi 
}

get-cons

echo "Devices"
for dev in "${devs[@]}"; do
	if [ "$1" = "--color-test" ]; then
		color-test "$dev"
	else
		updateLEDS "$dev"
	fi
done
