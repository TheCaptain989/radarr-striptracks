#!/bin/bash

# bash_unit tests
# Radarr API
# Radarr installed from BuildImage.yml

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  fake log :
  export test_video1="Racism_is_evil.webm"
}

setup() {
  export radarr_eventtype="Import"
  initialize_variables
  initialize_mode_variables
  check_log >/dev/null
  check_required_binaries
  [ -f "$test_video1" ] || { wget -q "https://upload.wikimedia.org/wikipedia/commons/transcoded/e/e4/%27Racism_is_evil%2C%27_Trump_says.webm/%27Racism_is_evil%2C%27_Trump_says.webm.240p.vp9.webm?download" -O "$test_video1"; }
}

test_radarr_test_event() {
  export radarr_eventtype="Test"
  initialize_mode_variables
  assert_equals "Info|Script was test executed successfully." "$(check_eventtype)"
}

test_radarr_version() {
  check_eventtype
  check_config
  assert_within_delta 5 ${striptracks_arr_version/.*/} 1
}

test_radarr_get_languages() {
  check_eventtype
  check_config
  get_language_codes
  assert_equals "English" "$(echo $striptracks_result | jq -crM '.[] | select(.id == 1) | .name')"
}

test_radarr_get_quality_profiles() {
  check_eventtype
  check_config
  get_profiles quality
  assert_equals "Any" "$(echo $striptracks_result | jq -crM '.[] | select(.id == 1) | .name')"
}

todo_radarr_detect_languages() {
  # Must load the video into Radarr first
  # Bad assert
  radarr_moviefile_path="$test_video1"
  process_command_line -a :eng --skip-profile "Any"
  check_eventtype
  check_config
  check_video
  detect_languages
  # assert_equals "1" "$striptracks_detected_language"
}

teardown_suite() {
  rm -f "./striptracks.txt"
  unset radarr_eventtype striptracks_arr_config
}
