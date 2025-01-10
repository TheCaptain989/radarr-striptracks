#!/bin/bash

striptracks_debug=0
striptracks_pid=$$
striptracks_tempvideo=.github/tests/test.mkv
striptracks_title="Test Title"

function log {(
  while read -r
  do
    # shellcheck disable=2046
    echo $(date +"%Y-%m-%d %H:%M:%S.%1N")"|[$striptracks_pid]$REPLY"
  done
)}

function end_script {
  # Cool bash feature
  striptracks_message="Info|Completed in $((SECONDS/60))m $((SECONDS%60))s"
  echo "$striptracks_message" | log
  [ "$1" != "" ] && striptracks_exitstatus=$1
  [ $striptracks_debug -ge 1 ] && echo "Debug|Exit code ${striptracks_exitstatus:-0}" | log
  exit ${striptracks_exitstatus:-0}
}

function get_mediainfo {
  [ $striptracks_debug -ge 1 ] && echo "Debug|Executing: /usr/bin/mkvmerge -J \"$1\"" | log
  unset striptracks_json
  striptracks_json=$(/usr/bin/mkvmerge -J "$1")
  local striptracks_return=$?
  [ $striptracks_debug -ge 2 ] && echo "mkvmerge returned: $striptracks_json" | awk '{print "Debug|"$0}' | log
  case $striptracks_return in
    0)
      # Check for unsupported container.
      if [ "$(echo "$striptracks_json" | jq -crM '.container.supported')" = "false" ]; then
        striptracks_message="Error|Video format for '$1' is unsupported. Unable to continue. mkvmerge returned container info: $(echo $striptracks_json | jq -crM .container)"
        echo "$striptracks_message" | log
        echo "$striptracks_message" >&2
        end_script 9
      fi
    ;;
    1) striptracks_message=$(echo -e "[$striptracks_return] Warning when inspecting video.\nmkvmerge returned: $(echo "$striptracks_json" | jq -crM '.warnings[]')" | awk '{print "Warn|"$0}')
      echo "$striptracks_message" | log
    ;;
    2) striptracks_message=$(echo -e "[$striptracks_return] Error when inspecting video.\nmkvmerge returned: $(echo "$striptracks_json" | jq -crM '.errors[]')" | awk '{print "Error|"$0}')
      echo "$striptracks_message" | log
      echo "$striptracks_message" >&2
      end_script 9
    ;;
  esac
  return $striptracks_return
}

# get_mediainfo "README.md"

striptracks_video=.github/tests/bear-320x240_corrupted_after_init_segment.webm

get_mediainfo "$striptracks_video"

striptracks_audioarg="-a 1"
striptracks_subsarg="-S"

striptracks_mkvcommand="nice /usr/bin/mkvmerge --title \"$striptracks_title\" -q -o \"$striptracks_tempvideo\" $striptracks_audioarg $striptracks_subsarg \"$striptracks_video\""
[ $striptracks_debug -ge 1 ] && echo "Debug|Executing: $striptracks_mkvcommand" | log
striptracks_result=$(eval $striptracks_mkvcommand)
striptracks_return=$?
case $striptracks_return in
  1) striptracks_message=$(echo -e "[$striptracks_return] Warning when remuxing video: \"$striptracks_video\"\nmkvmerge returned: $striptracks_result" | awk '{print "Warn|"$0}')
    echo "$striptracks_message" | log
  ;;
  2) striptracks_message=$(echo -e "[$striptracks_return] Error when remuxing video: \"$striptracks_video\"\nmkvmerge returned: $striptracks_result" | awk '{print "Error|"$0}')
    echo "$striptracks_message" | log
    echo "$striptracks_message" >&2
    end_script 13
  ;;
esac

<<comment
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
comment

striptracks_audiokeep=":eng+1"
striptracks_subskeep=":fre"

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
