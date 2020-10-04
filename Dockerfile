## Buildstage ##
FROM lsiobase/ubuntu:xenial as buildstage

# Build arguments
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
ARG DOCKERHUB

LABEL maintainer="TheCaptain989"

# Build-time metadata as defined at http://label-schema.org
LABEL org.label-schema.name="${DOCKERHUB}:latest" \
      org.label-schema.description="A Docker Mod for the LinuxServer.io Radarr/Sonarr container that adds mkvtoolnix and script for remuxing video files" \
      org.label-schema.url="https://hub.docker.com/r/${DOCKERHUB}" \
      org.label-schema.version=$VERSION \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vendor="TheCaptain989" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-url="https://github.com/TheCaptain989/radarr-striptracks" \
      org.label-schema.vcs-ref=$VCS_REF

# Build-time metadata as defined at https://github.com/opencontainers/image-spec
LABEL org.opencontainers.image.title="${DOCKERHUB}:latest" \
      org.opencontainers.image.description="A Docker Mod for the LinuxServer.io Radarr/Sonarr container that adds mkvtoolnix and script for remuxing video files" \
      org.opencontainers.image.url="https://hub.docker.com/r/${DOCKERHUB}" \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.vendor="TheCaptain989" \
      org.opencontainers.image.source="https://github.com/TheCaptain989/radarr-striptracks" \
      org.opencontainers.image.revision=$VCS_REF

RUN mkdir -p /root-layer/etc && \
  echo "$VERSION" > /root-layer/etc/version.tc989

# Stage local files
COPY root/ /root-layer/

## Single layer deployed image ##
FROM scratch

# Copy files from buildstage
COPY --from=buildstage /root-layer/ /
