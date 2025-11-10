#!/bin/bash

striptracks_type=Radarr
striptracks_pid=0
striptracks_api_url="http://localhost:7878/api/v3"
striptracks_apikey="NOT_A_REAL_API_KEY"
striptracks_video="test_video.mkv"
striptracks_videofile_api="movie"
striptracks_debug=2

log() {( while read -r; do echo "$(date +"%Y-%m-%d %H:%M:%S.%1N")|[$striptracks_pid]$REPLY"; done; )}
function delete_videofile {
  # Delete video file

  local videofile_id="$1"

  local return=0
  local i=0
  for ((i=1; i <= 5; i++)); do
    call_api 0 "Deleting or recycling \"$striptracks_video\"." "DELETE" "$striptracks_videofile_api/$videofile_id"
    local api_return=$?; [ $api_return -ne 0 ] && {
      # Exit loop if database is not locked, else wait
      if wait_if_locked; then
        local return=1
        break
      fi
    }
  done
  return $return
}
function call_api {
  # Call the Radarr/Sonarr API

  local debug_add=$1 # Value added to debug level when evaluating for JSON debug output
  local message="$2" # Message to log
  local method="$3" # HTTP method to use (GET, POST, PUT, DELETE)
  local endpoint="$4" # API endpoint to call
  local data # Data to send with the request. All subsequent arguments are treated as data.

  # Process remaining data values
  shift 4
  while (( "$#" )); do
    # Escape double quotes in data parameter
    local param="${1//\"/\\\"}"
    case "$param" in
      "{"*|"["*)
        data+=" --json \"$param\""
        shift
      ;;
      *=*)
        data+=" --data-urlencode \"$param\""
        shift
      ;;
      *)
        data+=" --data-raw \"$param\""
        shift
      ;;
    esac
  done

  local url="$striptracks_api_url/$endpoint"
  [ $striptracks_debug -ge 1 ] && echo "Debug|$message Calling ${striptracks_type^} API using $method and URL '$url'${data:+ with$data}" | log
  if [ "$method" = "GET" ]; then
    method="-G"
  else
    method="-X $method"
  fi
  local curl_cmd="curl -s --fail-with-body -H \"X-Api-Key: $striptracks_apikey\" -H \"Content-Type: application/json\" -H \"Accept: application/json\" ${data:+$data} $method \"$url\""
  [ $striptracks_debug -ge 2 ] && echo "Debug|Executing: $curl_cmd" | sed -E 's/(X-Api-Key: )[^"]+/\1[REDACTED]/' | log
  unset striptracks_result
  # (See issue #104)
  declare -g striptracks_result
  #striptracks_result=$(eval "$curl_cmd")
  # shellcheck disable=SC2089
  striptracks_result='{"message":"database is locked"}' # For testing wait_if_locked
  local curl_return=22; [ $curl_return -ne 0 ] && {
    # shellcheck disable=SC2090
    local message=$(echo -e "[$curl_return] curl error when calling: \"$url\"${data:+ with$data}\nWeb server returned: $(echo $striptracks_result | jq -jcM 'if type=="array" then map(.errorMessage) | join(", ") else (if has("title") then "[HTTP \(.status?)] \(.title?) \(.errors?)" elif has("message") then .message else "Unknown JSON format." end) end')" | awk '{print "Error|"$0}')
    echo "$message" | log
    echo "$message" >&2
  }
  # APIs can return A LOT of data, and it is not always needed for debugging
  [ $striptracks_debug -ge 2 ] && echo "Debug|API returned ${#striptracks_result} bytes." | log
  [ $striptracks_debug -ge $((2 + debug_add)) -a ${#striptracks_result} -gt 0 ] && echo "API returned: $striptracks_result" | awk '{print "Debug|"$0}' | log
  return $curl_return
}
function wait_if_locked {
  # Wait 1 minute if database is locked

  # Exit codes:
  #  0 - Database is locked
  #  1 - Database is not locked

  # shellcheck disable=SC2090
  if [[ "$(echo $striptracks_result | jq -jcM '.message?')" =~ database\ is\ locked ]]; then
    local return=1
    echo "Warn|Database is locked; system is likely overloaded. Sleeping 1 minute." | log
    sleep 1
  else 
    local return=0
  fi
  return $return
}

delete_videofile 1234