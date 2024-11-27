#!/bin/bash

function log { while read -r line; do echo "$line"; done }
# Exit program
function end_script {
  # Cool bash feature
  striptracks_message="Info|Completed in $((SECONDS/60))m $((SECONDS%60))s"
  echo "$striptracks_message" | log
  [ "$1" != "" ] && striptracks_exitstatus=$1
  [ $striptracks_debug -ge 1 ] && echo "Debug|Exit code ${striptracks_exitstatus:-0}" | log
  exit ${striptracks_exitstatus:-0}
}


# wget https://raw.githubusercontent.com/ietf-wg-cellar/matroska-test-files/refs/heads/master/test_files/test5.mkv
# wget https://download.samplelib.com/mp4/sample-5s.mp4 -O sample.mp4

# striptracks_json=$(mkvmerge -J test5.mkv | jq '.tracks[5].properties.forced_track=true')
striptracks_audiokeep=":eng:any+df"; striptracks_subskeep=":eng:any+f"; striptracks_debug=2
striptracks_title='Berserk: The Golden Age Arc 1 - The Egg of the King (2012)'; striptracks_video='/media/develop/Movies/Berserk The Golden Age Arc I - The Egg of the King (2012)/Berserk- The Golden Age Arc 1 - The Egg of the King (2012).mkv'; striptracks_tempvideo='/media/develop/Movies/Berserk The Golden Age Arc I - The Egg of the King (2012)/Berse.tmp.zHVJ1o'
striptracks_json='{"attachments":[],"chapters":[],"container":{"properties":{"container_type":17,"date_local":"2010-08-21T18:06:43+00:00","date_utc":"2010-08-21T18:06:43Z","duration":46665000000,"is_providing_timestamps":true,"muxing_application":"libebml v1.0.0 + libmatroska v1.0.0","segment_uid":"9d516a0f927a12d286e1502d23d0fdb0","writing_application":"mkvmerge v4.0.0 (\"The Stars were mine\") built on Jun  6 2010 16:18:42"},"recognized":true,"supported":true,"type":"Matroska"},"errors":[],"file_name":"test5.mkv","global_tags":[{"num_entries":3}],"identification_format_version":12,"track_tags":[],"tracks":[{"codec":"MPEG-4p10/AVC/H.264","id":0,"properties":{"codec_id":"V_MPEG4/ISO/AVC","codec_private_data":"014d401fffe10014274d401fa918080093600d418041adb0ad7bdf0101000428ce09c8","codec_private_length":35,"default_duration":41666665,"default_track":true,"display_dimensions":"1024x576","display_unit":0,"enabled_track":true,"forced_track":false,"language":"und","minimum_timestamp":0,"number":1,"packetizer":"mpeg4_p10_video","pixel_dimensions":"1024x576","uid":1258329745},"type":"video"},{"codec":"AAC","id":1,"properties":{"audio_channels":2,"audio_sampling_frequency":48000,"codec_id":"A_AAC","codec_private_data":"1190","codec_private_length":2,"default_duration":21333333,"default_track":true,"enabled_track":true,"forced_track":false,"language":"und","minimum_timestamp":12000000,"number":2,"uid":3452711582},"type":"audio"},{"codec":"SubRip/SRT","id":2,"properties":{"codec_id":"S_TEXT/UTF8","codec_private_length":0,"default_track":true,"enabled_track":true,"encoding":"UTF-8","forced_track":false,"language":"eng","minimum_timestamp":3549000000,"number":3,"text_subtitles":true,"uid":368310685},"type":"subtitles"},{"codec":"SubRip/SRT","id":3,"properties":{"codec_id":"S_TEXT/UTF8","codec_private_length":0,"default_track":false,"enabled_track":true,"encoding":"UTF-8","forced_track":false,"language":"hun","minimum_timestamp":42000000,"number":4,"text_subtitles":true,"uid":77489046},"type":"subtitles"},{"codec":"SubRip/SRT","id":4,"properties":{"codec_id":"S_TEXT/UTF8","codec_private_length":0,"default_track":false,"enabled_track":true,"encoding":"UTF-8","forced_track":false,"language":"ger","minimum_timestamp":42000000,"number":5,"text_subtitles":true,"uid":3554194305},"type":"subtitles"},{"codec":"SubRip/SRT","id":5,"properties":{"codec_id":"S_TEXT/UTF8","codec_private_length":0,"default_track":false,"enabled_track":true,"encoding":"UTF-8","forced_track":true,"language":"fre","minimum_timestamp":42000000,"number":6,"text_subtitles":true,"uid":3601783439},"type":"subtitles"},{"codec":"SubRip/SRT","id":6,"properties":{"codec_id":"S_TEXT/UTF8","codec_private_length":0,"default_track":false,"enabled_track":true,"encoding":"UTF-8","forced_track":false,"language":"spa","minimum_timestamp":42000000,"number":8,"text_subtitles":true,"uid":637820071},"type":"subtitles"},{"codec":"SubRip/SRT","id":7,"properties":{"codec_id":"S_TEXT/UTF8","codec_private_length":0,"default_track":false,"enabled_track":true,"encoding":"UTF-8","forced_track":false,"language":"ita","minimum_timestamp":42000000,"number":9,"text_subtitles":true,"uid":2328328329},"type":"subtitles"},{"codec":"AAC","id":8,"properties":{"audio_channels":1,"audio_sampling_frequency":22050,"codec_id":"A_AAC","codec_private_data":"1388","codec_private_length":2,"default_duration":46439909,"default_track":false,"enabled_track":true,"forced_track":false,"language":"eng","minimum_timestamp":9000000,"number":10,"track_name":"Commentary","uid":215750297},"type":"audio"},{"codec":"SubRip/SRT","id":9,"properties":{"codec_id":"S_TEXT/UTF8","codec_private_length":0,"default_track":false,"enabled_track":true,"encoding":"UTF-8","forced_track":false,"language":"jpn","minimum_timestamp":42000000,"number":11,"text_subtitles":true,"uid":652628868},"type":"subtitles"},{"codec":"SubRip/SRT","id":10,"properties":{"codec_id":"S_TEXT/UTF8","codec_private_length":0,"default_track":false,"enabled_track":true,"encoding":"UTF-8","forced_track":false,"language":"und","minimum_timestamp":42000000,"number":7,"text_subtitles":true,"uid":131186099},"type":"subtitles"}],"warnings":[]}'

