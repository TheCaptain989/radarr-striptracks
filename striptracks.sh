#!/bin/bash

# Adapated and corrected from Endoro's post 1/5/2014:
#  https://forum.videohelp.com/threads/343271-BULK-remove-non-English-tracks-from-MKV-container#post2292889
#
# Put a colon `:` in front of every language code.  Expects ISO639-2 codes

RADARR_CONFIG=/config/config.xml
LOG=/config/logs/striptracks.txt
MAXLOGSIZE=1048576
MAXLOG=4
MOVIE="$radarr_moviefile_path"

# Not the most robust way to do this.  Expects 3 character file extension (i.e. ".avi")
NEWMOVIE=${MOVIE::-4}.new.mkv

# For debug purposes only
#ENVLOG=/config/logs/debugenv.txt
#echo --------$(date +"%F %T")-------- >>"$ENVLOG"
#printenv | sort >>"$ENVLOG"

function usage {
  [ -z "$MOVIE" ] && MOVIE=/path_to_movie/video.mkv
  echo "Examples:"
  echo " - keep English and Japanase audio and English subtitles"
  echo "   $0 $MOVIE :eng:jpn :eng"
  echo " - keep English audio and no subtitles"
  echo "   $0 $MOVIE :eng \"\""
  echo
  echo " Put a colon \`:\` in front of every language code.  Expects ISO639-2 codes"
}

# Can still go over MAXLOG if read line is too long
#  Must include whole function in subshell for read to work!
function log {(
  while read
  do
    echo $(date +"%F %T")\|"$REPLY" >>"$LOG"
    FILESIZE=`wc -c "$LOG" | cut -d' ' -f1`
    if [ $FILESIZE -gt $MAXLOGSIZE ]
    then
      for i in `seq $((MAXLOG-1)) -1 0`
      do
        [ -f "${LOG::-4}.$i.txt" ] && mv "${LOG::-4}."{$i,$((i+1))}".txt"
      done
      touch "$LOG"
    fi
  done
)}

if [ -z "$MOVIE" ]
then
  MSG="ERROR: No movie file specified! Not called from Radarr?"
  echo "$MSG" | log
  echo "$MSG"
  usage 
  exit 1
fi

if [ ! -f "$MOVIE" ]
then
  MSG="ERROR: Input file not found: \"$MOVIE\""
  echo "$MSG" | log
  echo "$MSG"
  exit 5
fi

if [ -z "$1" ]
then
  MSG="ERROR: No audio languages specified!"
  echo "$MSG" | log
  echo "$MSG"
  usage
  exit 2
fi

if [ -z "$2" ]
then
  MSG="ERROR: No subtitles languages specified!"
  echo "$MSG" | log
  echo "$MSG"
  usage
  exit 3
fi

