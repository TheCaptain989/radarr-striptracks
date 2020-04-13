#!/bin/bash

# Video remuxing script designed for use with Radarr and Sonarr
# Automatically strips out unwanted audio and subtitle streams, keeping only the desired languages.
#  https://github.com/TheCaptain989/radarr-striptracks

# Adapated and corrected from Endoro's post 1/5/2014:
#  https://forum.videohelp.com/threads/343271-BULK-remove-non-English-tracks-from-MKV-container#post2292889
#
# Put a colon `:` in front of every language code.  Expects ISO639-2 codes

# Dependencies:
#  mkvmerge
#  awk

# Exit codes:
#  0 - success
#  1 - no video file specified on command line
#  2 - no audio language specified on command line
#  3 - no subtitle language specified on command line
#  4 - mkvmerge not found
#  5 - specified video file not found
# 10 - remuxing completed, but no output file found

### Variables
export striptracks_script=$(basename "$0")
export striptracks_arr_config=/config/config.xml
export striptracks_log=/config/logs/striptracks.txt
export striptracks_maxlogsize=512000
export striptracks_maxlog=4
export striptracks_debug=0
export striptracks_video="$radarr_moviefile_path"
if [ "$striptracks_video" ]; then
  export striptracks_type="Radarr"
  export striptracks_video_type="movie"
else
  export striptracks_video="$sonarr_episodefile_path"
  if [ "$striptracks_video" ]; then
    export striptracks_type="Sonarr"
    export striptracks_video_type="series"
  fi
fi
export striptracks_api="Rescan${striptracks_video_type^}"
export striptracks_json_key="${striptracks_video_type}Id"
export striptracks_video_idname="${striptracks_type,,}_${striptracks_video_type}_id"
export striptracks_video_id="${!striptracks_video_idname}"
export striptracks_tempvideo="$striptracks_video.tmp"
export striptracks_newvideo="${striptracks_video%.*}.mkv"
export striptracks_title=$(basename "${striptracks_video%.*}")
export striptracks_recyclebin=$(sqlite3 /config/nzbdrone.db 'SELECT Value FROM Config WHERE Key="recyclebin"')

### Functions
function usage {
  usage="
$striptracks_script
Video remuxing script designed for use with Radarr and Sonarr

Source: https://github.com/TheCaptain989/radarr-striptracks

Usage:
  $0 [-d] <audio_languages> <subtitle_languages>

Arguments:
  audio_languages       # ISO639-2 code(s) prefixed with a colon \`:\`
                          Multiple codes may be concatenated.
  subtitle_languages    # ISO639-2 code(s) prefixed with a colon \`:\`
                          Multiple codes may be concatenated.

Options:
  -d    # enable debug logging

Examples:
  $striptracks_script :eng:und :eng              # keep English and Undetermined audio and
                                              English subtitles
  $striptracks_script :eng \"\"                    # keep English audio and no subtitles
  $striptracks_script -d :eng:kor:jpn :eng:spa   # Enable debugging, keeping English, Korean,
                                              and Japanese audio, and English and
                                              Spanish subtitles
"
  >&2 echo "$usage"
}
# Can still go over striptracks_maxlog if read line is too long
#  Must include whole function in subshell for read to work!
function log {(
  while read
  do
    echo $(date +"%Y-%-m-%-d %H:%M:%S.%1N")\|"$REPLY" >>"$striptracks_log"
    FILESIZE=`wc -c "$striptracks_log" | cut -d' ' -f1`
    if [ $FILESIZE -gt $striptracks_maxlogsize ]
    then
      for i in `seq $((striptracks_maxlog-1)) -1 0`
      do
        [ -f "${striptracks_log::-4}.$i.txt" ] && mv "${striptracks_log::-4}."{$i,$((i+1))}".txt"
      done
        [ -f "${striptracks_log::-4}.txt" ] && mv "${striptracks_log::-4}.txt" "${striptracks_log::-4}.0.txt"
      touch "$striptracks_log"
    fi
  done
)}
# Inspired by https://stackoverflow.com/questions/893585/how-to-parse-xml-in-bash
read_xml () {
  local IFS=\>
  read -d \< ENTITY CONTENT
}

# Process options
while getopts ":d" opt; do
  case ${opt} in
    d ) # For debug purposes only
      MSG="Debug|Enabling debug logging."
      echo "$MSG" | log
      >&2 echo "$MSG"
      striptracks_debug=1
      printenv | sort | sed 's/^/Debug|/' | log
    ;;
  esac
done
shift $((OPTIND -1))

if [ -z "$striptracks_video" ]; then
  MSG="Error|No video file specified! Not called from Radarr/Sonarr?"
  echo "$MSG" | log
  >&2 echo "$MSG"
  usage 
  exit 1
fi

