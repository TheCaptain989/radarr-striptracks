#!/bin/bash

# shellcheck disable=all
#json='{"attachments":[],"chapters":[],"container":{"properties":{"container_type":25,"is_providing_timestamps":true},"recognized":true,"supported":true,"type":"QuickTime/MP4"},"errors":[],"file_name":"ElephantsDream.mp4","global_tags":[],"identification_format_version":12,"track_tags":[],"tracks":[{"codec":"MPEG-4p10/AVC/H.264","id":0,"properties":{"language":"","number":1,"packetizer":"mpeg4_p10_video","pixel_dimensions":"1280x720"},"type":"video"},{"codec":"MPEG-4p10/AVC/H.264","id":10,"properties":{"language":"","number":10,"packetizer":"mpeg4_p10_video","pixel_dimensions":"1280x720"},"type":"video"},{"codec":"AAC","id":1,"properties":{"audio_bits_per_sample":16,"audio_channels":2,"audio_sampling_frequency":44100,"number":2},"type":"audio"},{"codec":"TheCaptain989-forced","id":2,"properties":{"audio_bits_per_sample":16,"audio_channels":2,"audio_sampling_frequency":44100,"track_name":"Should include","language":"ger","number":5,"forced_track":true},"type":"audio"},{"codec":"TheCaptain989-default","id":3,"properties":{"audio_bits_per_sample":16,"audio_channels":2,"audio_sampling_frequency":44100,"track_name":"Should include","language":"ger","number":6,"default_track":true},"type":"audio"},{"codec":"TheCaptain989","id":4,"properties":{"audio_bits_per_sample":16,"audio_channels":2,"audio_sampling_frequency":44100,"track_name":"Should include","language":"eng","number":3},"type":"audio"},{"codec":"TheCaptain989-2","id":5,"properties":{"audio_bits_per_sample":16,"audio_channels":2,"audio_sampling_frequency":44100,"language":"eng","track_name":"Should exclude","number":4},"type":"audio"}],"warnings":[]}'
json='{"attachments":[],"chapters":[],"container":{"properties":{"container_type":25,"is_providing_timestamps":true},"recognized":true,"supported":true,"type":"QuickTime/MP4"},"errors":[],"file_name":"ElephantsDream.mp4","global_tags":[],"identification_format_version":12,"track_tags":[],"tracks":[{"codec":"MPEG-4p10/AVC/H.264","id":0,"properties":{"language":"","number":1,"packetizer":"mpeg4_p10_video","pixel_dimensions":"1280x720"},"type":"video"},{"codec":"MPEG-4p10/AVC/H.264","id":10,"properties":{"language":"","number":10,"packetizer":"mpeg4_p10_video","pixel_dimensions":"1280x720"},"type":"video"},{"codec":"AAC","id":1,"properties":{"audio_bits_per_sample":16,"audio_channels":2,"audio_sampling_frequency":44100,"number":2},"type":"audio"},{"codec":"TheCaptain989-forced","id":2,"properties":{"audio_bits_per_sample":16,"audio_channels":2,"audio_sampling_frequency":44100,"track_name":"Should include","language":"ger","number":5,"forced_track":true},"type":"audio"},{"codec":"TheCaptain989-default","id":3,"properties":{"audio_bits_per_sample":16,"audio_channels":2,"audio_sampling_frequency":44100,"track_name":"Should include","language":"ger","number":6,"default_track":true},"type":"audio"},{"codec":"SubsAlpha","id":4,"properties":{"track_name":"Should include","language":"eng","forced_track":true},"type":"subtitles"},{"codec":"TheCaptain989","id":5,"properties":{"audio_bits_per_sample":16,"audio_channels":2,"audio_sampling_frequency":44100,"track_name":"Should include","language":"eng","number":3},"type":"audio"},{"codec":"TheCaptain989-2","id":6,"properties":{"audio_bits_per_sample":16,"audio_channels":2,"audio_sampling_frequency":44100,"language":"eng","track_name":"Should exclude","number":4},"type":"audio"}],"warnings":[]}'

echo $json | jq -c '.tracks | map(.properties.language)'

