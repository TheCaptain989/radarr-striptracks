#!/bin/bash

# bash_unit tests
# Eventtype

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  initialize_variables
  process_command_line -a :eng
  fake log :
}

test_unknown_eventtype() {
  assert_status_code 7 "initialize_mode_variables"
}

test_radarr_eventtype() {
  export radarr_eventtype="Import"
  initialize_variables
  initialize_mode_variables
  assert_equals "movie" "$striptracks_video_type"
}

test_sonarr_eventtype() {
  export sonarr_eventtype="Import"
  initialize_variables
  initialize_mode_variables
  assert_equals "series" "$striptracks_video_type"
}

test_unsupported_eventtype() {
  export radarr_eventtype="Grab"
  initialize_variables
  initialize_mode_variables
  assert_status_code 20 "check_eventtype 2>/dev/null"
}

test_test_event() {
  export radarr_eventtype="Test"
  initialize_variables
  initialize_mode_variables
  assert_equals "Info|Script was test executed successfully." "$(check_eventtype)"
}

teardown() {
  unset radarr_eventtype
  unset sonarr_eventtype
  unset striptracks_video_type
}