if [ -z "$1" ]; then
  MSG="Error|No audio languages specified!"
  echo "$MSG" | log
  >&2 echo "$MSG"
  usage
  exit 2
fi

if [ -z "$2" ]; then
  MSG="Error|No subtitles languages specified!"
  echo "$MSG" | log
  >&2 echo "$MSG"
  usage
  exit 3
fi

if [ ! -f "/usr/bin/mkvmerge" ]; then
  MSG="Error|/usr/bin/mkvmerge is required by this script"
  echo "$MSG" | log
  >&2 echo "$MSG"
  exit 4
fi

if [ ! -f "$striptracks_video" ]; then
  MSG="Error|Input file not found: \"$striptracks_video\""
  echo "$MSG" | log
  >&2 echo "$MSG"
  exit 5
fi

if [ "$striptracks_type" = "Radarr" ]; then 
  MSG="Info|Radarr event: $radarr_eventtype, Movie: $striptracks_video, AudioKeep: $1, SubsKeep: $2"
else
  MSG="Info|Sonarr event: $sonarr_eventtype, Episode: $striptracks_video, AudioKeep: $1, SubsKeep: $2"
fi
echo "$MSG" | log
echo "" | awk -v Debug=$striptracks_debug -v OrgVideo="$striptracks_video" -v TempVideo="$striptracks_tempvideo" -v MKVVideo="$striptracks_newvideo" -v Title="$striptracks_title" -v AudioKeep="$1" -v SubsKeep="$2" '
BEGIN {
  MKVMerge="/usr/bin/mkvmerge"
  FS="[\t\n: ]"
  IGNORECASE=1
  if (match(Title,/[a-zA-Z0-9]- /)) {
    Arr[1]=substr(Title,1,RSTART)
    Arr[2]=substr(Title,RSTART+RLENGTH-1)
    Title=Arr[1]":"Arr[2]
  }  # mawk does not have gensub function

  if (Debug) print "Debug|Renaming: \""OrgVideo"\" to \""TempVideo"\""
  Result=system("mv \""OrgVideo"\" \""TempVideo"\"")
  if (Result) {
    print "Error|"Result" renaming \""OrgVideo"\"" > "/dev/stderr"
    exit
  }

  # Read in the output of mkvmerge
  exe=MKVMerge" --identify-verbose \""TempVideo"\""
  while ((exe | getline Line) > 0) {
    if (Debug) print "Debug|"Line
    FieldCount=split(Line, Fields)
    if (Fields[1]=="Track") {
      NoTr++
      Track[NoTr, "id"]=Fields[3]
      Track[NoTr, "typ"]=Fields[5]
      if (Fields[6]~/^\(/) {
        Track[NoTr, "code"]=substr(Line,1,match(Line,/\)/))
        sub(/^[^\(]+/,"",Track[NoTr, "code"])
      }
      if (Track[NoTr, "typ"]=="video") VidCnt++
      if (Track[NoTr, "typ"]=="audio") AudCnt++
      if (Track[NoTr, "typ"]=="subtitles") SubsCnt++
      for (i=6; i<=FieldCount; i++) {
        if (Fields[i]=="language") Track[NoTr, "lang"]=Fields[++i]
      }
    } else if (Fields[1]=="Chapters") {
      Chapters=Fields[3]
    }
  }
  if (!NoTr) { print "Error|No tracks found in \""TempVideo"\"" > "/dev/stderr"; exit }
  if (!AudCnt) AudCnt=0; if (!SubsCnt) SubsCnt=0
  print "Info|Original tracks: "NoTr" (audio: "AudCnt", subtitles: "SubsCnt")"
  if (Chapters) print "Info|Chapters: "Chapters
  for (i=1; i<=NoTr; i++) {
    if (Debug) print "Debug|i:"i,"Track ID:"Track[i,"id"],"Type:"Track[i,"typ"],"Lang:"Track[i, "lang"],"Code:"Track[i, "code"]
    if (Track[i, "typ"]=="audio") {
      if (AudioKeep~Track[i, "lang"]) {
        AudKpCnt++
        print "Info|Keeping audio track "Track[i, "id"]": "Track[i, "lang"]" "Track[i, "code"]
        if (AudioCommand=="") {
          AudioCommand=Track[i, "id"]
        } else {
          AudioCommand=AudioCommand","Track[i, "id"]
        }
      # Special case if there is only one audio track, even if it was not specified
      } else if (AudCnt==1) {
        print "Info|Keeping only audio track "Track[i, "id"]": "Track[i, "lang"]" "Track[i, "code"]
        AudioCommand=Track[i, "id"]
      # Special case if there were multiple tracks, none were selected, and this is the last one.
      } else if (AudioCommand=="" && Track[i, "id"]==AudCnt) {
        print "Info|Keeping last audio track "Track[i, "id"]": "Track[i, "lang"]" "Track[i, "code"]
        AudioCommand=Track[i, "id"]
      } else {
        if (Debug) print "Debug|\tRemove:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
      }
    } else {
      if (Track[i, "typ"]=="subtitles") {
        if (SubsKeep~Track[i, "lang"]) {
          SubsKpCnt++
          print "Info|Keeping subtitle track "Track[i, "id"]": "Track[i, "lang"]" "Track[i, "code"]
          if (SubsCommand=="") {
            SubsCommand=Track[i, "id"]
          } else {
            SubsCommand=SubsCommand","Track[i, "id"]
          }
        } else {
          if (Debug) print "Debug|\tRemove:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
        }
      }
    }
  }
  if (!AudKpCnt) AudKpCnt=0; if (!SubsKpCnt) SubsKpCnt=0
  print "Info|Kept tracks: "AudKpCnt+SubsKpCnt+VidCnt" (audio: "AudKpCnt", subtitles: "SubsKpCnt")"
  if (AudioCommand=="") {
    # This should never happen, but belt and suspenders
    CommandLine="-A"
  } else {
    CommandLine="-a "AudioCommand
  }
  if (SubsCommand=="") {
    CommandLine=CommandLine" -S"
  } else {
    CommandLine=CommandLine" -s "SubsCommand
  }
  if (Debug) print "Debug|Executing: "MKVMerge" --title \""Title"\" -q -o \""MKVVideo"\" "CommandLine" \""TempVideo"\""
  Result=system(MKVMerge" --title \""Title"\" -q -o \""MKVVideo"\" "CommandLine" \""TempVideo"\"")
  if (Result>1) print "Error|"Result" remuxing \""TempVideo"\"" > "/dev/stderr"
}' | log

# Check for script completion and non-empty file
if [ -s "$striptracks_newvideo" ]; then
  # Use Recycle Bin if configured
  if [ "$striptracks_recyclebin" ]; then
    [ $striptracks_debug -eq 1 ] && echo "Debug|Moving: \"$striptracks_tempvideo\" to \"${striptracks_recyclebin%/}/$(basename "$striptracks_video")"\" | log
    mv "$striptracks_tempvideo" "${striptracks_recyclebin%/}/$(basename "$striptracks_video")" | log
  else
    [ $striptracks_debug -eq 1 ] && echo "Debug|Deleting: \"$striptracks_tempvideo\"" | log
    rm "$striptracks_tempvideo" | log
  fi
else
  MSG="Error|Unable to locate or invalid remuxed file: \"$striptracks_newvideo\". Undoing rename."
  echo "$MSG" | log
  >&2 echo "$MSG"
  [ $striptracks_debug -eq 1 ] && echo "Debug|Renaming: \"$striptracks_tempvideo\" to \"$striptracks_video\"" | log
  mv -f "$striptracks_tempvideo" "$striptracks_video" | log
  exit 10
fi

# Call *arr API to RescanMovie/RescanSeries
if [ -f "$striptracks_arr_config" ]; then
  # Read *arr config.xml
  while read_xml; do
    [[ $ENTITY = "Port" ]] && PORT=$CONTENT
    [[ $ENTITY = "UrlBase" ]] && URLBASE=$CONTENT
    [[ $ENTITY = "BindAddress" ]] && BINDADDRESS=$CONTENT
    [[ $ENTITY = "ApiKey" ]] && APIKEY=$CONTENT
  done < $striptracks_arr_config
  
  [[ $BINDADDRESS = "*" ]] && BINDADDRESS=localhost
  
  if [ "$striptracks_video_id" ]; then
    [ $striptracks_debug -eq 1 ] && echo "Debug|Calling $striptracks_type API '$striptracks_api' using series id '$striptracks_video_id' and URL 'http://$BINDADDRESS:$PORT$URLBASE/api/command?apikey=$APIKEY'" | log
    # Calling API
    RESULT=$(curl -s -d "{name: '$striptracks_api', $striptracks_json_key: $striptracks_video_id}" -H "Content-Type: application/json" \
      -X POST http://$BINDADDRESS:$PORT$URLBASE/api/command?apikey=$APIKEY | jq -c ". | {JobId: .id, ${striptracks_json_key^}: .body.$striptracks_json_key, Message: .body.completionMessage, DateStarted: .queued}")
    [ $striptracks_debug -eq 1 ] && echo "Debug|API returned: $RESULT" | log
  else
    MSG="Warn|Missing environment variable $striptracks_video_idname"
    echo "$MSG" | log
    >&2 echo "$MSG"
  fi
else
  MSG="Warn|Unable to locate $striptracks_type config file: '$striptracks_arr_config'"
  echo "$MSG" | log
  >&2 echo "$MSG"
fi

MSG="Info|Completed in $(($SECONDS/60))m $(($SECONDS%60))s"
echo "$MSG" | log
