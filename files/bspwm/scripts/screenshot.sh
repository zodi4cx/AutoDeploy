#!/bin/bash
filename="/tmp/screenshot-$(date +%H%M%S).png"
import "$filename" && xclip -sel clip -t image/png "$filename"
