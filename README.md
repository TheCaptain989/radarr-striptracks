[![](https://images.microbadger.com/badges/image/thecaptain989/radarr.svg)](https://microbadger.com/images/thecaptain989/radarr "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/thecaptain989/radarr.svg)](https://microbadger.com/images/thecaptain989/radarr "Get your own version badge on microbadger.com")

A Radarr/Sonarr Docker container with a script to automatically strip out unwanted audio and subtitle streams, keeping only the desired languages, using mkvmerge. Chapters, if they exist, are preserved. It also sets the Title attribute in the MKV to the filename minus its extension.

**One unified script works in either Radarr or Sonarr.  Both containers are auto-built when the script is updated on Github.**

# Installation
1. Pull your selected container ([thecaptain989/radarr](https://hub.docker.com/r/thecaptain989/radarr "TheCaptain989's Radarr container") or [thecaptain989/sonarr](https://hub.docker.com/r/thecaptain989/sonarr "TheCaptain989's Sonarr container")) from Docker Hub:  
  `docker pull thecaptain989/radarr:latest`   OR  
  `docker pull thecaptain989/sonarr:latest`

>NOTE: These containers supports Linux OSes only.

2. Configure the Docker container with all the port, volume, and environment settings from the *original container documentation* here:  
   **[linuxserver/radarr](https://hub.docker.com/r/linuxserver/radarr "Docker container")**  
   **[linuxserver/sonarr](https://hub.docker.com/r/linuxserver/sonarr "Docker container")**

3. After all of the above configuration is complete, to use mkvmerge:  
   1. Configure a custom script from the Settings->Connect screen and type the following in the Path field:  

      **`/usr/local/bin/striptracks.sh`**  
  
   2. Add the codes for the audio and subtitle languages you want to keep as Arguments (details in the [Syntax](./README.md#syntax) section below):

      <ins>Example</ins>  
      **`:eng:und :eng`**

## Usage

The source video can be any mkvtoolnix supported video format. The output is an MKV file with the same name.

If you've configured the Radarr/Sonarr Recycle Bin path correctly, the original video will be moved there.  
>**NOTE:** If you have *not* configured the Recycle Bin, the original video file will be deleted/overwritten and permanently lost.

### Syntax

The script accepts two arguments and one option:

`[-d] <audio_languages> <subtitle_languages>`

The arguments are language codes in [ISO639-2](https://en.wikipedia.org/wiki/List_of_ISO_639-2_codes "List of ISO 639-2 codes") format. These are three letter abbreviations prefixed with a colon ':', such as:

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

![striptracks](https://raw.githubusercontent.com/TheCaptain989/radarr-striptracks/master/images/striptracks.png "Radarr/Sonarr custom script settings")

### Logs
A log file is created for the script activity called:

`/config/logs/striptracks.txt`

This log can be inspected or downloaded from the Radarr/Sonarr GUI under System->Logs->Files

Script errors will show up in both the script log and the native Radarr/Sonarr log.

Log rotation is performed, and 5 log files of 512KB each are kept.  
If debug logging is enabled, the log file can grow very large very quickly.  *Do not leave debug logging enabled permanently.*

## Credits

This would not be possible without the following:

[Radarr](http://radarr.video/ "Radarr homepage")  
[Sonarr](http://sonarr.tv/ "Sonarr homepage")  
[LinuxServer.io Radarr](https://hub.docker.com/r/linuxserver/radarr "Docker container") container  
[LinuxServer.io Sonarr](https://hub.docker.com/r/linuxserver/sonarr "Docker container") container  
[MKVToolNix](https://mkvtoolnix.download/ "MKVToolNix homepage") by Moritz Bunkus  
The AWK script parsing mkvmerge output is adapted from Endoro's post on [VideoHelp](https://forum.videohelp.com/threads/343271-BULK-remove-non-English-tracks-from-MKV-container#post2292889).
