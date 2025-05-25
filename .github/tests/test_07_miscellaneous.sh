#!/bin/bash

# bash_unit tests
# Miscellaneous checks

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  initialize_variables
  fake log :
}

test_org_code() {
  fake check_compat :
  striptracks_type="radarr"
  striptracks_audiokeep=":eng:org"
  striptracks_originalLangCode=":eng"
  process_org_code audio striptracks_audiokeep
  assert_equals ":eng:eng" "$striptracks_audiokeep"
}
