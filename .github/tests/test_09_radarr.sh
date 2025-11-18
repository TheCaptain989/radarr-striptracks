#!/bin/bash

# bash_unit tests
# Radarr API
# Radarr installed from BuildImage.yml

# Used for debugging unit tests
_log() {( while read -r; do echo "$(date +"%Y-%m-%d %H:%M:%S.%1N")|[$striptracks_pid]$REPLY" >>striptracks.txt; done; )}

setup_suite() {
  source ../../root/usr/local/bin/striptracks.sh
  fake log :
  export test_video1="Racism_is_evil.webm"
  export video1_dir="Carmencita (1894)"
  [ -d "$video1_dir" ] || mkdir "$video1_dir"
  [ -f "$test_video1" ] || { wget -q "https://upload.wikimedia.org/wikipedia/commons/transcoded/e/e4/%27Racism_is_evil%2C%27_Trump_says.webm/%27Racism_is_evil%2C%27_Trump_says.webm.240p.vp9.webm?download" -O "$video1_dir/$test_video1"; }
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
  assert_within_delta 6 ${striptracks_arr_version/.*/} 2
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

test_radarr_call_api_with_json() {
  check_eventtype
  check_config
  call_api 0 "Creating a test tag." "POST" "tag" '{"label":"test"}'
  assert_equals '{"label":"test","id":1}' "$(echo $striptracks_result | jq -jcM)"
}

test_radarr_call_api_with_urlencode() {
  check_eventtype
  check_config
  call_api 0 "Getting tmp filesystem info." "GET" "filesystem" "path=/tmp/"
  assert_equals '{"parent":"/","directories":[],"files":[]}' "$(echo $striptracks_result | jq -jcM)"
}

test_radarr_z01_video_load() {
  load_video
  radarr_movie_id=$(echo $striptracks_result | jq -crM '.id?')
  initialize_mode_variables
  rescan
  sleep 1
  while ! check_job $striptracks_jobid; do
    echo -n "Waiting for Radarr job $striptracks_jobid to complete..."
    sleep 1
  done
  get_video_info
  # Needed for next test
  echo $striptracks_result | jq -r >"$video1_dir/${test_video1%.webm}.json"
  assert_equals "Carmencita" "$(echo $striptracks_result | jq -crM '.title')"
}

test_radarr_z02_video_convert() {
  # fake log _log
  # striptracks_debug=1
  # Read in values from first test
  striptracks_result="$(cat "$video1_dir/${test_video1%.webm}.json")"
  radarr_moviefile_path="$(echo $striptracks_result | jq -crM '.movieFile.path')"
  radarr_moviefile_id="$(echo $striptracks_result | jq -crM '.movieFile.id')"
  radarr_movie_id="$(echo $striptracks_result | jq -crM '.id')"
  radarr_movie_path="$(echo $striptracks_result | jq -crM '.path')"
  radarr_movie_title="$(echo $striptracks_result | jq -crM '.title')"
  radarr_movie_year="$(echo $striptracks_result | jq -crM '.year')"
  process_command_line -a :eng
  initialize_mode_variables
  check_eventtype
  log_script_start
  check_config
  check_video
  detect_languages
  get_mediainfo "$striptracks_video"
  process_mkvmerge_json
  remux_video
  replace_original_video
  rescan_and_cleanup
  assert_equals 0 ${striptracks_exitstatus:-0}
}

test_radarr_z03_video_delete() {
  # Read in values from first test
  striptracks_result="$(cat "$video1_dir/${test_video1%.webm}.json")"
  radarr_moviefile_path="$(echo $striptracks_result | jq -crM '.movieFile.path')"
  radarr_moviefile_id="$(echo $striptracks_result | jq -crM '.movieFile.id')"
  radarr_movie_id="$(echo $striptracks_result | jq -crM '.id')"
  radarr_movie_path="$(echo $striptracks_result | jq -crM '.path')"
  radarr_movie_title="$(echo $striptracks_result | jq -crM '.title')"
  radarr_movie_year="$(echo $striptracks_result | jq -crM '.year')"
  assert_status_code 0 "delete_video"
}

load_video() {
  check_config
  call_api 0 "Loading video file into Radarr." "POST" "movie" "{\"QualityProfileId\":1, \"TmdbId\":16612, \"Title\":\"Carmencita\", \"path\":\"$PWD/$video1_dir\", \"monitored\":true, \"rootFolderPath\":\"$PWD/\", \"movieFile\":{\"id\":1, \"path\":\"$PWD/$video1_dir/$test_video1\", \"quality\":{\"quality\":{\"id\":1,\"name\":\"Any\"},\"revision\":{\"version\":1,\"real\":1}}}}"
}

delete_video() {
  check_config
  call_api 0 "Deleting video file from Radarr." "DELETE" "movie/$radarr_movie_id" "deleteFiles=true"
}

get_video_info() {
  call_api 0 "Getting video info from Radarr." "GET" "movie/$radarr_movie_id"
}

teardown_suite() {
  rm -f -d "./striptracks.txt" "$video1_dir/${test_video1%.webm}.mkv" "$video1_dir/${test_video1%.webm}.json" "$video1_dir/$test_video1" "$video1_dir"
  unset radarr_eventtype striptracks_arr_config
}
