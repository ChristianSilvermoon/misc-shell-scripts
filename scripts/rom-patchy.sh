#!/bin/bash
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/rom-patchy"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/rom-patchy"

# Dependency Check
command -v crc32   >/dev/null 2>&1 || MISSING_DEPS+=("crc32"   "Needed for checking ROM checksums")
command -v flips   >/dev/null 2>&1 || MISSING_DEPS+=("flips"   "Floating IPS; needed for BPS Patching")
command -v xdelta3 >/dev/null 2>&1 || MISSING_DEPS+=("xdelta3" "Needed for xdelta Patching and Patch Checking")
command -v find    >/dev/null 2>&1 || MISSING_DEPS+=("find"    "Needed for locating files on disk.")

if [ ! "$(command -v hexdump)" ]&&[ ! "$(command -v od)" ]; then
	command -v hexdump >/dev/null 2>&1 && MISSING_DEPS+=("hexdump" "Needed for reading data from Patch files. Provide this or \"od\"")
	command -v od      >/dev/null 2>&1 && MISSING_DEPS+=("od"      "Needed for reading data from Patch files. Provide this or \"hexdump\"")
fi

if [ "${#MISSING_DEPS[@]}" != "0" ]; then
	echo "The following dependencies are not in \$PATH."
	printf "  %-28s %s\n" "${MISSING_DEPS[@]}" 
	exit 1
fi


if [ ! -d "$CACHE" ]; then
	mkdir -p "$CACHE"
fi

# Are we on a Terminal?
[ -t 1 ] && CLI=1 || CLI=0
# Used to know if we should attempt displaying Desktop Notifications.

gnotify() {
	if [ "$CLI" = "0" ] && [ "$DISPLAY" ]; then
		notify-send -t 6000 "Rom Patchy~" "$1"
	fi
}

# Config
if [ -f "$CONFIG/dirs.conf" ]; then
	# Load ConfiG
	mapfile -t tROMDIRS < "$CONFIG/dirs.conf"
	ROMDIRS=()

	# Interperet some special characters in some cases
	for ((i = 0; i < ${#tROMDIRS[@]}; i++)); do
		if [ "${tROMDIRS[$i]}" = "" ]; then
			# Skip Blank Lines
			continue
		elif [ "${tROMDIRS[$i]:0:1}" = "#" ]; then
			# Skip lines starting with #
			continue
		elif [ "${tROMDIRS[$i]:0:1}" = "~" ]; then
			ROMDIRS+=( "${HOME}${tROMDIRS[$i]:1}" )
		else
			ROMDIRS+=( "${tROMDIRS[$i]}" )
		fi
	done

else
	# Assume home directory and removable media directories
	ROMDIRS=( "$HOME" "/media/$USER" )
	printf -- "%s\n" "${ROMDIRS[@]}" > "$CONFIG/dirs.conf"
fi

ROMS=()

# Loading the full ROM List can be an expensive operation
# Let's only do this when necessary.
loadROMS() {
	mapfile -t ROMS < <(
		for x in "${ROMDIRS[@]}"; do
		        find "$x" -type f \( \
					-iname "*.nds" -o \
					-iname "*.n64" -o \
					-iname "*.z64" -o \
					-iname "*.gba" -o \
					-iname "*.gbc" -o \
					-iname "*.gb" -o \
					-iname "*.sfc" -o \
					-iname "*.smc" -o \
					-iname "*.nes" -o \
					-iname "*.gen" -o \
					-iname "*.gg" -o \
					-iname "*.vb" -o \
					-iname "*.fds" \
				 \)
		done
	)
}

bpsRead() {
	local file="$1"
	local mode="$2"
	local src targ patch

	local len=$(wc -c < "$file")

	# Note: BPS Patches store crc32 checksums as uint32
	# That means they're 4 bytes
	# Located at the end of the file
	# in order of source (-12), target (-8), patch (-4)
	#
	# The Patch cheksum is the checksum of
	# all data before the last 4 bytes

	echo "Reading BPS Patch File..." 1>&2
	# For versatility, we can use either od OR hexdump
	if [ "$(command -v od)" ]; then
		# Extract checksums to variable
		src=$(od --endian=little -An -t x1 -j$(( len - 12 )) -N4 < "$file")
		targ=$(od --endian=little -An -t x1 -j$(( len - 8 )) -N4 < "$file")
		patch=$(od --endian=little -An -t x1 -j$(( len - 4 )) -N4 < "$file")

		# Remove Spaces
		src=${src// }
		targ=${targ// }
		patch=${patch// }

	elif [ "$(command -v hexdump)" ]; then
		# Extract checksums to variable
		src=$(hexdump -e '16/1 "%02x"' -s $(( len - 12 )) -n 4 "$file")
		targ=$(hexdump -e '16/1 "%02x"' -s $(( len - 8 )) -n 4 "$file")
		patch=$(hexdump -e '16/1 "%02x"' -s $(( len - 4 )) -n 4 "$file")
	fi
	
	# Re-order bytes to match the output of crc32
	src=${src:6:2}${src:4:2}${src:2:2}${src:0:2}
	targ=${targ:6:2}${targ:4:2}${targ:2:2}${targ:0:2}
	patch=${patch:6:2}${patch:4:2}${patch:2:2}${patch:0:2}

	echo "  embeded crc32 checksums" 1>&2
	printf "    %-10s : %s\n" "Source" "$src" "Target" "$targ" "Patch" "$patch" 1>&2
	echo "" 1>&2

	case $mode in
		"")
			printf "%s\n" "$src" "$targ" "$patch"
			;;
		"human")
			printf "%-15s %s\n" "Source" "$src"
			printf "%-15s %s\n" "Target" "$targ"
			printf "%-15s %s\n" "Patch" "$patch"
			;;
		"src")
			echo "$src"
			;;
		"target")
			echo "$targ"
			;;
		"patch")
			echo "$patch"
			;;
		*)
			return 1
			;;
	esac

}

