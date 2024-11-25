#!/bin/bash

case "$1" in
	"--help"|"-?")
		echo "Restarts the following systemd user units."
		echo ""
		printf "  %s\n" pipewire{,-pulse}.{service,socket} wireplumber.service
		exit
		;;
	"")
		:
		;;
	*)
		echo "Invalid Arguments!"
		exit 1
		;;
esac


systemctl --user restart pipewire{,-pulse}.{service,socket} wireplumber.service
