#!/bin/bash

# bash_unit tests
# Miscellaneous checks

# Used for debugging unit tests
_log() {( while read -r; do echo "$(date +"%Y-%m-%d %H:%M:%S.%1N")|[$striptracks_pid]$REPLY"; done; )}

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  initialize_variables
  fake log :
}

test_org_code_in_audio() {
  fake check_compat :
  striptracks_type="radarr"
  striptracks_audiokeep=":eng:org"
  striptracks_originalLangCode=":jpn"
  process_org_code audio striptracks_audiokeep
  assert_equals ":eng:jpn" "$striptracks_audiokeep"
}

test_org_code_in_default_subtitles() {
  fake check_compat :
  striptracks_type="radarr"
  striptracks_default_subtitles=":org"
  striptracks_originalLangCode=":eng"
  process_org_code subtitles striptracks_default_subtitles
  assert_equals ":eng" "$striptracks_default_subtitles"
}

test_track_reorder() {
  export striptracks_json_processed='{"tracks":[{"id":0,"type":"video","language":"und","striptracks_keep":true},{"id":1,"type":"audio","language":"eng","name":"name","striptracks_keep":true},{"id":2,"type":"subtitles","language":"fra","name":"comment forced","forced":true,"striptracks_keep":true},{"id":3,"type":"subtitles","language":"eng","name":"comment","forced":false,"striptracks_keep":true}]}'  
  export striptracks_audiokeep=":eng"
  export striptracks_subskeep=":eng:fra"
  export striptracks_reorder="true"
  determine_track_order
  assert_equals "0:0,0:1,0:3,0:2" "$striptracks_neworder"
}

test_map_default_with_skip_flag() {
  fake execute_mkv_command :
  export striptracks_json_processed='{"tracks":[{"id":0,"type":"video","language":"und","striptracks_keep":true},{"id":1,"type":"audio","language":"eng","name":"name","striptracks_keep":true},{"id":2,"type":"subtitles","language":"eng","name":"comment forced","forced":true,"striptracks_keep":true},{"id":3,"type":"subtitles","language":"eng","name":"comment","forced":false,"striptracks_keep":true}]}'
  export striptracks_default_subtitles=":eng-f"
  map_default_tracks
  assert_matches '--default-track-flag 3:1 --default-track-flag 2:0' "$striptracks_mkvmerge_default_args"
  assert_matches '--edit track:4 --set flag-default=1 --edit track:3 --set flag-default=0' "$striptracks_mkvpropedit_default_args"
}

test_map_default_with_name() {
  fake execute_mkv_command :
  export striptracks_json_processed='{"tracks":[{"id":0,"type":"video","language":"und","striptracks_keep":true},{"id":1,"type":"audio","language":"eng","name":"name","striptracks_keep":true},{"id":2,"type":"subtitles","language":"eng","name":"comment forced","forced":true,"striptracks_keep":true},{"id":3,"type":"subtitles","language":"eng","name":"comment","forced":false,"striptracks_keep":true}]}'
  export striptracks_default_subtitles=":eng=comment"
  map_default_tracks
  assert_matches '--default-track-flag 2:1 --default-track-flag 3:0' "$striptracks_mkvmerge_default_args"
  assert_matches '--edit track:3 --set flag-default=1 --edit track:4 --set flag-default=0' "$striptracks_mkvpropedit_default_args"
}

test_map_default_with_name_and_skip() {
  fake execute_mkv_command :
  export striptracks_json_processed='{"tracks":[{"id":0,"type":"video","language":"und","striptracks_keep":true},{"id":1,"type":"audio","language":"eng","name":"name","striptracks_keep":true},{"id":2,"type":"subtitles","language":"eng","name":"comment forced","forced":true,"striptracks_keep":true},{"id":3,"type":"subtitles","language":"eng","name":"comment","forced":false,"striptracks_keep":true}]}'
  export striptracks_default_subtitles=":eng-f=comment"
  map_default_tracks
  assert_matches '--default-track-flag 3:1 --default-track-flag 2:0' "$striptracks_mkvmerge_default_args"
  assert_matches '--edit track:4 --set flag-default=1 --edit track:3 --set flag-default=0' "$striptracks_mkvpropedit_default_args"
}

test_map_default_multiple_codes() {
  fake execute_mkv_command :
  export striptracks_json_processed='{"tracks":[{"id":0,"type":"video","language":"und","striptracks_keep":true},{"id":1,"type":"audio","language":"eng","name":"name","striptracks_keep":true},{"id":2,"type":"audio","language":"fra","name":"comment forced","forced":true,"striptracks_keep":true},{"id":3,"type":"subtitles","language":"eng","name":"comment","forced":false,"striptracks_keep":true}]}'
  export striptracks_default_audio=":dut:fra"
  map_default_tracks
  assert_matches '--default-track-flag 2:1 --default-track-flag 1:0' "$striptracks_mkvmerge_default_args"
  assert_matches '--edit track:3 --set flag-default=1 --edit track:2 --set flag-default=0' "$striptracks_mkvpropedit_default_args"
}