idPatchType() {
	local file="$1"

	# Magic numbers for Identifying file types
	local -A magic=(
		["bps"]="42505331"
		["ips"]="5041544348"
		["xdelta"]="d6c3c400"
	)

	local test=$(hexdump -e '16/1 "%02x"' -n 5 "$file")
	test="${test,,}"

	if [ "${test:0:8}" = "${magic[bps]}" ]; then
		echo "bps"
	elif [ "${test:0:10}" = "${magic[ips]}" ]; then
		echo "ips"
	elif [ "${test:0:8}" = "${magic[xdelta]}" ]; then
		echo "xdelta"
	else
		echo "unknown"
	fi
}

patch_bps() {
	local patch="$1"
	local rom="$2"
	local out="${patch%\.*}.${rom##*\.}"

	echo "flips --apply \"$patch\" \"$rom\" \"$out\""
	if [ "$(command -v flips)" ]; then
		if [ ! -f "$out" ]; then
			flips --apply "$patch" "$rom" "$out"
			gnotify "Patched $rom"
		else

			gnotify  "Refusing to overwite $out"
			echo "Refusing to overwite $out"
		fi
	else
		echo "flips is not in \$PATH"
		exit 1
	fi
	echo "" 1>&2
}

patch_xdelta() {
	local patch="$1"
	local rom="$2"
	local out="${patch%\.*}.${rom##*\.}"

	echo "xdelta3 -d -s \"$rom\" \"$patch\" \"$out\""


	if [ "$(command -v xdelta3)" ]; then
		if [ ! -f "$out" ]; then
			xdelta3 -d -s "$rom" "$patch" "$out"
			gnotify "Patched $rom"
		else

			gnotify  "Refusing to overwite $out"
			echo "Refusing to overwite $out"
		fi
	else
		echo "xdelta3 is not in \$PATH"
		exit 1
	fi
	echo "" 1>&2
}