json_processed=$(echo "$json" | jq -c --argjson AudioRules '{"languages":{"eng":1,"fre":-1},"forced_languages":{"any":-1},"default_languages":{"ger":-1}}' \
--argjson SubsRules '{"languages":null,"forced_languages":{"any":-1},"default_languages":null}' '
# Process tracks
reduce .tracks[] as $track (
  # Create object to hold tracks and counters for each reduce iteration
  # This is what will be output at the end of the reduce loop
  {"tracks": [], "counters": {"audio": {"normal": {}, "forced": {}, "default": {}}, "subtitles": {"normal": {}, "forced": {}, "default": {}}}};

  # Set track language to "und" if null or empty
  # NOTE: The // operator cannot be used here because it checks for null or empty values, not blank strings
  (if ($track.properties.language == "" or $track.properties.language == null) then "und" else $track.properties.language end) as $track_lang |

  # Initialize counters for each track type and language
  (.counters[$track.type].normal[$track_lang] //= 0) |
  if $track.properties.forced_track then (.counters[$track.type].forced[$track_lang] //= 0) else . end |
  if $track.properties.default_track then (.counters[$track.type].default[$track_lang] //= 0) else . end |
  .counters[$track.type] as $track_counters |
  
  # Add tracks one at a time to output object above
  .tracks += [
    $track |
    .striptracks_debug_log = "Debug|Parsing track ID:\(.id) Type:\(.type) Name:\(.properties.track_name) Lang:\($track_lang) Codec:\(.codec) Default:\(.properties.default_track) Forced:\(.properties.forced_track)" |
    # Use track language evaluation above
    .properties.language = $track_lang |

    # Determine keep logic based on type and rules
    if .type == "video" then
      .striptracks_keep = true
    elif .type == "audio" or .type == "subtitles" then
      .striptracks_log = "\(.id): \($track_lang) (\(.codec))\(if .properties.track_name then " \"" + .properties.track_name + "\"" else "" end)" |
      # Same logic for both audio and subtitles
      (if .type == "audio" then $AudioRules else $SubsRules end) as $currentRules |
      if ($currentRules.languages["any"] == -1 or ($track_counters.normal | add) < $currentRules.languages["any"] or
          $currentRules.languages[$track_lang] == -1 or $track_counters.normal[$track_lang] < $currentRules.languages[$track_lang]) then
        .striptracks_keep = true
      elif (.properties.forced_track and
            ($currentRules.forced_languages["any"] == -1 or ($track_counters.forced | add) < $currentRules.forced_languages["any"] or
              $currentRules.forced_languages[$track_lang] == -1 or $track_counters.forced[$track_lang] < $currentRules.forced_languages[$track_lang])) then
        .striptracks_keep = true |
        .striptracks_rule = "forced"
      elif (.properties.default_track and
            ($currentRules.default_languages["any"] == -1 or ($track_counters.default | add) < $currentRules.default_languages["any"] or
              $currentRules.default_languages[$track_lang] == -1 or $track_counters.default[$track_lang] < $currentRules.default_languages[$track_lang])) then
        .striptracks_keep = true |
        .striptracks_rule = "default"
      else . end |
      if .striptracks_keep then
        .striptracks_log = "Info|Keeping \(if .striptracks_rule then .striptracks_rule + " " else "" end)\(.type) track " + .striptracks_log
      else
        .striptracks_keep = false
      end
    else . end
  ] | 
  
  # Increment counters for each track type and language
  .counters[$track.type].normal[$track_lang] +=
    if .tracks[-1].striptracks_keep then
      1
    else 0 end | 
  .counters[$track.type].forced[$track_lang] +=
    if ($track.properties.forced_track and .tracks[-1].striptracks_keep) then
      1
    else 0 end |
  .counters[$track.type].default[$track_lang] +=
    if ($track.properties.default_track and .tracks[-1].striptracks_keep) then
      1
    else 0 end
) |

# Output simplified dataset
{ striptracks_log, tracks: .tracks | map({ id, type, language: .properties.language, forced: .properties.forced_track, default: .properties.default_track, striptracks_debug_log, striptracks_log, striptracks_rule, striptracks_keep }) }
')

echo $json_processed | jq -c '.tracks | map({id, language, striptracks_rule, striptracks_keep})'

striptracks_audiokeep=":any+f:ger:eng+1"
striptracks_subskeep=":any+f"

# Reorder tracks
echo "$json_processed" | jq -c --arg AudioKeep "$striptracks_audiokeep" \
--arg SubsKeep "$striptracks_subskeep" '
# Reorder tracks
def order_tracks(tracks; rules; tracktype):
  rules | split(":")[1:] | map(split("+") | {lang: .[0], mods: .[1]}) | 
  reduce .[] as $rule (
    [];
    . as $orderedTracks |
    . += [tracks |
    map(. as $track | 
      select(.type == tracktype and .striptracks_keep and
        ($rule.lang | in({"any":0,($track.language):0})) and
        ($rule.mods == null or
          ($rule.mods | test("[fd]") | not) or
          ($rule.mods | contains("f") and $track.forced) or
          ($rule.mods | contains("d") and $track.default)
        )
      ) |
      .id as $id |
      # Remove track id from orderedTracks if it already exists
      if ([$id] | flatten | inside($orderedTracks | flatten)) then empty else $id end
    )]
  ) | flatten;

# Reorder audio and subtitles according to language rules
.tracks as $tracks |
order_tracks($tracks; $AudioKeep; "audio") as $audioOrder |
order_tracks($tracks; $SubsKeep; "subtitles") as $subsOrder |

# Output ordered track string compatible with the mkvmerge --track-order option
# Video tracks are always first, followed by audio tracks, then subtitles
$tracks | map(select(.type == "video") | .id) + $audioOrder + $subsOrder | map("0:" + tostring) | join(",")
'
