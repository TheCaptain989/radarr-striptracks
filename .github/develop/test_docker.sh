#!/bin/bash
# shellcheck disable=SC2181

container_name="radarr"
repo="radarr-striptracks"
status="$(docker ps -a --filter "name=^${container_name}$" --format '{{.Status}}')"

# Create radarr container
if [ -z "$status" ]; then
 echo "Creating radarr container"
 docker run -d -e TZ=America/Chicago --user root --name radarr -p 7878:7878 -v /workspaces/$repo:/workspaces/$repo linuxserver/radarr:latest
 if [ $? -ne 0 ]; then
   echo "Failed to start radarr container"
   exit 1
 fi
elif [[ "$status" =~ Exited ]]; then
 echo "Starting existing radarr container"
 docker start $container_name
 if [ $? -ne 0 ]; then
   echo "Failed to start radarr container"
   exit 1
 fi
fi

# Install mkvmerge and bash-unit
if [ ! -f /workspaces/$repo/bash_unit ] && [ ! -f /usr/bin/mkvtoolnix ]; then
  echo "Installing mkvtoolnix and bash-unit in radarr container"
  docker exec -it radarr /bin/bash -c "cd /workspaces/$repo && apk add --no-cache mkvtoolnix && curl -s https://raw.githubusercontent.com/bash-unit/bash_unit/main/install.sh | bash"
  if [ $? -ne 0 ]; then
    echo "Failed to install bash-unit in radarr container"
    exit 1
  fi
fi

# Run tests
docker exec -it radarr /bin/bash -c "FORCE_COLOR=true /workspaces/$repo/bash_unit ${2} /workspaces/$repo/.github/tests/test_${1}*"
if [ $? -ne 0 ]; then
  echo "Tests failed"
  exit 1
fi