test_process_mkvmerge_json_keeps_matching_tracks() {
  export striptracks_debug=0
  export striptracks_json='{"tracks":[{"id":0,"type":"video","codec":"avc1","properties":{"language":null,"track_name":""}},{"id":1,"type":"audio","codec":"aac","properties":{"language":"eng","track_name":"English","default_track":true,"forced_track":false}},{"id":2,"type":"audio","codec":"aac","properties":{"language":"fra","track_name":"French","default_track":false,"forced_track":false}},{"id":3,"type":"subtitles","codec":"subrip","properties":{"language":"eng","track_name":"English","default_track":true,"forced_track":false}},{"id":4,"type":"subtitles","codec":"subrip","properties":{"language":"fra","track_name":"French","default_track":false,"forced_track":false}}]}'
  export striptracks_audiokeep=":eng"
  export striptracks_subskeep=":eng"
  process_mkvmerge_json
  # Check that English audio is kept
  assert_equals "true" "$(echo "$striptracks_json_processed" | jq -crM '.tracks[] | select(.type == "audio" and .language == "eng") | .striptracks_keep')"
  # Check that French audio is not kept
  assert_equals "false" "$(echo "$striptracks_json_processed" | jq -crM '.tracks[] | select(.type == "audio" and .language == "fra") | .striptracks_keep')"
  # Check that English subtitles are kept
  assert_equals "true" "$(echo "$striptracks_json_processed" | jq -crM '.tracks[] | select(.type == "subtitles" and .language == "eng") | .striptracks_keep')"
}

test_process_mkvmerge_json_handles_forced_subtitles() {
  export striptracks_debug=0
  export striptracks_json='{"tracks":[{"id":0,"type":"video","codec":"avc1","properties":{"language":null,"track_name":""}},{"id":1,"type":"audio","codec":"aac","properties":{"language":"eng","track_name":"English","default_track":true,"forced_track":false}},{"id":2,"type":"subtitles","codec":"subrip","properties":{"language":"eng","track_name":"English (Forced)","default_track":false,"forced_track":true}},{"id":3,"type":"subtitles","codec":"subrip","properties":{"language":"eng","track_name":"English","default_track":true,"forced_track":false}}]}'
  export striptracks_audiokeep=":eng"
  export striptracks_subskeep=":eng-f"
  process_mkvmerge_json
  # Check that forced English subtitle (track 2) is excluded
  assert_equals "false" "$(echo "$striptracks_json_processed" | jq -crM '.tracks[] | select(.type == "subtitles" and .language == "eng" and .forced == true) | .striptracks_keep')"
}

test_process_mkvmerge_json_complex_modifiers() {
  export striptracks_debug=0
  export striptracks_json='{"tracks":[{"id":0,"type":"video","codec":"avc1","properties":{"language":null,"track_name":""}},{"id":1,"type":"audio","codec":"aac","properties":{"language":"eng","track_name":"English","default_track":true,"forced_track":false}},{"id":2,"type":"audio","codec":"aac","properties":{"language":"eng","track_name":"English (Forced)","default_track":false,"forced_track":true}},{"id":3,"type":"audio","codec":"aac","properties":{"language":"eng","track_name":"English (Forced)","default_track":false,"forced_track":true}},{"id":4,"type":"audio","codec":"aac","properties":{"language":"fra","track_name":"French","default_track":false,"forced_track":false}},{"id":5,"type":"audio","codec":"aac","properties":{"language":"fra","track_name":"French Alt","default_track":false,"forced_track":false}},{"id":6,"type":"audio","codec":"aac","properties":{"language":"fra","track_name":"French 3","default_track":false,"forced_track":false}}]}'
  export striptracks_audiokeep=":eng+f:fra+1"
  export striptracks_subskeep=""
  process_mkvmerge_json
  # Check that all forced English audio tracks are kept (forced modifier)
  assert_equals "2" "$(echo "$striptracks_json_processed" | jq -crM '[.tracks[] | select(.type == "audio" and .language == "eng" and .forced == true and .striptracks_keep)] | length')"
  # Check that exactly 1 French audio track is kept (limit modifier)
  assert_equals "1" "$(echo "$striptracks_json_processed" | jq -crM '[.tracks[] | select(.type == "audio" and .language == "fra" and .striptracks_keep)] | length')"
  # Check that non-forced English is not kept
  assert_equals "false" "$(echo "$striptracks_json_processed" | jq -crM '.tracks[] | select(.type == "audio" and .language == "eng" and .forced == false) | .striptracks_keep')"
}

teardown() {
  unset striptracks_json_processed striptracks_audiokeep striptracks_default_subtitles striptracks_neworder striptracks_mkvmerge_default_args striptracks_mkvpropedit_default_args
}
