#!/bin/bash

# bash_unit tests
# Tests for parse_language_codes_to_json

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  initialize_variables
}

test_parser_empty() {
  local out
  out=$(parse_language_codes_to_json "")
  assert_equals '[{"lang":"mis","limit":-1,"mods":[],"match":null},{"lang":"zxx","limit":-1,"mods":[],"match":null}]' "$(echo "$out" | jq -crM '.')"
}

test_parser_basic_counts() {
  local out
  out=$(parse_language_codes_to_json ":eng:fra+2")
  assert_equals "-1" "$(echo "$out" | jq -crM '.[] | select(.lang == "eng") | .limit')"
  assert_equals "2" "$(echo "$out" | jq -crM '.[] | select(.lang == "fra") | .limit')"
}

test_parser_forced_and_default() {
  local out
  out=$(parse_language_codes_to_json ":eng+f:fra+d")
  assert_equals "-1" "$(echo "$out" | jq -crM '.[] | select(.lang == "eng" and .mods[].forced) | .limit')"
  assert_equals "-1" "$(echo "$out" | jq -crM '.[] | select(.lang == "fra" and .mods[].default) | .limit')"
}

test_parser_name_match() {
  local out
  out=$(parse_language_codes_to_json ":eng-f=comment")
  assert_equals "comment" "$(echo "$out" | jq -crM '.[] | select(.lang == "eng" and .mods[].forced == false).match')"
}

teardown_suite() {
  unset striptracks_exitstatus
}