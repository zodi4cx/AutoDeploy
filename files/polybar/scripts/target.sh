#!/bin/bash

if [ "$1" == "--toggle" ]; then
	if [ ! -f /tmp/.target_show ] || [ $(cat /tmp/.target_show) -eq 1 ]; then var=0
        else var=1; fi
        echo $var > /tmp/.target_show
        exit
elif [ "$1" == "--copy" ]; then
	echo -n "$(cat /tmp/.target)" | xclip -sel clip
	notify-send "Copied!"
	exit
fi

if [ -f /tmp/.target ]; then
	if [ "$(cat /tmp/.target_show 2>/dev/null)" != 1 ]; then echo "什 $(cat /tmp/.target)"
	else echo "什"; fi
else echo; fi