find_xdelta() {
	local patch="$1"
	local rom target tHistory
	local -A xdeltaHistory
	#===================================================================================
	# Notes:
	# - I cannot figure out how on earth to get a usable checksum from xdelta patches
	# - xdelta3 DOES have a test command:
	#
	#      xdelta3 -d -J -s $rom $patch
	#
	# - We can still use the test command for a slow search
	# - Probably most likely the same ROM will be patched over a bunch of random ones
	#   - People are more likely to play mods of the same game they love vs random ones
	#
	# - We can store a history of previously successfully matched ROMs to check *first*
	#   - This means using patches targeting the same ROM *should* patch faster
	#   - But is not as efficient as checksum caching
	#===================================================================================

	# Note: Load History
	if [ -f "$CACHE/xdelta-match-history" ]; then
		mapfile -t tHistory < "$CACHE/xdelta-match-history"
		for rom in "${tHistory[@]}"; do
			# Convert them into an associative array to dodge storing duplicates
			[ "$rom" ] && xdeltaHistory[$rom]="0"
		done

		unset tHistory # Just in case
	fi

	# History Check
	echo -en "Searching for ROM for \"${PATCHFILE##*\/}\" in xdelta match history first...\n" 1>&2

	for rom in "${!xdeltaHistory[@]}"; do
		xdeltaHistory[$rom]="1" # If we get past the history check we know to skip checking this one in the Filesystem Search.

		# If the xdelta3 check passes, it is the correct ROM
		xdelta3 -d -J -s "$rom" "$patch" &>/dev/null && target="$rom" && break	
	done

	if [ "$target" ]; then
		echo "  Found ROM in history" 1>&2
		echo "    $target" 1>&2

		echo "$target"
		return 0
	fi

	gnotify "ROM for \"${PATCHFILE##*\/}\" not in history, searching disk...\n\nThis could take some time!"
	echo -e "\nSearching for ROM that xdelta patch works on (${PATCHFILE##*\/})..." 1>&2
	echo "  Scanning ROM Directories for file." 1>&2

	# Load ROM List
	echo -n "    Loading ROM List..." 1>&2
	[ "${#ROMS[@]}" = "0" ] && loadROMS
	echo " complete!" 1>&2

	echo -n "    Scanning files on disk..." 1>&2
	for rom in "${ROMS[@]}"; do

		[ "${xdeltaHistory[$rom]}" = "1" ] && continue # Skip check if we checked it in history

		# If the xdelta3 check passes, it is the correct ROM
		xdelta3 -d -J -s "$rom" "$patch" &>/dev/null && target="$rom" && break

	done
	echo " Complete!" 1>&2

	[ "$target" ] && echo "      Match was found!" 1>&2 || echo "      Match not found..." 1>&2

	xdeltaHistory[$target]="0"

	# Write history to disk
	printf "%s\n" "${!xdeltaHistory[@]}" > "$CACHE/xdelta-match-history"

	# Return Target ROM
	if [ "$target" ]; then
		echo "      Found ROM on Disk." 1>&2
		echo "        $target" 1>&2

		echo "$target"
		return 0
	fi

	return 1
}

find_crc32() {
	# Find Target ROM with the correct CRC32
	local csum="$1"
	local rom target

	local entry tcache hash file targetFile
	local -A cache

	echo "Searching for ROM with crc32 checksum ($csum)..." 1>&2

	# Attempt to find crc32 in cache...
	if [ -f "$CACHE/rom-crc32" ]; then
		# Load Cache to associative Array
		echo "  Reading rom-crc32 Cache..." 1>&2
		mapfile -t tcache < "$CACHE/rom-crc32"
		for entry in "${tcache[@]}"; do
			cache[${entry%%=*}]="${entry#*=}"
		done

		# Determine if File exists & Matches cached hash
		targetFile="${cache[$csum]}"
		if [ -f "$targetFile" ] && [ "$(crc32 "$targetFile")" = "$csum" ]; then
			# Return file if it exists and Matches
			echo "    Located file in cache!" 1>&2
			target="$targetFile"
		else
			# The file either didn't exist or didn't match and thus the cache is stale
			echo "    File not found in cache." 1>&2
			unset cache["$csum"]
		fi
	fi
	echo "" 1>&2

	# If we found the ROM in cache, just return that
	[ "$target" ] && echo "$target" && return 0

	# If not...
	gnotify "ROM for ${PATCHFILE##*\/} not in cache, searching disk\n\nThis could take some time!" &>/dev/null
	echo "  Scanning ROM Directories for file." 1>&2

	# Load ROM List
	echo -n "    Loading ROM List..." 1>&2
	[ "${#ROMS[@]}" = "0" ] && loadROMS
	echo " complete!" 1>&2

	echo -n "    Scanning files on disk..." 1>&2
	for rom in "${ROMS[@]}"; do
		entry=$(crc32 "$rom")
		cache[$entry]="$rom" # Update Cache with checksum

		[ "$entry" = "$csum" ] && target="$rom" && break
	done
	echo " Complete!" 1>&2

	[ "$target" ] && echo "      Match was found!" 1>&2 || echo "      Match not found..." 1>&2

	# Write Updated Cache back to disk
	for hash in "${!cache[@]}"; do
		printf "%s=%s\n" "$hash" "${cache[$hash]}"
	done > "$CACHE/rom-crc32"
	echo "    Updated rom-crc32 cache written to disk!" 1>&2
	echo "" 1>&2

	# Return Target ROM
	[ "$target" ] && echo "$target" || return 1
}

