# Use the offical LinuxServer.io image
FROM linuxserver/radarr:latest

LABEL maintainer="TheCaptain989"

# Build arguments
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

# Build-time metadata as defined at http://label-schema.org
LABEL org.label-schema.name="thecaptain989/radarr" \
      org.label-schema.description="The LinuxServer.io Radarr container plus mkvtoolniox and script for remuxing video files" \
      org.label-schema.url="https://hub.docker.com/r/thecaptain989/radarr" \
      org.label-schema.version=$VERSION \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vendor="TheCaptain989" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-url="https://github.com/TheCaptain989/radarr-striptracks" \
      org.label-schema.vcs-ref=$VCS_REF

# Build-time metadata as defined at https://github.com/opencontainers/image-spec
LABEL org.opencontainers.image.title="thecaptain989/radarr" \
      org.opencontainers.image.description="The LinuxServer.io Radarr container plus mkvtoolniox and script for remuxing video files" \
      org.opencontainers.image.url="https://hub.docker.com/r/thecaptain989/radarr" \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.vendor="TheCaptain989" \
      org.opencontainers.image.source="https://github.com/TheCaptain989/radarr-striptracks" \
      org.opencontainers.image.revision=$VCS_REF

# Add custom branding to container init script
COPY 98-motd /etc/cont-init.d/98-motd

# Copy shell script that can be called by Radarr
COPY --chown=root:users striptracks.sh /usr/local/bin/striptracks.sh

# Install mkvtoolnix which included mkvmerge
RUN chmod +x /usr/local/bin/striptracks.sh &&\
    echo "$VERSION" > /etc/version.tc989 &&\
    apt-get update &&\
    apt-get -y install mkvtoolnix &&\
    rm -rf /var/lib/apt/lists/*
