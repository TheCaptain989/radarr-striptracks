#!/bin/bash

# bash_unit tests
# Remux video file
# mkvtoolnix installed from BuildImage.yml

setup_suite() {
  which mkvmerge >/dev/null || { printf "\t\e[0;91mmkvmerge not found\e[0m\n"; exit 1; }
  source ../../root/usr/local/bin/striptracks.sh
  initialize_variables
  check_log >/dev/null
  export test_video1="Racism_is_evil.webm"
  export test_video2="vsshort-vorbis-subs.mkv"
  export test_video3="test5.mkv"
  fake log :
}

setup() {
  [ -f "$test_video1" ] || { wget -q "https://upload.wikimedia.org/wikipedia/commons/transcoded/e/e4/%27Racism_is_evil%2C%27_Trump_says.webm/%27Racism_is_evil%2C%27_Trump_says.webm.240p.vp9.webm?download" -O "$test_video1" && mkvmerge -J "$test_video1" >"${test_video1%.webm}.json"; }
  [ -f "$test_video2" ] || { wget -q "https://mkvtoolnix.download/samples/vsshort-vorbis-subs.mkv" && mkvmerge -J "$test_video2" >"${test_video2%.mkv}.json"; }
  [ -f "$test_video3" ] || { wget -q "https://github.com/ietf-wg-cellar/matroska-test-files/raw/refs/heads/master/test_files/test5.mkv" && mkvmerge -J "$test_video3" >"${test_video3%.mkv}.json"; }
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

test_set_mkvmerge_priority() {
  process_command_line -a :eng -p low -f "$test_video1"
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
  assert_equals "vsshort-vorbis-subs" "$(mkvmerge -J "$striptracks_video" | jq -crM '.container.properties.title')"
}

todo_mkvmerge_error() {
  # Must find an invalid video file that mkvmerge will error on
  process_command_line -a :eng -f "bear-1280x720-a_frag-cenc.mp4"
  initialize_mode_variables
  check_video
  get_mediainfo "$striptracks_video"
  process_mkvmerge_json
  assert_status_code 13 "remux_video 2>/dev/null"
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

teardown_suite() {
  rm -f "${test_video1%.webm}.mkv" "$test_video1" "$test_video2" "$test_video3" "${test_video2:0:5}.tmp".* "./striptracks.txt" "${test_video1%.webm}.json" "${test_video2%.mkv}.json" "${test_video3%.mkv}.json"
  unset striptracks_video test_video1 test_video2 test_video3
}
