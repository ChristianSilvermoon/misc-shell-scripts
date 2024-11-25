#!/bin/bash


# Array for Video Resolution Shorthand
declare -gA RES
RES["144"]="256x144"
RES["192"]="256x192"
RES["224"]="256x224"
RES["240"]="320x240"
RES["480"]="640x480"
RES["720"]="1280x720"
RES["1080"]="1920x1080"
RES["1440"]="2560x1440"
RES["2160"]="3840x2160"

# Supported Resolutions (Aliases)
RES["DOGSHIT"]="${RES["144"]}" # Wow, this is awful!
RES["POTATO"]="${RES["240"]}"  # Very Low Quality
RES["SD"]="${RES["480"]}"      # Standard Definition
RES["HD"]="${RES["720"]}"      # High Definition
RES["FHD"]="${RES["1080"]}"    # Full High Definition
RES["4K"]="${RES["2160"]}"     # 4K
RES["UHD"]="${RES["2160"]}"    # Ultra HD (AKA 4K)
RES["2K"]="${RES["1440"]}"     # QuadHD, AKA @K
RES["QHD"]="${RES["1440"]}"    # QuadHD, AKA @K
RES["NDS"]="${RES["192"]}"     # Nintendo DS

wait-spinner() {
	if [ "$1" = "bg" ]; then
		local delay="0.1"
		tput sc
		tput civis
		while true; do
			echo -ne "\e[1;31m|\e[22;37m"
			sleep $delay
			tput cub1
			echo -ne "\e[1;32m/\e[22;37m"
			sleep $delay
			tput cub1
			echo -ne "\e[1;33m—\e[22;37m"
			sleep $delay
			tput cub1
			echo -ne "\e[1;34m"
			echo -n '\'
			echo -ne "\e[22;37m"
			tput cub1
			sleep $delay
		done
	elif [ "$1" = "q" ]; then
		kill %wait-spinner 2>&1 > /dev/null
		tput rc
		tput el
		tput cnorm
	else
		wait-spinner bg &
	fi
}

trap 'exit_trap' SIGINT
exit_trap() {
	wait-spinner q 2>&1 > /dev/null
	tput cnorm
	echo ""
	exit
}


rmsilence() {
	# Remove Silence from start and end of audio
	echo -e "\e[2mffmpeg -i \"$1\" -af \"silenceremove=start_periods=1:start_duration=1:start_threshold=-60dB:detection=peak,aformat=dblp,areverse,silenceremove=start_periods=1:start_duration=1:start_threshold=-60dB:detection=peak,aformat=dblp,areverse\" \"$2\"\e[22m\n" 1>&2
	ffmpeg -hide_banner -i "$1" -af "silenceremove=start_periods=1:start_duration=1:start_threshold=-60dB:detection=peak,aformat=dblp,areverse,silenceremove=start_periods=1:start_duration=1:start_threshold=-60dB:detection=peak,aformat=dblp,areverse" "$2"

}

3dsify() {
	#local TARGET_FPS TARGET_W TARGET_H TARGET_VCODEC TARGET_ACODEC
	: ${TARGET_FPS:=24}            # Framerate MUST be no greater than 24
	: ${TARGET_W:=256}             # Max Width: 256
	: ${TARGET_H:=144}             # Max Height: 144
	: ${TARGET_VCODEC:=mpeg2video} # h264; h265; mpeg4; (Motion Jpeg?)
	: ${TARGET_ACODEC:=mp3}        # mp1; mp2; ac3; aac; libvorbis; pcm
	: ${TARGET_CRF:=25}            # 0-64; recommended 25; How much quality to sacrifice for size reduction

	# Note: Add Subtitle Handling
	#  3DS CAnnot display Subtitle Tracks
	#  They must be burned in at a reasonable scale

	local probe_output=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of default=nw=1 "$1")

	local WIDTH HEIGHT FPS
	WIDTH=$(echo "$probe_output" | grep "width" | cut -d'=' -f 2-)
	HEIGHT=$(echo "$probe_output" | grep "height" | cut -d'=' -f 2-)
	FPS=$(echo "$probe_output" | grep "r_frame_rate" | cut -d'=' -f 2- | cut -d '/' -f 1)
	
	if [ "$FPS" -gt "$TARGET_FPS" ]; then
		# reduce fps if too high
		local fps_filter="${TARGET_FPS}"
	else
		# keep source fps
		local fps_filter="${FPS}"
	fi

	if [ "$HEIGHT" -gt "$TARGET_H" ] || [ "$WIDTH" -gt "$TARGET_W" ]; then
		# rescale if larger than target resolution
		local rescale="${TARGET_W}x${TARGET_H}"
	else
		# keep source resolution
		local rescale="${WIDTH}x${HEIGHT}"
	fi

	ffmpeg -i "$1" \
		-map 0:v:0 \
		-map 0:a:0 \
		-filter:v fps=${FPS_FILTER} \
		-vf scale=${rescale} \
		-c:v ${TARGET_VCODEC} \
		-c:a ${TARGET_ACODEC} \
		-preset slow \
		-crf ${TARGET_CRF} \
		"$2"
}

