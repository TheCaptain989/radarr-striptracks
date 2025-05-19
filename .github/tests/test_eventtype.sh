#!/bin/bash

# bash_unit test

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  initialize_variables
  process_command_line -a :eng
}

test_unknown_eventtype() {
  assert_status_code 7 "initialize_mode_variables"
}

test_radarr_eventtype() {
  export radarr_eventtype="import"
  initialize_variables
  initialize_mode_variables
  assert_equals "movie" "$striptracks_video_type"
}

test_sonarr_eventtype() {
  export sonarr_eventtype="import"
  initialize_variables
  initialize_mode_variables
  assert_equals "series" "$striptracks_video_type"
}