# striptracks_json=$(mkvmerge -J test5.mkv | jq '.tracks[5].properties.forced_track=true')
# striptracks_json=$(mkvmerge -J sample.mp4)
# striptracks_json='{ "attachments": [], "chapters": [], "container": { "properties": { "container_type": 25, "is_providing_timestamps": true }, "recognized": true, "supported": true, "type": "QuickTime/MP4" }, "errors": [], "file_name": "sample.mp4", "global_tags": [], "identification_format_version": 12, "track_tags": [], "tracks": [ { "codec": "MPEG-4p10/AVC/H.264", "id": 0, "properties": { "language": "und", "number": 1, "packetizer": "mpeg4_p10_video", "pixel_dimensions": "1920x1080" }, "type": "video" }, { "codec": "AAC", "id": 1, "properties": { "audio_bits_per_sample": 16, "audio_channels": 2, "audio_sampling_frequency": 44100, "language": "eng", "number": 2 }, "type": "audio" }, { "codec": "AAC", "id": 2, "properties": { "audio_bits_per_sample": 16, "audio_channels": 2, "audio_sampling_frequency": 44100, "language": "eng", "number": 3 }, "type": "audio" }  ], "warnings": [] }'
striptracks_title='Poppy (1936)'; striptracks_video='/config/test/Poppy/Poppy (1936).mkv'; striptracks_tempvideo='/config/test/Poppy/Poppy.tmp.Bxax0t'
striptracks_json='{"attachments":[],"chapters":[],"container":{"properties":{"container_type":5,"is_providing_timestamps":true},"recognized":true,"supported":true,"type":"AVI"},"errors":[],"file_name":"/config/test/Poppy/Poppy (1936).avi","global_tags":[],"identification_format_version":19,"track_tags":[],"tracks":[{"codec":"MPEG-4p2","id":0,"properties":{"pixel_dimensions":"640x480"},"type":"video"},{"codec":"MP3","id":1,"properties":{"audio_channels":2,"audio_sampling_frequency":44100},"type":"audio"}],"warnings":[]}'