maxscale() {
	local TARGET_RES="${RES[${1^^}]}"

	if [ "$TARGET_RES" ]; then
		# Match From Target RaSolution Array
		local TARGET_W="${TARGET_RES//x*}"
		local TARGET_H="${TARGET_RES//*x}"
	else
		# Manually specifiy resolution?
		if
			[[ ${1//x*} =~ ^[0-9]+$ ]] &&
			[[ ${1//*x} =~ ^[0-9]+$ ]]
		then
			TARGET_RES="$1"
			TARGET_W="${1//x*}"
			TARGET_H="${1//*x}"

			if [ "$TARGET_H" -lt 1 ] || [ "$TARGET_W" -lt 1 ]; then
				echo -e "\e[31;1mCustom Resolution Too Small\e[22;37m" 1>&2
				exit 1
			fi
		fi
	fi

	echo "TARGET_RES : $TARGET_RES"
	echo "TARGET_H   : $TARGET_H"
	echo "TARGET_W   : $TARGET_W"

	if [ ! "$TARGET_RES" ]; then
		echo -e "\e[31;1mInvalid Resolution: $1\e[22;37m"
		exit 1
	fi

	local probe_output=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of default=nw=1 "$2")
	local WIDTH=$(echo "$probe_output" | grep "width" | cut -d'=' -f 2-)
	local HEIGHT=$(echo "$probe_output" | grep "height" | cut -d'=' -f 2-)

	echo "INPUT: $2"
	echo "OUTPUT: $3"

	# Rescale If Needed
	if [ "$HEIGHT" -gt "$TARGET_H" ] || [ "$WIDTH" -gt "$TARGET_W" ]; then
		# Rescale if larger than target resolution
		echo -n "Downscaling ${WIDTH}x${HEIGHT} to ${TARGET_W}x${TARGET_H}... "
		wait-spinner
		local RESCALE="${TARGET_W}x${TARGET_H}"

		ffmpeg -i "$2" \
			-map 0:v? \
			-map 0:a? \
			-map 0:s? \
			-filter:v scale=${RESCALE} \
			-loglevel error \
			-hide_banner \
			"$3"

		wait-spinner q
	else
		# Keep source resolution
		echo -n "Keeping input resolution (${WIDTH}x${HEIGHT}) at new file... "
		
		ffmpeg -i "$2" \
			-map 0:v? \
			-map 0:a? \
			-map 0:s? \
			-loglevel error \
			-hide_banner \
			-c copy \
			"$3"

	fi
	echo "Finished!"
}

rev-loop-nosound() {
	# Make a loop of video forward, then backward
	ffmpeg -i "$1" \
		-filter_complex "[0:v]reverse,fifo[r];[0:v][r] concat=n=2:v=1 [v]" \
		-map "[v]" \
		"$2"
}

rev-loop-sound() {
	# Make loop of a vidoe forward, then backwards, with sound
	ffmpeg -i "$1" \
		-filter_complex "[0:v]reverse,fifo[r];[0:v][0:a][r] [0:a]concat=n=2:v=1:a=1 [v] [a]" -map "[v]" -map "[a]" \
		"$2"
}

to-gif() {
	# Make video into good looking GIF
	ffmpeg -i "$1" \
		-map 0:v:0 \
		-vf 'split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse' \
		"$2"
}

help_line() {
	printf "  %-20s %s\n" "$1" "$2"
}

help_msg() {
	echo -e "\e[1;32m${0//*\/}\e[37m - \e[36mCollection of ffmpeg Scripts\e[37m"
	echo -e "\n\e[1mUSAGE\e[22m"
	echo "  ${0//*\/} <Operation> <Input File> <Output File>"
	echo -e "\n\e[1mSCRIPTS\e[22m"

	help_line "rmsilence" "Remove Trailing/Leading Silence (Audio Only)"
	help_line "3dsify, convert-3ds" "Optimize Video for Playback on Old 3DS Homebrew Player"
	echo -en "\e[2m"
	help_line "" "  https://github.com/Core-2-Extreme/Video_player_for_3DS"
	echo -en "\e[22m"
	help_line "maxscale-RES" "Downscale Video (if needed) to new Resolution"
	help_line "revloop" "Loop video first forward, then backwards (No Audio)"
	help_line "revloop-sound" "Same as revloop, but supports audio."
	help_line "to-gif" "Convert to decent looking GIF using palette from source"

	help_line "help, --help, -?" "Display This Message"

	echo -e "\n\e[1mRESOLUTIONS ALIASES\e[22m"
	#local r="${!RES[@]}"
	#echo -e "  \e[3m${r// /, }\e[23m"

	for x in "${!RES[@]}"; do
		help_line "$x" "${RES[$x]}"
	done | sort -n

}

case "$1" in
	"rmsilence")
		rmsilence "$2" "$3"
		;;
	"3dsify"|"convert-3ds")
		3dsify "$2" "$3"
		exit
		;;
	"revloop")
		rev-loop-nosound "$2" "$3"
		;;
	"revloop-sound")
		rev-loop-sound "$2" "$3"
		;;
	"to-gif")
		to-gif "$2" "$3"
		;;
	"maxscale-"*)
		r="${1//*-}" #Remove downscale-
		maxscale "$r" "$2" "$3"
		exit
		;;
	"help"|"--help"|"-?")
		help_msg
		;;
	*)
		echo -e "\e[1;31mUnknown Script\e[22;37m" 1>&2
		exit 1
		;; 
esac
