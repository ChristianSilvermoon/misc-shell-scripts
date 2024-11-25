#!/bin/bash
# ps5triggers
#
# This script is intended as a cozy way to manipulate
# the behavior of the DualSense's triggers using
# 'dualsensectl'
#
# It can either set behavior and exit
# 
# OR
#
# Wrap another command, and return the trigger behavior
# to default when the command exists.
#
# See "ps5triggers --help" for usage details.
#
# This is required:
#   https://github.com/nowrep/dualsensectl
#
trap 'clean-exit' EXIT INT TERM 


clean-exit() {
	trap - EXIT INT TERM
	if [ "${#launchCMD[@]}" = "0" ]; then
		# If no launch command, do not reset triggers
		exit
	else
		# Reset triggers on exit
		dualsensectl trigger both off
		exit
	fi
}

# Trigger Modes
#  You can define any additional modes you like just
#  by adding them to this Associative Array
#
#  For info on what to put as the follow up arguments See:
#    https://github.com/nowrep/dualsensectl/wiki/Usage-Examples#user-content-Trigger
declare -A TMODES=(
	["normal"]="off"
	["rusty-trigger"]="feedback-raw 0 8 0 8 0 8 0 8 0 8"
	["depth-resist"]="feedback-raw 0 1 2 3 4 5 6 7 8 0"
	["depth-vibe"]="vibration-raw 0 1 2 3 4 5 6 7 8 8 100"
	["heart"]="galloping 0 9 1 3 1"
	["horse"]="galloping 0 9 2 3 2"
	["vibe"]="machine 1 9 7 0 100 100"
	["machine-gun"]="machine 1 9 7 7 9 1"
	["machine-gun-burst"]="machine 1 9 7 0 18 12"
	["gun"]="weapon 2 8 8"
	["bow"]="bow 1 8 8 1"
	["gamecube-strong"]="feedback-raw 0 0 0 0 0 0 0 4 8 0"
	["gamecube-weak"]="feedback-raw 0 0 0 0 0 0 0 2 4 0"
)

# Mode aliases
TMODES[gcn]="${TMODES[gamecube-strong]}"
TMODES[gcn-strong]="${TMODES[gamecube-strong]}"
TMODES[gcn-weak]="${TMODES[gamecube-weak]}"


help_msg() {
	local c="${00##*/}"
	echo -e "\e[32;1m${c}\e[39m - \e[36mControl Dualsense Triggers\e[0m"

	echo -e "\n\e[1mUSAGE\e[0m"
	printf -- "  %s\n    %s\n\n" \
		"Set & Exit" "${c} <mode>" \
		"Wrap Another Program" "${c} <mode> [command]"

	echo -e "\e[1mOPTIONS\e[0m"
	printf "  %-28s %s\n" \
		"l.<mode>"   "Set the left trigger's mode" \
		"r.<mode>"   "Set the right trigger's mode" \
		"b.<mode>"   "Set the mode of both triggers" \
		"--"         "Parse all future ARGS as a launch command" \
		"--help, -?" "Display this message"

	echo -e "\n\e[1mMODES\e[0m"
	printf "  %s\n" "${!TMODES[@]}"
}

if ! command -v dualsensectl &>/dev/null; then
	echo "dualsensectl is unavailable." 1>&2
	echo -e "\nSee:\n  https://github.com/nowrep/dualsensectl" 1>&2
	exit 1
fi

for x in "${@}"; do
	# Handle -- disabling arguments
	[ "$narg" ] && launchCMD+=("$X") && continue

	case "$x" in
		--)
			narg=true
		;;
		"--help")
			help_msg
			exit
		;;
		l.*)
			mode="${x#*.}"
			if [ "${TMODES[$mode]}" ]; then
				dualsensectl trigger left ${TMODES[$mode]}
			else
				echo "Invalid left trigger mode: $mode"
			fi
		;;
		r.*)
			mode="${x#*.}"
			if [ "${TMODES[$mode]}" ]; then
				dualsensectl trigger right ${TMODES[$mode]}
			else
				echo "Invalid right trigger mode: $mode"
			fi
		;;

		b.*)
			mode="${x#*.}"
			if [ "${TMODES[$mode]}" ]; then
				dualsensectl trigger both ${TMODES[$mode]}
			else
				echo "Invalid right trigger mode: $mode"
			fi	
		;;

		*) launchCMD+=("$x") ;;
	esac

done

"${launchCMD[@]}"
