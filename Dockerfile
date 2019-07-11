# Use the offical LinuxServer.io image
FROM linuxserver/radarr:latest

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="thecaptain989/radarr" \
      org.label-schema.description="The LinuxServer.io Radarr container plus mkvtoolniox and script for remuxing video files" \
      org.label-schema.url="https://hub.docker.com/r/thecaptain989/radarr" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"

# Copy shell script that can be called by Radarr
COPY striptracks.sh /usr/local/bin/striptracks.sh

# Add custom branding to container init script
COPY 98-motd /etc/cont-init.d/98-motd

# Install mkvtoolnix which included mkvmerge
RUN apt-get update &&\
	apt-get -y install mkvtoolnix \
 && rm -rf /var/lib/apt/lists/*