striptracks_json_processed=$(echo "$striptracks_json" | jq -jcM --arg AudioKeep "$striptracks_audiokeep" \
--arg SubsKeep "$striptracks_subskeep" '
# Parse input string into language rules
def parse_language_codes($codes):
  ($codes | split(":")[1:] | map(split("+")) | 
    {languages: map(select(length == 1) | .[0]),
     forced_languages: map(select(length > 1 and (.[1] | contains("f"))) | .[0]),
     default_languages: map(select(length > 1 and (.[1] | contains("d"))) | .[0])}
  );

# Language rules for audio and subtitles, adding required audio tracks
(parse_language_codes($AudioKeep) | .languages += ["mis","zxx"]) as $AudioRules |
parse_language_codes($SubsKeep) as $SubsRules |

# Log chapter information
if (.chapters[0].num_entries) then
  .striptracks_log = "Info|Chapters: \(.chapters[].num_entries)"
else . end |

# Process tracks
.tracks |= map(
  # Set track language to "und" if null or empty
  (if (.properties.language == "" or .properties.language == null) then "und" else .properties.language end) as $lang |
  .striptracks_debug = "Debug|Parsing: Track ID:\(.id) Type:\(.type) Name:\(.properties.track_name) Lang:\($lang) Codec:\(.codec) Default:\(.properties.default_track) Forced:\(.properties.forced_track)" |
  
  # Determine keep logic based on type and rules
  if .type == "video" then
    .striptracks_keep = true
  elif .type == "audio" or .type == "subtitles" then
      .striptracks_log = "\(.id): \($lang) (\(.codec))\(if .properties.track_name then " \"" + .properties.track_name + "\"" else "" end)" |
      (if .type == "audio" then $AudioRules else $SubsRules end) as $currentRules |
      if (($currentRules.languages | index("any")) or ($currentRules.languages | index($lang))) then
        .striptracks_keep = true
      elif (.properties.forced_track and (($currentRules.forced_languages | index("any")) or ($currentRules.forced_languages | index($lang)))) then
        .striptracks_keep = true |
        .rule = "forced"
      elif (.properties.default_track and (($currentRules.default_languages | index("any")) or ($currentRules.default_languages | index($lang)))) then
        .striptracks_keep = true |
        .rule = "default"
      else . end |
    if .striptracks_keep then
      .striptracks_log = "Info|Keeping \(if .rule then .rule + " " else "" end)\(.type) track " + .striptracks_log
    else
      .striptracks_keep = false
    end
  else . end
) |

# Ensure at least one audio track is kept
if ((.tracks | map(select(.type == "audio")) | length == 1) and (.tracks | map(select(.type == "audio" and .striptracks_keep)) | length == 0)) then
  # If there is only one audio track and none are kept, keep the only audio track
  .tracks |= map(if .type == "audio" then
      .striptracks_log = "Warn|No audio tracks matched! Keeping only audio track " + .striptracks_log |
      .striptracks_keep = true
    else . end)
elif (.tracks | map(select(.type == "audio" and .striptracks_keep)) | length == 0) then
  # If no audio tracks are kept, first try to keep the default audio track
  .tracks |= map(if .type == "audio" and .properties.default_track then
      .striptracks_log = "Warn|No audio tracks matched! Keeping default audio track " + .striptracks_log |
      .striptracks_keep = true
    else . end) |
  # If still no audio tracks are kept, keep the first audio track
  if (.tracks | map(select(.type == "audio" and .striptracks_keep)) | length == 0) then
    (first(.tracks[] | select(.type == "audio"))) |= . +
    {striptracks_log: ("Warn|No audio tracks matched! Keeping first audio track " + .striptracks_log),
     striptracks_keep: true}
  else . end
else . end |

# Output simplified dataset
{ striptracks_log, tracks: [ .tracks[] | { id, type, forced: .properties.forced_track, default: .properties.default_track, striptracks_debug, striptracks_log, striptracks_keep } ] }
')
[ $striptracks_debug -ge 2 ] && echo "Debug|Track processing returned ${#striptracks_json_processed} bytes." | log
[ $striptracks_debug -ge 3 ] && echo "Track processing returned: $(echo "$striptracks_json_processed" | jq)" | awk '{print "Debug|"$0}' | log