help_msg() {
	echo -e "\e[32;1m${0##*/}\e[37m - Fwiendly ROM Patchy scwipt UwU\e[0m\n"
	printf "  %s\n" \
		"Finds and patches the correct ROM for you from your collection."

	echo -e "\n\e[1mUSAGE\e[0m"
	echo -e "  ${0##*/} [OPTION] [PATCH FILE]\n"

	echo -e "\e[1mOPTIONS\e[0m"
	printf "  %-28s %s\n" \
		"--add-dir, +d <dir>" "Add directory to search"    \
		"--rm-dir, -d <dir>"  "Remove directory to search" \
		"--clear-cache, -c"   "Delete CACHE directory."    \
		"--help, -?" "Display this message"

	echo -e "\n\e[1mPATCH FORMATS\e[0m"

	printf "  %-8s %s\n" \
		"bps"    "Common Patch Format, best supported!" \
		"xdelta" "Supported, but not able to search as efficiently." \
		"ips"    "Unsupported. No way to correctly determine intended target ROM :("

}


argHandler() {
	local a
	local narg
	local subarg
	local old_config new_config

	for a in "$@"; do
		case "$subarg" in
			"+d")
				echo "Add Directory: $a"
				[ -d "$a" ] && echo "$a" >> "$CONFIG/dirs.conf" && subarg= && exit
				echo "No such directory: $a"
				exit 1
				;;
			"-d")
				local line
				echo "Removing Directory: $a"
				mapfile -t old_config < "$CONFIG/dirs.conf"
				for line in "${old_config[@]}"; do
					[ "$line" = "$a" ] && continue || new_config+=("$line")
				done
				printf -- "%s\n" "${new_config[@]}" > "$CONFIG/dirs.conf"

				echo "You may want to --clear-cache to remove old matches so they aren't used anymore."
				# TO DO: should scrub cache of removed directory automatically
				subarg=
				exit
				;;
			*) subarg= ;;
		esac

		if [ "$narg" ]; then
			PATCHFILE="$a"
			TYPE=$(idPatchType "$a")
			continue
		fi

		case "$a" in
			"--")
				narg=1
				;;
			"--clear-cache"|"-c")
				echo "Clear Cache..."
				[ "$CACHE" ] || exit 2
				[ -d "$CACHE" ] && rm -vrf "$CACHE"
				exit
				;;
			"--add-dir"|"+d") subarg="+d" ;;
			"--rm-dir"|"-d")  subarg="-d" ;;
			"--help"|"-?")
				help_msg
				exit
				;;
			*)
				if [ -f "$a" ]; then 
					PATCHFILE="$a"
					TYPE=$(idPatchType "$a")
				else

					echo "Invalid Argument: $a"
					exit 1
				fi		
				;;
		esac
	done
}


argHandler "$@"


case "$TYPE" in

	"bps")
		srcHASH=$(bpsRead "$PATCHFILE" "src")
		if srcROM="$(find_crc32 "$srcHASH" )"; then
			patch_bps "$PATCHFILE" "$srcROM"
		else
			gnotify "Couldn't a ROM for $TYPE patch \"${1##*\/}\" with matching crc32 checksum of $srcHASH"
			echo "Couldn't a ROM for $TYPE patch \"${1##*\/}\" with matching crc32 checksum of $srcHASH"
			exit 1
		fi
		;;

	"ips")
		# TODO: Prompt for Target CRC32 Checksum
		#  IPS files do not contain a hash themselves
		#  But many places they are hosted do specify a target Hash
		#  We could ask the user for it!
		gnotify "$1 is an IPS file.\n\nIPS Patches are not supported."
		echo "ips patches do not contain a checksum that can be used to identify the correct ROM."
		echo ""
		echo "AKA ips files are unsupported"
		exit 1
		;;

	"xdelta")
		echo "xdelta support is only experimental."

		if srcROM=$(find_xdelta "$PATCHFILE"); then
			patch_xdelta "$PATCHFILE" "$srcROM"
		else
			gnotify "Couldn't find a ROM for $TYPE patch \"${1##*\/}\": $PATCHFILE"
			echo "Couldn't find a ROM for $TYPE patch \"${1##*\/}\": $PATCHFILE"
			exit 1
		fi

		exit
		;;

	*)
		gnotify "$1\n\nisn't a supported patch file!"
		echo "$1 is not a supported patch file"
		echo ""
		echo "No support for finding $TYPE Targets"
		exit 1
		;;
esac
