#!/bin/bash
# shellcheck disable=SC2034,SC2181,SC2154

striptracks_debug=0
source /workspaces/radarr-striptracks/root/usr/local/bin/striptracks.sh
setup_ansi_colors

striptracks_pid=$$
log() {( while read -r; do echo "$(date +"%Y-%m-%d %H:%M:%S.%1N")|[$striptracks_pid]$REPLY"; done; )}
execute_mkv_command() { :; }

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
        "number": 2
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
        "forced_track": true
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
        "track_name": "Should include",
        "language": "ger",
        "number": 6,
        "default_track": true
      },
      "type": "audio"
    },
    {
      "codec": "TheCaptain989-subs",
      "id": 27,
      "properties": {
        "track_name": "Subs forced",
        "language": "fre",
        "number": 3,
        "forced_track": true
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
        "number": 3
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
        "number": 4
      },
      "type": "audio"
    }
  ],
  "warnings": []
}'
striptracks_audiokeep=":eng+1:fre:ger+d:any+f"
striptracks_subskeep=":any+f"

echo -e "${ansi_yellow}Running tests...${ansi_nc}"
echo -e "${ansi_green}AudioKeep: ${striptracks_audiokeep}${ansi_nc}"
echo -e "${ansi_green}SubsKeep: ${striptracks_subskeep}${ansi_nc}"

