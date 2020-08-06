#!/bin/bash

gnome-terminal --hide-menubar -e "cmatrix -bL" -t "matrix" &
sleep 0.2

bspc node -t fullscreen
i3lock -n; bspc node -c
