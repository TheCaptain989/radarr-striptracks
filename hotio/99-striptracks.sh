#!/command/with-contenv bash
# shellcheck shell=bash

# Custom script to install Striptracks Mod meant for Radarr or Sonarr Docker containers

# Pre-set LSIO Docker Mod variables
DOCKER_MODS=thecaptain989/radarr-striptracks:latest
DOCKER_MODS_DEBUG=true
export DOCKER_MODS
export DOCKER_MODS_DEBUG

# Steal the current docker-mods version from the source
MODS_VERSION=$(curl -s "https://raw.githubusercontent.com/linuxserver/docker-baseimage-alpine/master/Dockerfile" | sed -nr "s/^ARG MODS_VERSION=//p")

# Download and execute the main the docker-mods script to install the mod
# Very well thought out code, this.  Why reinvent?
curl -s -o "/docker-mods" "https://raw.githubusercontent.com/linuxserver/docker-mods/mod-scripts/docker-mods.${MODS_VERSION}"
. /docker-mods

# Get script version from installed mod
VERSION=$(sed -nr "s/^export striptracks_ver=//p" /usr/local/bin/striptracks.sh)

# Remaining setup that is normally done with s6-overlay init scripts, but that rely on a lot of Docker Mods dependencies
cat <<EOF
----------------
>>> Striptracks Mod by TheCaptain989 <<<
Repos:
  Dev/test: https://github.com/TheCaptain989/radarr-striptracks
  Prod: https://github.com/linuxserver/docker-mods/tree/radarr-striptracks

Version: ${VERSION}
----------------
EOF

# Determine if setup is needed
if [ ! -f /usr/bin/mkvmerge ]; then
  echo "Running first time setup."

  if [ -f /usr/bin/apt ]; then
    # Ubuntu
    echo "Installing MKVToolNix using apt-get"
    apt-get update && \
        apt-get -y install mkvtoolnix && \
        rm -rf /var/lib/apt/lists/*
  elif [ -f /sbin/apk ]; then
    # Alpine
    echo "Installing MKVToolNix using apk"
    apk upgrade --no-cache && \
        apk add --no-cache mkvtoolnix && \
        rm -rf /var/lib/apt/lists/*
  else
    # Unknown
    echo "Unknown package manager.  Attempting to install MKVToolNix using apt-get"
    apt-get update && \
        apt-get -y install mkvtoolnix && \
        rm -rf /var/lib/apt/lists/*
  fi
fi

# Check ownership and attributes on each script file
for file in /usr/local/bin/striptracks*.sh
do
  # Change ownership
  if [ $(stat -c '%G' $file) != "abc" ]; then
    echo "Changing ownership on $file script."
    chown abc:abc $file
  fi

  # Make executable
  if [ ! -x $file ]; then
    echo "Making $file script executable."
    chmod +x $file
  fi
done
