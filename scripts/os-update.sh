#!/bin/bash
if [ "$UID" = "0" ]; then
	echo "Do NOT run as root."
	exit 1
fi
:|: # Make $ROWS & $COLUMNS work
shopt -s extglob
declare -A OS

parse-os-release() {
	local rel line value

	[ -f "/etc/os-release" ] || exit 2
	mapfile -t rel < /etc/os-release

	for line in "${rel[@]}"; do
		value="${line#*=}" #Isolate value
		value=${value#\"}; value=${value%\"} # Remove quotes
		OS[${line%%=*}]="$value"
	done
	
}

indent() {
	local amount=${1:-${INDENT_LEVEL:-3}}
	local x
	while read x; do
		printf -- "%${amount}s%s\n" "" "$x"
	done
}

header() {
	local string=$(printf -- "%s " "$1")
	local length=${COLUMNS:-$((${#string} + 2))}
	local bar=$(printf "%${length}s" "")
	bar=${bar// /=}

	printf -- "${bar}\n%s\n${bar}\n" "$1"
}

hr() {
	local length=${COLUMNS:-10}
	local bar=$(printf "%${length}s" "")
	bar=${bar// /-}
	printf -- "${bar}\n"
}

yorn() {
	local opt
	local default="${2:-n}"
	printf -- "%s" "$1"
	[ "${default,,}" = "y" ] &&
		echo -n " [Y*/N] " ||
		echo -n " [Y/N*] "
	read -r opt
	: ${opt:=$default}
	[ "${opt,,}" = "y" ] && return 0 || return 1
}

mkSnapshot() {
	echo "Checking for Timeshfit... "
	if command -v timeshift &>/dev/null; then
		echo "Found!"
	else
		echo "Unavailable."
		echo "   No automatic snapshot will be made."
		return 1
	fi

	echo -n "Reading Timeshift Snapshots... "
	snapshots=$(sudo timeshift --list-snapshots) && echo "Done!"
	echo -n "   Old Snapshot: "
	oldSnapshot=$(echo "${snapshots//+( )/ }" | grep "^[0-9] >" | grep "O Break Glass in case of Oopsie Whoopsie" | cut -d ' ' -f 3 | head -1)
	echo "${oldSnapshot:-none}"

	echo "Creating new timeshift Snapshot..."
	sudo timeshift --create --comments "Break Glass in case of Oopsie Whoopsie" 2>&1 | indent
	if [ "$oldSnapshot" ]; then
		echo "Removing Old Snapshot: $oldSnapshot"
		sudo timeshift --delete --snapshot "$oldSnapshot" 2>&1 | indent
	fi
}

header "OS Update Script"
echo "Authorize sudo (cache credentials)"
sudo -v

echo -n "Checking OS ID... "
parse-os-release
echo "${OS[ID]}"

case "${OS[ID]}" in
	"arch")
		yorn "Attempt Update?" || exit
		mkSnapshot
		if command -v yay &>/dev/null; then
			yay -Syu
		else
			sudo pacman -Syu
		fi
		;;
	"nobara")
		yorn "Attempt Update?" || exit
		mkSnapshot		
		nobara-updater cli
		;;
	"ubuntu")
		yorn "Attempt Update?" || exit
		mkSnapshot
		if command -v nala &>/dev/null; then
			sudo nala upgrade
		else
			sudo apt upgrade
		fi
		;;
	*)
		echo "This script doesn't know how to update OS ID: ${OS[ID]}"
		exit 3
		;;
esac

header "Universal Packages & Distro Agnostics"

if command -v pipx &>/dev/null; then
	if yorn "Update pipx packages including injections?"; then
		pipx upgrade-all --include-injected 2>&1 | indent
	fi
fi

if command -v flatpak &>/dev/null; then
	if [ "$(sudo flatpak remote-ls --updates | wc -l)" = "0" ]; then
		echo "Flatpak (System): Up To Date"
	else
		echo "Flatpak (System)"
		sudo flatpak update | indent
	fi

	if [ "$(flatpak --user remote-ls --updates | wc -l)" = "0" ]; then
		echo "Flatpak (User): Up To Date"
	else
		echo "Flatpak (User)"
		flatpak --user update | indent
	fi
fi

hr
