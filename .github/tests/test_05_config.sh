#!/bin/bash

# bash_unit tests
# Configuration file

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  export radarr_eventtype="Import"
  initialize_variables
  initialize_mode_variables
  fake log :
}

test_api_url() {
  fake get_version :
  fake check_compat :
  check_config
  assert_equals "http://localhost:7878/api/v3" "$striptracks_api_url"
}

test_api_curl_failure() {
  fake get_version return 1
  assert_status_code 17 "check_config 2>/dev/null"
}

test_api_bad_version() {
  fake get_version :
  fake check_compat return 1
  assert_status_code 8 "check_config 2>/dev/null"
}

teardown_suite() {
  unset radarr_eventtype striptracks_arr_config
}
