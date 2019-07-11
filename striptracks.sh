#!/bin/bash

# Adapated and corrected from Endoro's post 1/5/2014:
#  https://forum.videohelp.com/threads/343271-BULK-remove-non-English-tracks-from-MKV-container#post2292889
#
# Put a colon `:` in front of every language code.  Expects ISO639-2 codes

LOG=/config/logs/striptracks.txt
MOVIE="$radarr_moviefile_path"
NEWMOVIE=${MOVIE::-4}.new.mkv

# For debug purposes only
#ENVLOG=/config/logs/debugenv.txt
#echo --------$(date +"%F %T")-------- >>"$ENVLOG"
#printenv | sort >>"$ENVLOG"

function usage {
  [ -z "$MOVIE" ] && MOVIE=/path_to_movie/video.mkv
  echo Examples:
  echo " - keep English and Japanase audio and English subtitles"
  echo "   $0 $MOVIE :eng:jpn :eng"
  echo " - keep English audio and no subtitles"
  echo "   $0 $MOVIE :eng \"\""
  echo
  echo " Put a colon \`:\` in front of every language code.  Expects ISO639-2 codes"
}

if [ -z "$MOVIE" ]
then
  echo $(date +"%F %T")\|Error: No movie file found\! >>"$LOG"
  echo Error: No movie file specified\!
  usage
  exit 1
fi

if [ ! -f "$MOVIE" ]
then
  echo $(date +"%F %T")\|Error: File "$MOVIE" not found. >>"$LOG"
  echo Error: File "$MOVIE" not found.
  exit 5
fi

if [ -z "$1" ]
then
  echo $(date +"%F %T")\|Error: No audio languages specified\! >>"$LOG"
  echo Error: No audio languages specified\!
  usage
  exit 2
fi

if [ -z "$2" ]
then
  echo $(date +"%F %T")\|Error: No subtitles languages specified\! >>"$LOG"
  echo Error: No subtitles languages specified\!
  usage
  exit 3
fi

echo $(date +"%F %T")\|Event: "$radarr_eventtype"\|Video: "$MOVIE"\|AudioKeep: "$1"\|SubsKeep: "$2" >>"$LOG"
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
      for (i=6; i<=FieldCount; i++) {
        if (Fields[i]=="language") Track[NoTr, "lang"]=Fields[++i]
      }
    }
  }
  if (NoTr==0) {
    print "Error! No tracks found in "MKVVideo"."
    exit
  } else {print MKVVideo":", NoTr, "tracks found."}
  for (i=1; i<=NoTr; i++) {
    if (Track[i, "typ"]=="audio") {
      if (AudioKeep~Track[i, "lang"]) {
        print "Keep", Track[i, "typ"], "Track", Track[i, "id"],  Track[i, "lang"]
        if (AudioCommand=="") {AudioCommand=Track[i, "id"]
      } else AudioCommand=AudioCommand","Track[i, "id"]
      } else {
        print "\tRemove", Track[i, "typ"], "Track", Track[i, "id"],  Track[i, "lang"]
      }
    } else {
      if (Track[i, "typ"]=="subtitles") {
        if (SubsKeep~Track[i, "lang"]) {
          print "Keep", Track[i, "typ"], "Track", Track[i, "id"],  Track[i, "lang"]
          if (SubsCommand=="") {SubsCommand=Track[i, "id"]
          } else SubsCommand=SubsCommand","Track[i, "id"]
        } else {
          print "\tRemove", Track[i, "typ"], "Track", Track[i, "id"],  Track[i, "lang"]
        }
      }
    }
  }
  if (AudioCommand=="") {CommandLine="-A"
  } else {CommandLine="-a "AudioCommand}
  if (SubsCommand=="") {CommandLine=CommandLine" -S"
  } else {CommandLine=CommandLine" -s "SubsCommand}
  print MKVMerge" -o \""NewVideo"\" "CommandLine" \""MKVVideo"\""
  Result=system(MKVMerge" --title \""Title"\" -q -o \""NewVideo"\" "CommandLine" \""MKVVideo"\"")
  if (Result>1) print "Error "Result" muxing \""MKVVideo"\"!"
}' "$MOVIE" "$1" "$2" >>"$LOG"

[ -f "$NEWMOVIE" ] && {
  echo $(date +"%F %T")\|Moving "$NEWMOVIE" to "$MOVIE" >>"$LOG"
  mv "$NEWMOVIE" "$MOVIE"
} || {
  echo $(date +"%F %T")\|Error: Something went wrong. Unable to locate remuxed file: "$NEWMOVIE" >>"$LOG"
  echo Error: Something went wrong. Unable to locate remuxed file: "$NEWMOVIE"
  exit 10
}

echo $(date +"%F %T")\|Done >>"$LOG"