# Test process_mkvmerge_json function
echo -e "${ansi_cyan}Testing process_mkvmerge_json function...${ansi_nc}"
striptracks_json_processed_org=$(echo "$striptracks_json" | jq -jcM --arg AudioKeep "$striptracks_audiokeep" \
  --arg SubsKeep "$striptracks_subskeep" '
  # Parse input string into JSON language rules function
  def parse_language_codes(codes):
    # Supports f, d, and number modifiers (see issues #82 and #86)
    # -1 default value in language key means to keep unlimited tracks
    # NOTE: Logic can result in duplicate keys, but jq just uses the last defined key
    codes | split(":")[1:] | map(split("+") | {lang: .[0], mods: .[1]}) |
    {languages: map(
        # Select tracks with no modifiers or only numeric modifiers
        (select(.mods == null) | {(.lang): -1}),
        (select(.mods | test("^[0-9]+$")?) | {(.lang): .mods | tonumber})
      ) | add,
      forced_languages: map(
        # Select tracks with f modifier
        select(.mods | contains("f")?) | {(.lang): ((.mods | scan("[0-9]+") | tonumber) // -1)}
      ) | add,
      default_languages: map(
        # Select tracks with d modifier
        select(.mods | contains("d")?) | {(.lang): ((.mods | scan("[0-9]+") | tonumber) // -1)}
      ) | add
    };

  # Language rules for audio and subtitles, adding required audio tracks (see issue #54)
  (parse_language_codes($AudioKeep) | .languages += {"mis":-1,"zxx":-1}) as $AudioRules |
  parse_language_codes($SubsKeep) as $SubsRules |

  # Log chapter information
  if (.chapters[0].num_entries) then
    .striptracks_log = "Info|Chapters: \(.chapters[].num_entries)"
  else . end |

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
  { striptracks_log, tracks: .tracks | map({ id, type, language: .properties.language, name: .properties.track_name, forced: .properties.forced_track, default: .properties.default_track, striptracks_debug_log, striptracks_log, striptracks_keep }) }
')
process_mkvmerge_json

if [ "$striptracks_json_processed" = "$striptracks_json_processed_org" ]; then
  echo -e "\t${ansi_green}JSON processing test passed!${ansi_nc}"
else 
  echo -e "${ansi_red}ERROR: Processed JSON differs from original processing!${ansi_nc}"
  echo -e "\tOriginal: $(echo "$striptracks_json_processed_org" | jq -cM '.tracks | map(select(.striptracks_keep)|"{\(.id):\(.language)\(if .forced then ",f" else "" end)\(if .default then ",d" else "" end)}") | join(",")')"
  echo -e "\t     New: $(echo "$striptracks_json_processed" | jq -cM '.tracks | map(select(.striptracks_keep)|"{\(.id):\(.language)\(if .forced then ",f" else "" end)\(if .default then ",d" else "" end)}") | join(",")')"
  echo "$striptracks_json_processed"
fi

# Test determine_track_order function
echo -e "${ansi_cyan}Testing determine_track_order function...${ansi_nc}"
audio_rules_json=$(parse_language_codes_to_json "$striptracks_audiokeep" "audio")
striptracks_reorder="true"

striptracks_neworder_org=$(echo "$striptracks_json_processed" | jq -jcM --arg AudioKeep "$striptracks_audiokeep" \
  --arg SubsKeep "$striptracks_subskeep" '
  # Reorder tracks function
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

  # Reorder audio and subtitles according to language code order
  .tracks as $tracks |
  order_tracks($tracks; $AudioKeep; "audio") as $audioOrder |
  order_tracks($tracks; $SubsKeep; "subtitles") as $subsOrder |

  # Output ordered track string compatible with the mkvmerge --track-order option
  # Video tracks are always first, followed by audio tracks, then subtitles
  # NOTE: If there is only one audio track and it does not match a code in AudioKeep, it will not appear in the new track order string
  # NOTE: Other track types are still preserved as mkvmerge will automatically place any missing tracks after those listed per https://mkvtoolnix.download/doc/mkvmerge.html#mkvmerge.description.track_order
  $tracks | map(select(.type == "video") | .id) + $audioOrder + $subsOrder | map("0:" + tostring) | join(",")
')
determine_track_order

if [ "$striptracks_neworder" = "$striptracks_neworder_org" ]; then
  echo -e "\t${ansi_green}Track order test passed!${ansi_nc}"
else
  echo -e "${ansi_red}ERROR: New track order differs from original processing!${ansi_nc}"
  echo -e "\tOriginal: $striptracks_neworder_org"
  echo -e "\t     New: $striptracks_neworder"
fi

# Test set_default_tracks function
echo -e "${ansi_cyan}Testing set_default_tracks function...${ansi_nc}"
striptracks_default_audio=":eng=Should include"
striptracks_default_subtitles=":any-f"

echo -e "${ansi_green}Default Audio: ${striptracks_default_audio}${ansi_nc}"
echo -e "${ansi_green}Default Subtitles: ${striptracks_default_subtitles}${ansi_nc}"

function set_default_tracks_org {
  # Build mkvpropedit parameters to set default flags on audio and subtitle tracks.

  # Process audio and subtitle --set-default track settings
  for tracktype in audio subtitles; do
    local cfgvar="striptracks_default_${tracktype}"
    local currentcfg="${!cfgvar}"

    if [ -z "$currentcfg" ]; then
      [ $striptracks_debug -ge 1 ] && echo "Debug|No default ${tracktype} track setting specified." | log
      continue
    fi
    
    # Use jq to find the track ID using case-insensitive substring match on track name
    local track_id=$(echo "$striptracks_json_processed" | jq -crM --arg type "$tracktype" --arg currentcfg "$currentcfg" '
      def parse_cfg(cfg):
        # Remove leading ":" then split on "=" (if present)
        # Supports f as a modifier (see issue #113)
        (cfg | ltrimstr(":") | split("=")) as $eq |
        ($eq[0]) as $left |
        (if ($eq | length > 1) then $eq[1] else "" end) as $right |

        # Detect trailing "-f" on left or right and strip it; only "f" is a valid modifier
        (if ($left | test("-f$")) then {lang: ($left | sub("-f$"; "")), skip: true} else {lang: $left, skip: false} end) as $leftinfo |

        (if $right == "" then
           $leftinfo + {name: ""}
         else
           (if ($right | test("-f$")) then
             $leftinfo + {name: ($right | sub("-f$"; "")), skip: true}
           else
             $leftinfo + {name: $right}
           end)
         end);

      parse_cfg($currentcfg) as $rule |
      .tracks |
      map(. as $track |
        (($rule.lang == "any" or $rule.lang == $track.language) as $lang_match |
          ($rule.name == "" or (($track.name // "") | ascii_downcase | contains(($rule.name // "") | ascii_downcase))) as $name_match |
          ($rule.skip and $track.forced) as $skipped |
          select($track.type == $type and $lang_match and $name_match and ($skipped | not) and .striptracks_keep)
        )
      ) |
      .[0].id // ""
    ')

    if [ -n "$track_id" ]; then
      # The track IDs must be converted to 1-based for mkvpropedit (add 1)
      # Set variable to set default only on selected track (unset others of same type)
      export striptracks_default_flags_org
      striptracks_default_flags_org+=" --edit track:$((track_id + 1)) --set flag-default=1"
      # Find other kept tracks of same type to unset default flag
      local unset_ids=$(echo "$striptracks_json_processed" | jq -crM --arg type "$tracktype" --argjson track_id "$track_id" '.tracks | map(select(.type == $type and .striptracks_keep and .id != $track_id) | .id) | join(",")')
      striptracks_default_flags_org+="$(echo $unset_ids | awk 'BEGIN {RS=","}; /[0-9]+/ {print " --edit track:" ($0 += 1) " --set flag-default=0"}' | tr -d '\n')"
      local message="Info|Setting ${tracktype} track ${track_id} as default$([ -n "$unset_ids" ] && echo " and removing default from track(s) '$unset_ids'")."
      echo "$message" | log
      # Remove leading space
      striptracks_default_flags_org="${striptracks_default_flags_org# }"
    else
      local message="Warn|No ${tracktype} track matched default specification '${currentcfg}'. No changes made to default ${tracktype} tracks."
      echo "$message" | log
    fi
  done

  if [ -n "$striptracks_default_flags_org" ]; then
    # Execute mkvpropedit to set default flags on tracks
    local mkvcommand="/usr/bin/mkvpropedit -q $striptracks_default_flags_org \"$(escape_string "$striptracks_video")\""
    execute_mkv_command "$mkvcommand" "setting default track flags"
  fi
}
set_default_tracks_org
set_default_tracks

if [ "$striptracks_default_flags" = "$striptracks_default_flags_org" ]; then
  echo -e "\t${ansi_green}Default flags test passed!${ansi_nc}"
else
  echo -e "${ansi_red}ERROR: New default flags differ from original processing!${ansi_nc}"
  echo -e "\tOriginal: $striptracks_default_flags_org"
  echo -e "\t     New: $striptracks_default_flags"
fi
