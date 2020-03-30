[![](https://images.microbadger.com/badges/image/thecaptain989/radarr.svg)](https://microbadger.com/images/thecaptain989/radarr "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/thecaptain989/radarr.svg)](https://microbadger.com/images/thecaptain989/radarr "Get your own version badge on microbadger.com")

A Radarr Docker container with a script to automatically strip out unwanted audio and subtitle streams, keeping only the desired languages, using mkvmerge. Chapters, if they exist, are preserved. It also sets the Title attribute in the MKV to the filename minus its extension.

# First Things First
Configure the Docker container with all the port, volume, and environment settings from the original container documentation here:  
**[linuxserver/radarr](https://hub.docker.com/r/linuxserver/radarr)**

This container supports Linux OSes only.

## Usage

After all of the above configuration is complete, to use mkvmerge, configure a custom script from the Settings->Connect screen to call:

**`/usr/local/bin/striptracks.sh`**

Add the codes for the audio and subtitle languages you want to keep as Arguments, as specified below.

The source video can be any mkvtoolnix supported video format. The output is an MKV file with the same name.

If you've configured the Radarr Recycle Bin path correctly, the original video will be moved there.  
**NOTE:** If you have *not* configured the Recycle Bin, the original video file will be deleted/overwritten and permanently lost.

### Syntax

The script accepts two arguments and one option:

`[-d] <audio_languages> <subtitle_languages>`

The arguments are language codes in [ISO639-2](https://en.wikipedia.org/wiki/List_of_ISO_639-2_codes) format. These are three letter abbreviations prefixed with a colon ':', such as:

* :eng
* :fre
* :spa

...etc.  

Multiple codes may be concatenated, such as `:eng:spa` for both English and Spanish.  

Suggested to use `:eng:und :eng` if you are unsure of what to choose. This will keep English and Undetermined audio and English subtitles, if they exist.

The only events/notification triggers that have been tested are **On Download** and **On Upgrade**

The `-d` option enables debug logging.

### Examples
    :eng:und :eng              # keep English and Undetermined audio and English subtitles
    :eng ""                    # keep English audio and no subtitles
    -d :eng:kor:jpn :eng:spa   # Enable debugging, keeping English, Korean, and Japanese audio, and English and 
                                 Spanish subtitles

![striptracks](https://raw.githubusercontent.com/TheCaptain989/striptracks/master/images/striptracks.png)

### Logs
A log file is created for the script activity called:

`/config/logs/striptracks.txt`

This log can be inspected or downloaded from the Radarr GUI under System->Logs->Files

Log rotation is performed, and 5 log files of 1MB each are kept, matching Radarr's log retention.

If debug logging is enabled, the log file can grow very large very quickly.

## Credits

This would not be possible without the following:

[Radarr](http://radarr.video/)

[LinuxServer.io Radarr](https://hub.docker.com/r/linuxserver/radarr) container

[mkvtoolnix](https://mkvtoolnix.download/) by Moritz Bunkus

The AWK script parsing mkvmerge output is adapted from Endoro's post on [VideoHelp](https://forum.videohelp.com/threads/343271-BULK-remove-non-English-tracks-from-MKV-container#post2292889).