# Write messages to log
echo "$striptracks_json_processed" | jq -crM --argjson Debug $striptracks_debug '
# Log removed tracks
def log_removed_tracks($type):
  if (.tracks | map(select(.type == $type and .striptracks_keep == false)) | length > 0) then
    "Info|Removed \($type) tracks: " +
    (.tracks | map(select(.type == $type and .striptracks_keep == false) | .striptracks_log) | join(", "))
  else empty end;

# Log the chapters, if any
.striptracks_log // empty,

# Log debug messages
( .tracks[] | (if $Debug >= 2 then .striptracks_debug else empty end),

 # Log messages for kept tracks
 (select(.striptracks_keep) | .striptracks_log // empty)
),

log_removed_tracks("audio"),
log_removed_tracks("subtitles"),

# Summary of kept tracks
"Info|Kept tracks: \(.tracks | map(select(.striptracks_keep)) | length) " +
"(audio: \(.tracks | map(select(.type == "audio" and .striptracks_keep)) | length), " +
"subtitles: \(.tracks | map(select(.type == "subtitles" and .striptracks_keep)) | length))"
' | log

# Check for no audio or subtitle tracks
[ "$(echo "$striptracks_json_processed" | jq -crM '.tracks|map(select(.type=="audio" and .striptracks_keep))')" = "" ] && {
  striptracks_message="Warn|Script encountered an error when determining audio tracks to keep and must close."
  echo "$striptracks_message" | log
  echo "$striptracks_message" >&2
  end_script 11
}

# All tracks matched/no tracks removed
[ "$(echo "$striptracks_json" | jq -crM '.tracks|map(select(.type=="audio" or .type=="subtitles"))|length')" = "$(echo "$striptracks_json_processed" | jq -crM '.tracks|map(select(.type=="audio" or .type=="subtitles" and .striptracks_keep))|length')" ] && {
  [ $striptracks_debug -ge 1 ] && echo "Debug|No tracks will be removed from video \"$striptracks_video\"" | log
  # Check if already MKV.  Remuxing not performed.
  if [[ $striptracks_video == *.mkv ]]; then
    striptracks_message="Info|No tracks would be removed from video. Setting Title only and exiting."
    echo "$striptracks_message" | log
    striptracks_mkvcommand="/usr/bin/mkvpropedit -q --edit info --set \"title=$striptracks_title\" \"$striptracks_video\""
    [ $striptracks_debug -ge 1 ] && echo "Debug|Executing: $striptracks_mkvcommand" | log
    # eval $striptracks_mkvcommand
    end_script $?
  else
    [ $striptracks_debug -ge 1 ] && echo "Debug|Source video is not MKV. Remuxing anyway." | log
  fi
}

# Build argument with kept audio tracks for MKVmerge
striptracks_audioarg=$(echo "$striptracks_json_processed" | jq -crM '.tracks | map(select(.type == "audio" and .striptracks_keep) | .id) | join(",")')
striptracks_audioarg="-a $striptracks_audioarg"

# Build argument with kept subtitles tracks for MKVmerge
striptracks_subsarg=$(echo "$striptracks_json_processed" | jq -crM '.tracks | map(select(.type == "subtitles" and .striptracks_keep) | .id) | join(",")')
[ ${#striptracks_subsarg} -ne 0 ] && striptracks_subsarg="-s $striptracks_subsarg" || striptracks_subsarg="-S"

# Execute MKVmerge
striptracks_mkvcommand="nice /usr/bin/mkvmerge --title \"$striptracks_title\" -q -o \"$striptracks_tempvideo\" $striptracks_audioarg $striptracks_subsarg \"$striptracks_video\""
[ $striptracks_debug -ge 1 ] && echo "Debug|Executing: $striptracks_mkvcommand" | log
# eval $striptracks_mkvcommand
striptracks_return=$?
[ $striptracks_debug -ge 2 ] && echo "Debug|mkvmerge exited with code: $striptracks_return" | log
[ $striptracks_return -ne 0 ] && {
  striptracks_message="Error|[$striptracks_return] mkvmerge error while remuxing \"$striptracks_video\""
  echo "$striptracks_message" | log
  echo "$striptracks_message" >&2
  end_script 13
}
