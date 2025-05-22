#!/bin/bash

# bash_unit tests
# Remux video file

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
  [ -f "$test_video1" ] || wget -q "https://upload.wikimedia.org/wikipedia/commons/transcoded/e/e4/%27Racism_is_evil%2C%27_Trump_says.webm/%27Racism_is_evil%2C%27_Trump_says.webm.240p.vp9.webm?download" -O "$test_video1"
  [ -f "$test_video2" ] || wget -q "https://mkvtoolnix.download/samples/vsshort-vorbis-subs.mkv"
  [ -f "$test_video3" ] || wget -q "https://github.com/ietf-wg-cellar/matroska-test-files/raw/refs/heads/master/test_files/test5.mkv"
}

test_get_media_info() {
  process_command_line -a :eng -f "$test_video1"
  get_mediainfo "$test_video1"
  assert_equals "true" "$(echo $striptracks_json | jq -crM '.container.supported')"
}

test_remux_video() {
  process_command_line -a :eng -f "$test_video1"
  check_video
  get_mediainfo "$striptracks_video"
  process_mkvmerge_json
  remux_video
  assert "test -f \"$striptracks_tempvideo\" && rm -f \"$striptracks_tempvideo\""
}

test_remove_all_subtitles() {
  process_command_line -a :eng -f "$test_video2"
  initialize_mode_variables
  check_video
  get_mediainfo "$striptracks_video"
  process_mkvmerge_json
  remux_video
  set_perms_and_owner
  replace_original_video
  assert_equals "" "$(/usr/bin/mkvmerge -J "$striptracks_video" | jq '.tracks[] | select(.type == "subtitles")')"
}

teardown_suite() {
  rm -f "${test_video1%.webm}.mkv" "$test_video1" "$test_video2" "$test_video3" "./striptracks.txt"
}
