#!/bin/bash
# shellcheck disable=SC2034,SC2181,SC2154

striptracks_debug=0
source /workspaces/radarr-striptracks/root/usr/local/bin/striptracks.sh

striptracks_pid=$$
log() {( while read -r; do echo "$(date +"%Y-%m-%d %H:%M:%S.%1N")|[$striptracks_pid]$REPLY"; done; )}

# check determine_track_order 
export striptracks_json_processed='{"tracks":[{"id":0,"type":"video","language":"und","striptracks_keep":true},{"id":1,"type":"audio","language":"eng","name":"name","striptracks_keep":true},{"id":2,"type":"subtitles","language":"fra","name":"comment forced","forced":true,"striptracks_keep":true},{"id":3,"type":"subtitles","language":"eng","name":"comment","forced":false,"striptracks_keep":true}]}'  
export striptracks_audiokeep=":eng" 
export striptracks_subskeep=":eng:fra" 
export striptracks_reorder="true" 
determine_track_order 
echo "determine_track_order -> $striptracks_neworder" 
 
# check set_default_tracks scenarios 
export striptracks_json_processed='{"tracks":[{"id":0,"type":"video","language":"und","striptracks_keep":true},{"id":1,"type":"audio","language":"eng","name":"name","striptracks_keep":true},{"id":2,"type":"subtitles","language":"eng","name":"comment forced","forced":true,"striptracks_keep":true},{"id":3,"type":"subtitles","language":"eng","name":"comment","forced":false,"striptracks_keep":true}]}' 
striptracks_default_subtitles=":eng-f" 
striptracks_default_flags="" 
set_default_tracks 
echo "default_flags for :eng-f -> $striptracks_default_flags" 
 
striptracks_default_subtitles=":eng=comment" 
striptracks_default_flags="" 
set_default_tracks 
echo "default_flags for :eng=comment -> $striptracks_default_flags" 
 
striptracks_default_subtitles=":eng=comment-f" 
striptracks_default_flags="" 
set_default_tracks 
echo "default_flags for :eng=comment-f -> $striptracks_default_flags" 
 
striptracks_default_subtitles=":eng-f=comment" 
striptracks_default_flags="" 
set_default_tracks 
echo "default_flags for :eng-f=comment -> $striptracks_default_flags"
