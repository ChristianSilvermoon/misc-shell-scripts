#!/bin/bash

date=${1:-$EPOCHSECONDS}

if ! udate=$(date --date="$1" +%s 2> /dev/null); then
	echo "Invalid Date: $1"
	exit 1
fi

inputLength=$(( ${#udate} + 6 ))
[ "${#date}" -ge "$inputLength" ] && inputLength="${#date}"

inputBar="$(printf "%${inputLength}s" "")"

printf "%-15s | %-${inputLength}s | %-20s\n" \
	"Format" "Input" "Result" \
	"---------------" "${inputBar// /-}" "--------------------" \
	"Normal" "$date" "$date" \
	"Default" "<t:$udate>" "$(printf "%(%B %d, %Y %I:%M %p)T" "$udate")" \
	"Date" "<t:$udate:D>" "$(printf "%(%B %d, %Y)T" "$udate")" \
	"Numeric Date" "<t:$udate:d>" "$(printf "%(%m/%d/%y)T" "$udate")" \
	"Day, Date, Time" "<t:$udate:F>" "$(printf "%(%A, %B %d, %Y %I:%M %p)T" "$udate" )" \
	"Date and Time" "<t:$udate:f>" "$(printf "%(%B %d, %Y %I:%M %p)T" "$udate" )" \
	"Fuzzy/Relative" "<t:$udate:R>" $'\e'"[2;3mEX: a minute ago"$'\e'"[0m" \
	"Time w/ Seconds" "<t:$udate:T>" "$(printf "%(%I:%M:%S %p)T" "$udate" )" \
	"Time" "<t:$udate:t>" "$(printf "%(%I:%M %p)T" "$udate" )"
