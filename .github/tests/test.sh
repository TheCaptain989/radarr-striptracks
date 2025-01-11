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

# striptracks_mkvcommand="nice /usr/bin/mkvmerge --title \"$striptracks_title\" -q -o \"$striptracks_tempvideo\" $striptracks_audioarg $striptracks_subsarg \"$striptracks_video\""
# [ $striptracks_debug -ge 1 ] && echo "Debug|Executing: $striptracks_mkvcommand" | log
# striptracks_result=$(eval $striptracks_mkvcommand)
# striptracks_return=$?
# case $striptracks_return in
#   1) striptracks_message=$(echo -e "[$striptracks_return] Warning when remuxing video: \"$striptracks_video\"\nmkvmerge returned: $striptracks_result" | awk '{print "Warn|"$0}')
#     echo "$striptracks_message" | log
#   ;;
#   2) striptracks_message=$(echo -e "[$striptracks_return] Error when remuxing video: \"$striptracks_video\"\nmkvmerge returned: $striptracks_result" | awk '{print "Error|"$0}')
#     echo "$striptracks_message" | log
#     echo "$striptracks_message" >&2
#     end_script 13
#   ;;
# esac

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

striptracks_audiokeep=":eng+1:fre:ger+d"
striptracks_subskeep=":fre"

echo "$striptracks_json" | jq -c --arg AudioKeep "$striptracks_audiokeep" \
--arg SubsKeep "$striptracks_subskeep" '
# Parse input string into language rules
def parse_input($codes):
  $codes | split(":")[1:] | map(
    capture("(?<language>[a-z]{3})(?<modifiers>[+][df0-9]+)?") |
    {
      forced_language: (if (.modifiers | contains("f")) then .language else empty end)#,
#      default_languages: (if (.modifiers | contains("d")) then .lang else empty end),
#      limits: ((.modifiers | scan("[+]([0-9])") | map(tonumber)) as $nums
#        | if $nums then {(.lang): $nums[0]} else {} end)
    }
  );

def parse_language_codes($codes):
  $codes | split(":")[1:] | map(split("+")) | 
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
  ;

# Language rules for audio and subtitles, adding required audio tracks
# (parse_language_codes($AudioKeep) | .languages += ["mis","zxx"]) as $AudioRules |
# parse_language_codes($SubsKeep) as $SubsRules |

parse_input($AudioKeep) as $AudioRules | { $AudioRules }

# Process tracks
# .tracks |= map(
#   # Set track language to "und" if null or empty
#   (if (.properties.language == "" or .properties.language == null) then "und" else .properties.language end) as $lang |
#   .striptracks_debug_log = "Debug|Parsing track ID:\(.id) Type:\(.type) Name:\(.properties.track_name) Lang:\($lang) Codec:\(.codec) Default:\(.properties.default_track) Forced:\(.properties.forced_track)" |
#   
#   # Determine keep logic based on type and rules
#   if .type == "video" then
#     .striptracks_keep = true
#   elif .type == "audio" or .type == "subtitles" then
#       .striptracks_log = "\(.id): \($lang) (\(.codec))\(if .properties.track_name then " \"" + .properties.track_name + "\"" else "" end)" |
#       (if .type == "audio" then $AudioRules else $SubsRules end) as $currentRules |
#       if (($currentRules.languages | index("any")) or ($currentRules.languages | index($lang))) then
#         .striptracks_keep = true
#       elif (.properties.forced_track and (($currentRules.forced_languages | index("any")) or ($currentRules.forced_languages | index($lang)))) then
#         .striptracks_keep = true |
#         .rule = "forced"
#       elif (.properties.default_track and (($currentRules.default_languages | index("any")) or ($currentRules.default_languages | index($lang)))) then
#         .striptracks_keep = true |
#         .rule = "default"
#       else . end |
#     if .striptracks_keep then
#       .striptracks_log = "Info|Keeping \(if .rule then .rule + " " else "" end)\(.type) track " + .striptracks_log
#     else
#       .striptracks_keep = false
#     end
#   else . end
# ) |
# 
# # Ensure at least one audio track is kept
# if ((.tracks | map(select(.type == "audio")) | length == 1) and (.tracks | map(select(.type == "audio" and .striptracks_keep)) | length == 0)) then
#   # If there is only one audio track and none are kept, keep the only audio track
#   .tracks |= map(if .type == "audio" then
#       .striptracks_log = "Warn|No audio tracks matched! Keeping only audio track " + .striptracks_log |
#       .striptracks_keep = true
#     else . end)
# elif (.tracks | map(select(.type == "audio" and .striptracks_keep)) | length == 0) then
#   # If no audio tracks are kept, first try to keep the default audio track
#   .tracks |= map(if .type == "audio" and .properties.default_track then
#       .striptracks_log = "Warn|No audio tracks matched! Keeping default audio track " + .striptracks_log |
#       .striptracks_keep = true
#     else . end) |
#   # If still no audio tracks are kept, keep the first audio track
#   if (.tracks | map(select(.type == "audio" and .striptracks_keep)) | length == 0) then
#     (first(.tracks[] | select(.type == "audio"))) |= . +
#     {striptracks_log: ("Warn|No audio tracks matched! Keeping first audio track " + .striptracks_log),
#      striptracks_keep: true}
#   else . end
# else . end |

# Output simplified dataset
# { striptracks_log, tracks: [ .tracks[] | { id, type, forced: .properties.forced_track, default: .properties.default_track, striptracks_debug_log, striptracks_log, striptracks_keep } ] }
'
