#!/bin/bash

if [ "$1" == "--toggle" ]; then
	if [ ! -f /tmp/.wifi ] || [ $(cat /tmp/.wifi) -eq 1 ]; then var=0
	else var=1; fi
	echo $var > /tmp/.wifi
	exit
elif [ "$1" == "--applet" ]; then
	if pidof nm-applet; then pkill nm-applet
	else nm-applet > /dev/null 2>&1 &
	fi
	exit
fi

IFACE="wlan0"
output=$(/usr/sbin/iwconfig $IFACE 2>/dev/null)

if ! echo "$output" | grep "Not-Associated" > /dev/null 2>&1 ; then
	essid=$(echo "$output" | grep -oP '(?<=ESSID:").*?(?=")')
	ip=$(/usr/sbin/ifconfig $IFACE 2>/dev/null | grep "inet " | awk '{print $2}')
	if [ "$(cat /tmp/.wifi 2>/dev/null)" == 1 ]; then echo "$essid"
	else echo "$ip"; fi
else
	echo
fi
