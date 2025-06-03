#!/bin/bash

# bash_unit tests
# Radarr API

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  fake log :
}

setup() {
  export radarr_eventtype="Import"
  initialize_variables
  initialize_mode_variables
  check_log >/dev/null
  check_required_binaries
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

teardown_suite() {
  rm -f "./striptracks.txt"
  unset radarr_eventtype striptracks_arr_config
}
