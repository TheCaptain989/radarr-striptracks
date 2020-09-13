A Radarr/Sonarr Docker container with a script to automatically strip out unwanted audio and subtitle streams, keeping only the desired languages, using mkvmerge. Chapters, if they exist, are preserved. The Title attribute in the MKV is sset to the video title plus year (ex: `The Sting (1973)`).

**One unified script works in either Radarr or Sonarr.  Both containers are auto-built when the script is updated on Github, or when the source container is updated.**

Radarr container info:
[![](https://images.microbadger.com/badges/image/thecaptain989/radarr.svg)](https://microbadger.com/images/thecaptain989/radarr "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/thecaptain989/radarr.svg)](https://microbadger.com/images/thecaptain989/radarr "Get your own version badge on microbadger.com")
![Docker Pulls](https://img.shields.io/docker/pulls/thecaptain989/radarr "Radarr Container Pulls")   
Sonarr container info:
[![](https://images.microbadger.com/badges/image/thecaptain989/sonarr.svg)](https://microbadger.com/images/thecaptain989/sonarr "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/thecaptain989/sonarr.svg)](https://microbadger.com/images/thecaptain989/sonarr "Get your own version badge on microbadger.com")
![Docker Pulls](https://img.shields.io/docker/pulls/thecaptain989/sonarr "Sonarr Container Pulls")

# Installation
>:warning: **Warning: Beta Releases** :warning:  
>This branch is for the v3 beta releases. I cannot guarantee these releases are stable and might perform breaking changes at any time.

1. Pull your selected container ([thecaptain989/radarr](https://hub.docker.com/r/thecaptain989/radarr "TheCaptain989's Radarr container") or [thecaptain989/sonarr](https://hub.docker.com/r/thecaptain989/sonarr "TheCaptain989's Sonarr container")) from Docker Hub:  
  `docker pull thecaptain989/radarr:preview`   OR  
  `docker pull thecaptain989/sonarr:preview`

>NOTE: These containers support Linux OSes only.

2. Configure the Docker container with all the port, volume, and environment settings from the *original container documentation* here:  
   **[linuxserver/radarr](https://hub.docker.com/r/linuxserver/radarr "Docker container")**  
   **[linuxserver/sonarr](https://hub.docker.com/r/linuxserver/sonarr "Docker container")**

3. After all of the above configuration is complete, to use mkvmerge, configure a custom script from the Settings->Connect screen and type the following in the **Path** field:  

      **`/usr/local/bin/striptracks-eng.sh`**  

      <ins>This script uses the following options, which keep English audio and subtitles only!</ins>  
      **`:eng:und :eng`**

      *For any other combinations of audio and subtitles you must either use one of the [included wrapper scripts](./README.md#included-wrapper-scripts) or create a custom script with the codes for the languages you want to keep.  See [Syntax](./README.md#syntax) section below.*

## Usage
The source video can be any mkvtoolnix supported video format. The output is an MKV file with the same name.

If you've configured the Radarr/Sonarr Recycle Bin path correctly, the original video will be moved there.  
>:warning: **NOTE:** If you have *not* configured the Recycle Bin, the original video file will be deleted/overwritten and permanently lost.

### Syntax
**NOTE:** The **Arguments** field for Custom Scripts was removed in Radarr and Sonarr v3 due to security concerns. To support options with this version and later, a wrapper script can be manually created that will call *striptracks.sh* with the required arguments. Therefore, this section is for legacy and advanced purposes only.

The script accepts two arguments and one option in the **Arguments** field:

`[-d] <audio_languages> <subtitle_languages>`

The arguments are language codes in [ISO639-2](https://en.wikipedia.org/wiki/List_of_ISO_639-2_codes "List of ISO 639-2 codes") format. These are three letter abbreviations prefixed with a colon ':', such as:

* :eng
* :fre
* :spa

...etc.  

Multiple codes may be concatenated, such as `:eng:spa` for both English and Spanish.  

It is suggested to use `:eng:und :eng` if you are unsure of what to choose. This will keep English and Undetermined audio and English subtitles, if they exist.
>**NOTE:** The script is smart enough to not remove the last audio track. This way you don't have to specify every possible language if you are importing a foreign film, for example.

The `-d` option enables debug logging.

### Examples
```
:eng:und :eng              # keep English and Undetermined audio and English subtitles
-d :eng ""                 # Enable debugging, keeping English audio and no subtitles
:eng:kor:jpn :eng:spa      # Keep English, Korean, and Japanese audio, and English and 
                             Spanish subtitles
```

#### Example Wrapper Script
To use the last example above, create and save the following text in a file called `wrapper.sh` and then use that in the **Path** field in place of `striptracks-eng.sh` mentioned in the [Installation](./README.md#installation) section above.
```
#!/bin/bash

. /usr/local/bin/striptracks.sh :eng:kor:jpn :eng:spa
```

#### Included Wrapper Scripts
For your convenience, several wrapper scripts are included in the Docker container in the `/usr/local/bin/` directory.  
You may use any of these scripts in place of the `striptracks-eng.sh` mentioned in the [Installation](./README.md#installation) section above.

```
striptracks-eng-debug.sh   # Keep English and Undetermined audio and English subtitles, and enable debug logging
striptracks-eng-jpn.sh     # Keep English, Japanese, and Undetermined audio and English subtitles
striptracks-spa.sh         # Keep Spanish audio and subtitles
striptracks-fra.sh         # Keep French audio and subtitles
striptracks-ger.sh         # Keep German audio and subtitles
striptracks-dut.sh         # Keep Dutch audio and subtitles
```

### Triggers
The only events/notification triggers that have been tested are **On Import** and **On Upgrade**

![striptracks](https://raw.githubusercontent.com/TheCaptain989/radarr-striptracks/preview/images/striptracks-v3.png "Radarr/Sonarr custom script settings")

### Logs
A log file is created for the script activity called:

`/config/logs/striptracks.txt`

This log can be inspected or downloaded from the Radarr/Sonarr GUI under System->Log Files

Script errors will show up in both the script log and the native Radarr/Sonarr log.

Log rotation is performed with 5 log files of 512KB each being kept.  
If debug logging is enabled, the log file can grow very large very quickly.  *Do not leave debug logging enabled permanently.*

## Credits

This would not be possible without the following:

[Radarr](http://radarr.video/ "Radarr homepage")  
[Sonarr](http://sonarr.tv/ "Sonarr homepage")  
[LinuxServer.io Radarr](https://hub.docker.com/r/linuxserver/radarr "Docker container") container  
[LinuxServer.io Sonarr](https://hub.docker.com/r/linuxserver/sonarr "Docker container") container  
[MKVToolNix](https://mkvtoolnix.download/ "MKVToolNix homepage") by Moritz Bunkus  
The AWK script parsing mkvmerge output is adapted from Endoro's post on [VideoHelp](https://forum.videohelp.com/threads/343271-BULK-remove-non-English-tracks-from-MKV-container#post2292889).
