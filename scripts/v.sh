#!/bin/bash
shopt -s extglob

help_msg() {
	echo -e "\e[32;1m${0##*/}\e[37m - \e[33mView Files or File Info Quickly\e[0m" 
}

case "$1" in
	"--help"|"-?")
		help_msg
		exit
		;;
	*)

		[ ! -e "$1" ] && echo "No such file or directory." 1>&2 && exit 1

		# List directories
		if [ -d "$1" ]; then
			if command -v lsd &>/dev/null; then
				lsd -glha --hyperlink=auto --header --blocks permission,links,size,user,group,date,git,name --date +"%b %d %y, %I:%M:%S" "$1"
			elif command -v exa &>/dev/null; then
				exa --icons --git -glha "$1"
			else
				ls -lha "$1"
			fi
			exit
		fi

		# Special mimetype handling
		case "$(mimetype -b "$1")" in
			application/x-compressed-tar)
				file -b "$1"
				tar -tzvf "$1" | less -F
				exit
				;;
			application/x-xz-compressed-tar)
				file -b "$1"
				tar -tJvf "$1" | less -F
				exit
				;;
			application/zip)
				file -b "$1"
				unzip -l "$1" | less -F
				exit
				;;
			application/x-7z-compressed)
				file -b "$1"
				command -v 7z &>/dev/null && 7z l "$1" | less -F && exit
				echo "7z not available"
				exit 1
				;;
			application/vnd.rar)
				file -b "$1"
				command -v bsdtar &>/dev/null && bsdtar -tvf "$1" | less -F && exit
				echo "bsdtar not available"
				exit 1
				;;
			application/vnd.debian.binary-package)
				command -v dpkg-deb &>/dev/null && dpkg-deb -I "$1" | sed 's/  //g; s/^ //g' | less -F && exit
				echo "dpkg-deb not available"
				exit 1
				;;
			application/x-rpm)
				command -v rpm &>/dev/null && rpm -qip "$1" | less -F && exit
				echo "rpm not available"
				exit 1
				;;
			application/vnd.oasis.opendocument.text)
				if command -v pandoc &>/dev/null && command -v bat; then
					pandoc -t markdown -s "$1" -s -o - | bat --file-name="$1" --language=markdown
					exit
				else
					echo "pandoc and bat are unavailable."
				fi
				exit 1
				;;
			image/*)
				[ "$TERMINOLOGY" = "1" ] && tycat "$1" && exit
				[ "$TERM" = "xterm-kitty" ] && kitten icat --align left "$1" && exit
				command -v chafa &>/dev/null && chafa "$1" && exit

				;;
			video/*)
				[ "$TERMINOLOGY" = "1" ] && tycat "$1"
				command -v ffprobe &>/dev/null && ffprobe -hide_banner "$1"
				;;
			audio/*)
				[ "$TERMINOLOGY" = "1" ] && tycat "$1"
				command -v ffprobe &>/dev/null && ffprobe -hide_banner "$1"
				;;	
			application/x-shellscript|text/*)
				command -v bat &>/dev/null && bat "$1" && exit
				cat "$1"
				exit
				;;
			application/x-executable)
				file -b "$1"
				ldd "$1"
				exit
				;;
			*)
				file -b "$1"
				exit 1
				;;
		esac

		exit
		;;
esac
