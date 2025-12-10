#!/bin/bash

# bash_unit tests
# Remux video file
# mkvtoolnix installed from BuildImage.yml

# Used for debugging unit tests
_log() {( while read -r; do echo "$(date +"%Y-%m-%d %H:%M:%S.%1N")|[$striptracks_pid]$REPLY" >>striptracks.txt; done; )}

setup_suite() {
  which mkvmerge >/dev/null || { printf "\t\e[0;91mmkvmerge not found\e[0m\n"; exit 1; }
  source ../../root/usr/local/bin/striptracks.sh
  initialize_variables
  check_log >/dev/null
  export test_video1="Racism_is_evil.webm"
  export test_video2="vsshort - vorbis  -  subs.mkv"
  export test_video3="test5.mkv"
  # shellcheck disable=SC2016
  export test_video4='$5 a Day (2008).mkv'
  export test_video5='bear-1280x720-a_frag-cenc.mp4'
  fake log :
}

setup() {
  [ -f "$test_video1" ] || { wget -q "https://upload.wikimedia.org/wikipedia/commons/transcoded/e/e4/%27Racism_is_evil%2C%27_Trump_says.webm/%27Racism_is_evil%2C%27_Trump_says.webm.240p.vp9.webm?download" -O "$test_video1" && mkvmerge -J "$test_video1" >"${test_video1%.webm}.json"; }
  [ -f "$test_video2" ] || { wget -q "https://mkvtoolnix.download/samples/vsshort-vorbis-subs.mkv" -O "$test_video2" && mkvmerge -J "$test_video2" >"${test_video2%.mkv}.json"; }
  [ -f "$test_video3" ] || { wget -q "https://github.com/ietf-wg-cellar/matroska-test-files/raw/refs/heads/master/test_files/test5.mkv" -O "$test_video3" && mkvmerge -J "$test_video3" >"${test_video3%.mkv}.json"; }
  [ -f "$test_video4" ] || cp "$test_video3" "$test_video4"
}

test_get_media_info() {
  process_command_line -a :eng -f "$test_video1"
  get_mediainfo "$test_video1"
  assert_equals "true" "$(echo "$striptracks_json" | jq -crM '.container.supported')"
}

test_remux_video() {
  process_command_line -a :eng -f "$test_video1"
  check_video
  get_mediainfo "$striptracks_video"
  process_mkvmerge_json
  remux_video
  assert "test -f \"$striptracks_tempvideo\" && rm -f \"$striptracks_tempvideo\""
}

test_remux_video_replace() {
  process_command_line -a :eng -f "$test_video1"
  initialize_mode_variables
  check_video
  get_mediainfo "$striptracks_video"
  process_mkvmerge_json
  remux_video
  replace_original_video
  assert "test -f \"$striptracks_newvideo\""
}

test_mkvmerge_idle_priority() {
  process_command_line -a :eng --priority idle -f "$test_video1"
  initialize_mode_variables
  check_video
  get_mediainfo "$striptracks_video"
  process_mkvmerge_json
  remux_video
  replace_original_video
  assert "test -f \"$striptracks_newvideo\""
}

test_mkvmerge_low_priority() {
  process_command_line -a :eng --priority low -f "$test_video1"
  initialize_mode_variables
  check_video
  get_mediainfo "$striptracks_video"
  process_mkvmerge_json
  remux_video
  replace_original_video
  assert "test -f \"$striptracks_newvideo\""
}

test_mkvmerge_medium_priority() {
  process_command_line -a :eng --priority medium -f "$test_video1"
  initialize_mode_variables
  check_video
  get_mediainfo "$striptracks_video"
  process_mkvmerge_json
  remux_video
  replace_original_video
  assert "test -f \"$striptracks_newvideo\""
}

test_mkvmerge_high_priority() {
  process_command_line -a :eng --priority high -f "$test_video1"
  initialize_mode_variables
  check_video
  get_mediainfo "$striptracks_video"
  process_mkvmerge_json
  remux_video
  replace_original_video
  assert "test -f \"$striptracks_newvideo\""
}

test_remove_all_subtitles() {
  process_command_line -a :eng -f "$test_video2"
  initialize_mode_variables
  check_video
  get_mediainfo "$striptracks_video"
  process_mkvmerge_json
  remux_video
  assert_equals "" "$(mkvmerge -J "$striptracks_tempvideo" | jq -crM '.tracks[] | select(.type == "subtitles")')"
}

test_set_title_only() {
  fake end_script :
  process_command_line -a :und -s :und -f "$test_video2"
  initialize_mode_variables
  check_video
  get_mediainfo "$striptracks_video"
  process_mkvmerge_json
  set_title_and_exit_if_nothing_removed
  assert_equals "vsshort - vorbis  -  subs" "$(mkvmerge -J "$striptracks_video" | jq -crM '.container.properties.title')"
}

test_unsupported_container() {
  touch $test_video5
  process_command_line -a :eng -f "$test_video5"
  initialize_mode_variables
  check_video
  assert_status_code 9 "get_mediainfo \"$striptracks_video\""
}

todo_corrupted_video() {
  # Must find video file that mkvmerge considers corrupted for this test to be valid
  process_command_line -a :eng -f "$test_video6"
  initialize_mode_variables
  check_video
  get_mediainfo "$striptracks_video"
  process_mkvmerge_json
  assert_status_code 13 "remux_video"
}

test_temp_file_deleted() {
  process_command_line -a :eng -f "$test_video3"
  initialize_mode_variables
  check_video
  get_mediainfo "$striptracks_video"
  process_mkvmerge_json
  remux_video
  rm -f "$striptracks_tempvideo"
  assert_status_code 10 "replace_original_video 2>/dev/null"
}

test_set_default_audio() {
  # fake log _log
  # striptracks_debug=1
  process_command_line -a :any -f "$test_video3" --set-default-audio :eng=commentary
  initialize_mode_variables
  check_video
  get_mediainfo "$striptracks_video"
  process_mkvmerge_json
  set_default_tracks
  remux_video
  replace_original_video
  assert_equals true "$(mkvmerge -J "$striptracks_video" | jq -crM '.tracks[] | select(.type == "audio" and .properties.track_name == "Commentary") | .properties.default_track')"
}

test_video_with_special_characters() {
  process_command_line -a :eng -f "$test_video4"
  initialize_mode_variables
  check_video
  get_mediainfo "$striptracks_video"
  assert_equals "true" "$(echo "$striptracks_json" | jq -crM '.container.supported')"
}

teardown_suite() {
  rm -f "${test_video1%.webm}.mkv" "$test_video1" "$test_video2" "$test_video3" "$test_video4" "$test_video5" "${test_video2:0:5}.tmp".* "./striptracks.txt" "${test_video1%.webm}.json" "${test_video2%.mkv}.json" "${test_video3%.mkv}.json"
  unset striptracks_video test_video1 test_video2 test_video3
}
