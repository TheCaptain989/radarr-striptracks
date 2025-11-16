#!/bin/bash

striptracks_debug=2
source /workspaces/radarr-striptracks/root/usr/local/bin/striptracks.sh

striptracks_pid=$$
log() {( while read -r; do echo "$(date +"%Y-%m-%d %H:%M:%S.%1N")|[$striptracks_pid]$REPLY"; done; )}

striptracks_json='{
  "attachments": [],
  "chapters": [],
  "container": {
    "properties": {
      "container_type": 25,
      "is_providing_timestamps": true
    },
    "recognized": true,
    "supported": true,
    "type": "QuickTime/MP4"
  },
  "errors": [],
  "file_name": "ElephantsDream.mp4",
  "global_tags": [],
  "identification_format_version": 12,
  "track_tags": [],
  "tracks": [
    {
      "codec": "MPEG-4p10/AVC/H.264",
      "id": 0,
      "properties": {
        "language": "",
        "number": 1,
        "packetizer": "mpeg4_p10_video",
        "pixel_dimensions": "1280x720",
        "uid": 201326592
      },
      "type": "video"
    },
    {
      "codec": "AAC",
      "id": 1,
      "properties": {
        "audio_bits_per_sample": 16,
        "audio_channels": 2,
        "audio_sampling_frequency": 44100,
        "number": 2,
        "uid": 335544320
      },
      "type": "audio"
    },
    {
      "codec": "TheCaptain989-forced",
      "id": 4,
      "properties": {
        "audio_bits_per_sample": 16,
        "audio_channels": 2,
        "audio_sampling_frequency": 44100,
        "track_name": "Should include",
        "language": "ger",
        "number": 5,
        "forced_track": true,
        "uid": 536870912
      },
      "type": "audio"
    },
    {
      "codec": "TheCaptain989-default",
      "id": 5,
      "properties": {
        "audio_bits_per_sample": 16,
        "audio_channels": 2,
        "audio_sampling_frequency": 44100,
        "track_name": "Must include",
        "language": "ger",
        "number": 6,
        "default_track": true,
        "uid": 671088640
      },
      "type": "audio"
    },
    {
      "codec": "TheCaptain989-subs",
      "id": 27,
      "properties": {
        "track_name": "Subs (SDH)",
        "language": "fre",
        "number": 3,
        "forced_track": true,
        "uid": 805306368
      },
      "type": "subtitles"
    },
    {
      "codec": "TheCaptain989",
      "id": 2,
      "properties": {
        "audio_bits_per_sample": 16,
        "audio_channels": 2,
        "audio_sampling_frequency": 44100,
        "track_name": "Should include",
        "language": "eng",
        "number": 3,
        "uid": 402653184
      },
      "type": "audio"
    },
    {
      "codec": "TheCaptain989-2",
      "id": 3,
      "properties": {
        "audio_bits_per_sample": 16,
        "audio_channels": 2,
        "audio_sampling_frequency": 44100,
        "language": "eng",
        "track_name": "Should exclude",
        "number": 4,
        "uid": 469762048
      },
      "type": "audio"
    }
  ],
  "warnings": []
}'

striptracks_audiokeep=":eng+1:fre:ger+d:any+f"
striptracks_subskeep=":any+f"
striptracks_default_audio=":ger"
striptracks_default_subtitles=":fre=SDH"

echo "Keeping Audio $striptracks_audiokeep     Subtitles $striptracks_subskeep"

process_mkvmerge_json
echo "$striptracks_json_processed" | jq -c .

# Set default tracks
execute_mkv_command() { echo "Simulated:" $1 $2; }
set_default_tracks
