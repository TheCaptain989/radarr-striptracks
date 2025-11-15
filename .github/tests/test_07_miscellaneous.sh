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
