#!/bin/bash

while (( "$#" )); do
  case "$1" in
    -a|--audio ) # Audio languages to keep
      if [ -z "$2" ] || [ ${2:0:1} = "-" ]; then
        echo "Error|Invalid option: $1 requires an argument." >&2
        exit 3
      elif [[ "$2" != :* ]]; then
        echo "Error|Invalid option: $1 argument requires a colon." >&2
        exit 3
      fi
      export striptracks_audiokeep="$2"
      shift 2
    ;;
    -s|--subs ) # Subtitles languages to keep
      if [ -z "$2" ] || [ ${2:0:1} = "-" ]; then
        echo "Error|Invalid option: $1 requires an argument." >&2
        exit 3
      elif [[ "$2" != :* ]]; then
        echo "Error|Invalid option: $1 argument requires a colon." >&2
        exit 3
      fi
      export striptracks_subskeep="$2"
      shift 2
    ;;
  esac
done

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
        "language": "und",
        "number": 1,
        "packetizer": "mpeg4_p10_video",
        "pixel_dimensions": "1280x720"
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
        "language": "und",
        "number": 2
      },
      "type": "audio"
    }
  ],
  "warnings": []
}'

echo "$striptracks_json" | jq -c --arg AudioKeep "$striptracks_audiokeep" \
--arg SubsKeep "$striptracks_subskeep" '
# Parse input string into language rules
def parse_language_codes($codes):
  ($codes | split(":")[1:] | map(split("+")) | 
    {languages: map(
      (select(length == 1) | .[0]),
      (select(length > 1 and (.[1] | test("^[0-9]+$"))) | {(.[0]): .[1]})
     ),
     forced_languages: map(
      select(length > 1 and (.[1] | contains("f"))) | .[0]
     ),
     default_languages: map(
      select(length > 1 and (.[1] | contains("d"))) | .[0]
     )}
  );

# Language rules for audio and subtitles, adding required audio tracks
(parse_language_codes($AudioKeep) | .languages += ["mis","zxx"]) as $AudioRules |
parse_language_codes($SubsKeep) as $SubsRules |

# Output simplified dataset
{ $AudioRules, $SubsRules }
'
