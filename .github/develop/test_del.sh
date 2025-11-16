#!/bin/bash

striptracks_debug=1
source /workspaces/radarr-striptracks/root/usr/local/bin/striptracks.sh

striptracks_pid=$$
log() {( while read -r; do echo "$(date +"%Y-%m-%d %H:%M:%S.%1N")|[$striptracks_pid]$REPLY"; done; )}

striptracks_type=Radarr
striptracks_api_url="http://localhost:7878/api/v3"
striptracks_apikey="NOT_A_REAL_API_KEY"
striptracks_video="test_video.mkv"
striptracks_videofile_api="movie"
striptracks_debug=2

delete_videofile 1234