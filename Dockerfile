# Use the offical LinuxServer.io image
FROM linuxserver/radarr:latest

LABEL maintainer="TheCaptain989"

# Build arguments
ARG NAME="thecaptain989/radarr"
ARG DESCRIPTION="The LinuxServer.io Radarr container plus mkvtoolniox and script for remuxing video files" 
ARG URL="https://hub.docker.com/r/thecaptain989/radarr"
ARG VCS_URL="https://github.com/TheCaptain989/striptracks"
ARG VERSION=1.0
ARG VENDOR="TheCaptain989"
ARG BUILD_DATE
ARG VCS_REF

# Build-time metadata as defined at http://label-schema.org
LABEL org.label-schema.name=$NAME \
      org.label-schema.description=$DESCRIPTION \
      org.label-schema.url=$URL \
      org.label-schema.version=$VERSION \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vendor=$VENDOR \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-url=$VCS_URL \
      org.label-schema.vcs-ref=$VCS_REF

# Build-time metadata as defined at https://github.com/opencontainers/image-spec
LABEL org.opencontainers.image.title=$NAME \
      org.opencontainers.image.description=$DESCRIPTION \
      org.opencontainers.image.url=$URL \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.vendor=$VENDOR \
      org.opencontainers.image.source=$VCS_URL \
      org.opencontainers.image.revision=$VCS_REF \
      

# Copy shell script that can be called by Radarr
COPY striptracks.sh /usr/local/bin/striptracks.sh

# Add custom branding to container init script
COPY 98-motd /etc/cont-init.d/98-motd

# Install mkvtoolnix which included mkvmerge
RUN apt-get update &&\
	apt-get -y install mkvtoolnix \
 && rm -rf /var/lib/apt/lists/*
