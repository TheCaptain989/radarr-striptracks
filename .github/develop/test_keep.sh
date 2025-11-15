#!/bin/bash

striptracks_debug=1
source ../../root/usr/local/bin/striptracks.sh

striptracks_pid=$$
log() {( while read -r; do echo "$(date +"%Y-%m-%d %H:%M:%S.%1N")|[$striptracks_pid]$REPLY"; done; )}

striptracks_json='{"attachments":[],"chapters":[],"container":{"properties":{"container_type":25,"is_providing_timestamps":true},"recognized":true,"supported":true,"type":"QuickTime/MP4"},"errors":[],"file_name":"ElephantsDream.mp4","global_tags":[],"identification_format_version":12,"track_tags":[],"tracks":[{"codec":"MPEG-4p10/AVC/H.264","id":0,"properties":{"language":"","number":1,"packetizer":"mpeg4_p10_video","pixel_dimensions":"1280x720"},"type":"video"},{"codec":"MPEG-4p10/AVC/H.264","id":10,"properties":{"language":"","number":10,"packetizer":"mpeg4_p10_video","pixel_dimensions":"1280x720"},"type":"video"},{"codec":"AAC","id":1,"properties":{"audio_bits_per_sample":16,"audio_channels":2,"audio_sampling_frequency":44100,"number":2},"type":"audio"},{"codec":"TheCaptain989-forced","id":2,"properties":{"audio_bits_per_sample":16,"audio_channels":2,"audio_sampling_frequency":44100,"track_name":"Should include","language":"ger","number":5,"forced_track":true},"type":"audio"},{"codec":"TheCaptain989-default","id":3,"properties":{"audio_bits_per_sample":16,"audio_channels":2,"audio_sampling_frequency":44100,"track_name":"Should include","language":"ger","number":6,"default_track":true},"type":"audio"},{"codec":"SubsAlpha","id":4,"properties":{"track_name":"Should include","language":"eng","forced_track":true},"type":"subtitles"},{"codec":"TheCaptain989","id":5,"properties":{"audio_bits_per_sample":16,"audio_channels":2,"audio_sampling_frequency":44100,"track_name":"Should include","language":"eng","number":3},"type":"audio"},{"codec":"TheCaptain989-2","id":6,"properties":{"audio_bits_per_sample":16,"audio_channels":2,"audio_sampling_frequency":44100,"language":"eng","track_name":"Should exclude","number":4},"type":"audio"}],"warnings":[]}'

striptracks_audiokeep=":any+f:ger:eng+1"
striptracks_subskeep=":any+f"

echo "Keeping Audio $striptracks_audiokeep     Subtitles $striptracks_subskeep"

process_mkvmerge_json
echo "$striptracks_json_processed" | jq -c .