echo "Radarr event: $radarr_eventtype|Movie: $MOVIE|AudioKeep: $1|SubsKeep: $2" | log
awk '
BEGIN {
  MKVMerge="/usr/bin/mkvmerge"
  FS="[\t\n: ]"
  IGNORECASE=1
  MKVVideo=ARGV[1]
  AudioKeep=ARGV[2]
  SubsKeep=ARGV[3]
  NewVideo=substr(MKVVideo, 1, length(MKVVideo)-4)".new.mkv"
  Title=substr(MKVVideo, 1, length(MKVVideo)-4)
  sub(".*/", "", Title)
  exe=MKVMerge" --identify-verbose \""MKVVideo"\""
  while ((exe | getline Line) > 0) {
    print Line
    FieldCount=split(Line, Fields)
    if (Fields[1]=="Track") {
      NoTr++
      Track[NoTr, "id"]=Fields[3]
      Track[NoTr, "typ"]=Fields[5]
      if (Track[NoTr, "typ"]=="audio") AudCnt++
      for (i=6; i<=FieldCount; i++) {
        if (Fields[i]=="language") Track[NoTr, "lang"]=Fields[++i]
      }
    }
  }
  if (NoTr==0) {
    print "ERROR: No tracks found in "MKVVideo"."
    exit
  } else {print "Tracks:",NoTr,", Audio Tracks:",AudCnt}
  for (i=1; i<=NoTr; i++) {
    #print "i:"i,"Track ID:"Track[i,"id"],"Type:"Track[i,"typ"],"Lang:"Track[i, "lang"]
    if (Track[i, "typ"]=="audio") {
      if (AudioKeep~Track[i, "lang"]) {
        print "Keep:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
        if (AudioCommand=="") {
          AudioCommand=Track[i, "id"]
        } else {
          AudioCommand=AudioCommand","Track[i, "id"]
        }
      } else if(AudCnt==1) {
        print "Keeping only audio track:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
        AudioCommand=Track[i, "id"]
      } else if(AudioCommand=="" && Track[i, "id"]==AudCnt) {
        print "Keeping last audio track:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
        AudioCommand=Track[i, "id"]
      } else {
        print "\tRemove:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
      }
    } else {
      if (Track[i, "typ"]=="subtitles") {
        if (SubsKeep~Track[i, "lang"]) {
          print "Keep:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
          if (SubsCommand=="") {
            SubsCommand=Track[i, "id"]
          } else {
            SubsCommand=SubsCommand","Track[i, "id"]
          }
        } else {
          print "\tRemove:", Track[i, "typ"], "track", Track[i, "id"], Track[i, "lang"]
        }
      }
    }
  }
  if (AudioCommand=="") {
    CommandLine="-A"
  } else {
    CommandLine="-a "AudioCommand
  }
  if (SubsCommand=="") {
    CommandLine=CommandLine" -S"
  } else {
    CommandLine=CommandLine" -s "SubsCommand
  }
  print "Executing: "MKVMerge" -o \""NewVideo"\" "CommandLine" \""MKVVideo"\""
  Result=system(MKVMerge" --title \""Title"\" -q -o \""NewVideo"\" "CommandLine" \""MKVVideo"\"")
  if (Result>1) print "ERROR: "Result" muxing \""MKVVideo"\""
}' "$MOVIE" "$1" "$2" | log

# Replace downloaded movie file
if [ -f "$NEWMOVIE" ]
then
  echo "Deleting: \"$MOVIE\"" | log
  rm "$MOVIE"
  echo "Moving: \"$NEWMOVIE\" to \"${MOVIE::-4}.mkv\"" | log
  mv "$NEWMOVIE" "${MOVIE::-4}.mkv"
else
  MSG="ERROR: Unable to locate remuxed file: \"$NEWMOVIE\""
  echo "$MSG" | log
  echo "$MSG"
  exit 10
fi

# Call Radarr API to RescanMovie
if [ ! -z "$radarr_movie_id" ]
then
  # Inspired by https://stackoverflow.com/questions/893585/how-to-parse-xml-in-bash
  read_xml () {
    local IFS=\>
    read -d \< ENTITY CONTENT
  }
  
  # Read Radarr config.xml
  while read_xml; do
    [[ $ENTITY = "Port" ]] && PORT=$CONTENT
    [[ $ENTITY = "UrlBase" ]] && URLBASE=$CONTENT
    [[ $ENTITY = "BindAddress" ]] && BINDADDRESS=$CONTENT
    [[ $ENTITY = "ApiKey" ]] && APIKEY=$CONTENT
  done < $RADARR_CONFIG
  
  [[ $BINDADDRESS = "*" ]] && BINDADDRESS=localhost
  
  echo "Calling Radarr API using movie id '$radarr_movie_id' and URL 'http://$BINDADDRESS:$PORT$URLBASE/api/command?apikey=$APIKEY'" | log
  # Calling API
  RESULT=$(curl -s -d "{name: 'RescanMovie', movieId: $radarr_movie_id}" -H "Content-Type: application/json" \
    -X POST http://$BINDADDRESS:$PORT$URLBASE/api/command?apikey=$APIKEY | jq -c '. | {JobId: .id, MovieId: .body.movieId, Message: .body.completionMessage, DateStarted: .queued}')
  echo "API returned: $RESULT" | log
else
  MSG="ERROR: Missing environment variable radarr_movie_id"
  echo "$MSG" | log
  echo "$MSG"
  exit 11
fi

echo "Done" | log
