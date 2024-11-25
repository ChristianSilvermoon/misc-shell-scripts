#!/bin/bash
TARGET_FILE="$(realpath "$1")"
TARGET_DIR="${TARGET_FILE%/*}"
WD="$PWD"

# If unrar is missing, but bsdtar is present, we can substitute it
if [ ! "$(command -v unrar)" ] && [ "$(command -v bsdtar)" ] ; then 
	echo -e "\e[2;3mNote: Using \"bsdtar\" in place of \"unrar\"\e[0m"
	unrar() {
		# wrapped bsdtar 
		if [ "$1" = "x" ]; then
			bsdtar -xf "$2"
		fi
	}

elif [ ! "$(command -v unrar)" ] && [ ! "$(command -v bsdtar)" ]; then
	echo "Neither \"unrar\" or \"bsdtar\" are present in \$PATH" 1>&2
	echo "There is no suitable utility available with which to e xtract a RAR archive" 1>&2
	exit
fi

help_msg() {
	echo -e "\e[32;1m${0##*/}\e[39m - Convert RAR Archive to 7z Archive"
	echo -e "\nUSAGE\e[0m"
	echo "  ${0##*/} <RAR Archive|Option> [7z args...]"

	echo -e "\n\e[1mOPTIONS\e[0m"
	printf "  %-28s %s\n" \
		"--help, -?" "Display this message"
}

for x in "$@"; do
	if [ "$x" = "--help" ] || [ "$x" = "-?" ]; then
		help_msg
		exit
	fi
done

shift

argsFor7z=( "$@" )

cleanup() {
	# Kill Archivers
	kill %unrar >/dev/null 2>&1
	kill %bsdtar >/dev/null 2>&1
	kill %7z    >/dev/null 2>&1

	# Delete temporary Directory
	[ "$TDR" ]             && # Verify not blank variable
	[ -d "$TDR" ]          && # Verify it is a directory
	[[ $TDR =~ \.rar27z ]] && # Verify that it actually contains the intended file name
		rm -rf "$TDR"         # Actually delete the directory
}

[ ! -f "$TARGET_FILE" ] && echo "No such file: $TARGET_FILE" && exit
NEW="${TARGET_FILE%.rar}.7z"
NEW="${WD:=.}/${NEW##*/}"
[ -f "$NEW" ] && echo "Refusing to overwrite existing file: $NEW" && exit 

if ! TDR=$(mktemp -dp "$WD" .rar27z-XXXXXXXXXX); then
	echo "Unable to create temporary directory."
	exit 1
fi

echo "TDR: $TDR"

trap cleanup EXIT SIGINT SIGTERM SIGKILL 

cd "$TDR"

echo "Old: $TARGET_FILE"
echo "NEW: $NEW"
unrar x "$TARGET_FILE" 				   || exit 2
7z "${argsFor7z[@]}" a "$NEW" ./* ./.* || exit 3
cd "$WD"

#mktemp -dp ./ .rar27z-XXXXXXXXXX


#mkdir .rar27z
