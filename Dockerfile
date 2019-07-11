# Use the offical LinuxServer.io image
FROM linuxserver/radarr:latest

# Copy shell script that can be called by Radarr
COPY striptracks.sh /usr/local/bin/striptracks.sh

# Add custom branding to container init script
COPY 98-motd /etc/cont-init.d/98-motd

# Install mkvtoolnix which included mkvmerge
RUN apt-get update &&\
	apt-get -y install mkvtoolnix \
 && rm -rf /var/lib/apt/lists/*
