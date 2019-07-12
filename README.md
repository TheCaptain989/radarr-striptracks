<p>Radarr with a script to automatically strip out unwanted audio and subtitle streams, keeping only the desired languages.  Chapters, if they exist, are preserved.  Also sets the Title attribute to the name of the file minus extension.</p>
<h1>First Things First</h1>
Configure the container with all the port, volume, and environment settings from the original container documentation here:<br>
<b><a href="https://hub.docker.com/r/linuxserver/radarr">linuxserver/radarr</a></b>

<h2>Usage</h2>
After all of the above configuration is complete, to use mkvmerge, configure a custom script from the Settings-&gt;Connect screen to call:
<p><code><b>/usr/local/bin/striptracks.sh</b></code></p>
<p>Add the codes for the audio and subtitle languages you want to keep as Arguments, as specified below.</p>
<p>The source video can be any mkvtoolnix supported video format.  The output is an MKV file with the same name.</p>
<p><b>NOTE:</b>The original video file will be deleted/overwritten and permanently lost.</p>
<h3>Syntax</h3>
<p>It accepts two arguments:</p>
<p><code>striptracks.sh [audio_languages] [subtitle_languages]</code></p>
<p>The arguments are language codes is <a href="https://en.wikipedia.org/wiki/List_of_ISO_639-2_codes">ISO639-2</a> format.  These are three letter abbreviations prefixed with a colon `:` such as:</p>
<ul>
<li>:eng</li>
<li>:fre</li>
<li>:esp</li>
</ul>
...etc.<br>
Multiple codes may be concatenated, such as <code>:eng:esp</code> for both English and Spanish.<br>
<p>Suggested to use <code>:eng:und :eng</code> if you are unsure of what to choose.  This will keep English and Undetermined audio and English subtitles, if they exist.</p>
The only events/notification triggers that have been tested are <b>On Download</b> and <b>On Upgrade</b>
<h2>Credits</h2>
This would not be possible without the following:
<p><a href="http://radarr.video/">Radarr</a></p>
<p><a href="https://hub.docker.com/r/linuxserver/radarr">LinuxServer.io Radarr</a> container</p>
<p><a href="https://mkvtoolnix.download/">mkvtoolnix</a> by Moritz Bunkus</p>
<p>The AWK script parsing mkvmerge output is adapted from Endoro's post on <a href="https://forum.videohelp.com/threads/343271-BULK-remove-non-English-tracks-from-MKV-container#post2292889">VideoHelp</a>.</p>
