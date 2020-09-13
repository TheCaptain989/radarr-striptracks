# Required environment variables are set in Docker Hub
# BRANCH=(radarr|sonarr)

# Use the offical LinuxServer.io image
ARG BRANCH
ARG DOCKER_TAG
FROM linuxserver/${BRANCH:-radarr}:${DOCKER_TAG:-latest}

LABEL maintainer="TheCaptain989"

# Build arguments
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
ARG BRANCH

# Build-time metadata as defined at http://label-schema.org
LABEL org.label-schema.name="thecaptain989/${BRANCH:-radarr}:${DOCKER_TAG:-latest}" \
      org.label-schema.description="The LinuxServer.io ${BRANCH:-radarr} container plus mkvtoolniox and script for remuxing video files" \
      org.label-schema.url="https://hub.docker.com/r/thecaptain989/${BRANCH:-radarr}" \
      org.label-schema.version=$VERSION \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vendor="TheCaptain989" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-url="https://github.com/TheCaptain989/radarr-striptracks" \
      org.label-schema.vcs-ref=$VCS_REF

# Build-time metadata as defined at https://github.com/opencontainers/image-spec
LABEL org.opencontainers.image.title="thecaptain989/${BRANCH:-radarr}:${DOCKER_TAG:-latest}" \
      org.opencontainers.image.description="The LinuxServer.io ${BRANCH:-radarr} container plus mkvtoolniox and script for remuxing video files" \
      org.opencontainers.image.url="https://hub.docker.com/r/thecaptain989/${BRANCH:-radarr}" \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.vendor="TheCaptain989" \
      org.opencontainers.image.source="https://github.com/TheCaptain989/radarr-striptracks" \
      org.opencontainers.image.revision=$VCS_REF

# Add custom branding to container init script
COPY 98-motd /etc/cont-init.d/98-motd

# Copy shell script that can be called by Radarr
COPY --chown=root:users striptracks*.sh /usr/local/bin/

# Install mkvtoolnix which includes mkvmerge
RUN chmod +x /usr/local/bin/striptracks*.sh &&\
    echo "$VERSION" > /etc/version.tc989 &&\
    apt-get update &&\
    apt-get -y install mkvtoolnix &&\
    rm -rf /var/lib/apt/lists/*
