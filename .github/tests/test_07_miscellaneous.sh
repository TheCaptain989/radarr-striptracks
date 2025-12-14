#!/bin/bash

# bash_unit tests
# Miscellaneous checks

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  initialize_variables
  fake log :
}

test_org_code_in_audio() {
  fake check_compat :
  striptracks_type="radarr"
  striptracks_audiokeep=":eng:org"
  striptracks_originalLangCode=":eng"
  process_org_code audio striptracks_audiokeep
  assert_equals ":eng:eng" "$striptracks_audiokeep"
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

test_set_default_with_skip_flag() {
  fake execute_mkv_command :
  export striptracks_json_processed='{"tracks":[{"id":0,"type":"video","language":"und","striptracks_keep":true},{"id":1,"type":"audio","language":"eng","name":"name","striptracks_keep":true},{"id":2,"type":"subtitles","language":"eng","name":"comment forced","forced":true,"striptracks_keep":true},{"id":3,"type":"subtitles","language":"eng","name":"comment","forced":false,"striptracks_keep":true}]}'
  export striptracks_default_subtitles=":eng-f"
  set_default_tracks
  assert_matches '--edit track:4 --set flag-default=1 --edit track:3 --set flag-default=0' "$striptracks_default_flags"
}

test_set_default_with_name() {
  fake execute_mkv_command :
  export striptracks_json_processed='{"tracks":[{"id":0,"type":"video","language":"und","striptracks_keep":true},{"id":1,"type":"audio","language":"eng","name":"name","striptracks_keep":true},{"id":2,"type":"subtitles","language":"eng","name":"comment forced","forced":true,"striptracks_keep":true},{"id":3,"type":"subtitles","language":"eng","name":"comment","forced":false,"striptracks_keep":true}]}'
  export striptracks_default_subtitles=":eng=comment"
  set_default_tracks
  assert_matches '--edit track:3 --set flag-default=1 --edit track:4 --set flag-default=0' "$striptracks_default_flags"
}

test_set_default_with_name_and_skip() {
  fake execute_mkv_command :
  export striptracks_json_processed='{"tracks":[{"id":0,"type":"video","language":"und","striptracks_keep":true},{"id":1,"type":"audio","language":"eng","name":"name","striptracks_keep":true},{"id":2,"type":"subtitles","language":"eng","name":"comment forced","forced":true,"striptracks_keep":true},{"id":3,"type":"subtitles","language":"eng","name":"comment","forced":false,"striptracks_keep":true}]}'
  export striptracks_default_subtitles=":eng=comment-f"
  set_default_tracks
  assert_matches '--edit track:4 --set flag-default=1 --edit track:3 --set flag-default=0' "$striptracks_default_flags"
}

test_set_default_with_name_and_skip_reverse() {
  fake execute_mkv_command :
  export striptracks_json_processed='{"tracks":[{"id":0,"type":"video","language":"und","striptracks_keep":true},{"id":1,"type":"audio","language":"eng","name":"name","striptracks_keep":true},{"id":2,"type":"subtitles","language":"eng","name":"comment forced","forced":true,"striptracks_keep":true},{"id":3,"type":"subtitles","language":"eng","name":"comment","forced":false,"striptracks_keep":true}]}'
  export striptracks_default_subtitles=":eng-f=comment"
  set_default_tracks
  assert_matches '--edit track:4 --set flag-default=1 --edit track:3 --set flag-default=0' "$striptracks_default_flags"
}
