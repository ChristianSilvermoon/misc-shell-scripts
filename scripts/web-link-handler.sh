#!/bin/bash
# -----------------------------------------------
# Handle URLs using preferred ways
# -----------------------------------------------

shopt -s extglob

DEFAULT_BROWSER=firefox
# Since the script is to act as the real defualt web browser
# We need to not call xdg-open to avoid creating an infinite loop
#
# So we define our preferred browser here instead.


lFreeTube() {
	# Launch the newest FreeTube Instace
	# ...or the browser, if there is none.
	local appimage
	local appimage_date=0
	local ndate
	local x

	# Check AppImages; use newest creation date to decide which to use
	for x in $HOME/Applications/{F,f}ree{T,t}ube*.{A,a}pp{I,i}mage; do 
		[ -x "$x" ] || continue # It's an executable file or we skip

		ndate="$(stat -c %W "$x")" # Get File Birth in UNIX Time

		[ "$ndate" -gt "$appimage_date" ] && appimage_date="$ndate" && appimage="$x"
	done

	local flatpak
	local flatpak_date=0

	# Check Flatpaks
	for x in {/var/lib,${XDG_DATA_HOME:-$HOME/.local/share}}/flatpak/exports/bin/io.freetubeapp.FreeTube; do 
		[ -x "$x" ] || continue # Executable or ignore

		ndate="$(stat -L -c %W "$x")" # Get File Birth in UNIX Time
	
		[ "$ndate" -gt "$flatpak_date" ] && flatpak_date="$ndate" && flatpak="$x"
	done

	# Which to use?
	[ "$appimage_date" -gt "$flatpak_date" ] && freetube="$appimage" || freetube="$flatpak"

	printf "%-20s %28(%c)T\n  %s\n\n" \
		"AppImage" "$appimage_date" "$appimage" \
		"Flatpak" "$flatpak_date" "$flatpak"

	printf "Using %-20s\n\n" "$freetube"

	if [ -x "$freetube" ]; then
		exec "$freetube" "$1"
	else
		# No freetube? TO THE BROWSER WITH YOU!
		exec "$DEFAULT_BROWSER" "$1"
	fi
}


fp() {
	# Run Flatpak programs easy

	local app

	# Returns
	#  1 - Flatpak App not found
	#  2 - Flatpak is not in $PATH
	command -v flatpak 2>&1 >/dev/null || return 2

	for app in {${XDG_DATA_HOME:-$HOME/.local/share},/var/lib}/flatpak/exports/bin/*; do
		[ -x "$app" ] || continue # only try actual apps

		[[ ${app,,} =~ \.${1}$ ]] || continue

		shift
		exec "$app" "$@"
	done
	return 1

}

declare -A RULES=(
	["youtube"]="^http(s|())://(www\.|)youtu(be\.com|\.be).+*"
	["steam"]="^http(s|())://(store.steampowered.com/|steamcommunity.com/).+*"
)

# Test Rules until a match is found
for rule in "${!RULES[@]}"; do
	[[ $1 =~ ${RULES[$rule]} ]] && break
	rule=
done

echo "Rule: ${rule:=DEFAULT}"


[ "$WEB_LINK_HANDLER_DEBUG" ] && exit
[ "$2" = "--test" ] && exit

# Launch URL via RULE
case "${rule:=DEFAULT}" in

	# BLOCK_* is not to be opened.
	"BLOCK_"*)   notify-send "Web Link Handler - URL Blocked" "$1"; exit ;;
	"DEFAULT")   exec "$DEFAULT_BROWSER" "$1"          ;; # Just open it.
	"youtube")   lFreeTube "$1"                        ;; # YouTube Links in FreeTube

	"steam")
		# Steam Links in Steam
		STEAM_FRAME_FORCE_CLOSE=1 \
			exec \
			steam \
			-silent \
			-console \
			"steam://openurl/$1"		
	;;

	*)
		# If we have a rule but no special handler for it.
		notify-send "Web Link Handler - Undefined Rule" "You've defined \"$rule\", but not what to do!"
		exec "$DEFAULT_BROWSER" "$1"
	;;
esac
