#!/command/with-contenv bash

MOD_SCRIPT_VER="3.20240626"

# Check for curl
curl_check() {
    if [[ ! -f /usr/bin/curl ]] || [[ ! -f /usr/bin/jq ]]; then
        write_mod_info "Curl/JQ was not found on this system for Docker mods installing"
        if [[ -f /usr/bin/apt ]]; then
            # Ubuntu
            export DEBIAN_FRONTEND="noninteractive"
            apt-get update
            apt-get install --no-install-recommends -y \
                curl \
                jq
        elif [[ -f /sbin/apk ]]; then
            # Alpine
            apk add --no-cache \
                curl \
                jq
        elif [[ -f /usr/bin/dnf ]]; then
            # Fedora
            dnf install -y --setopt=install_weak_deps=False --best \
                curl \
                jq
        elif [[ -f /usr/sbin/pacman ]]; then
            # Arch
            pacman -Sy --noconfirm \
                curl \
                jq
        fi
    fi
}

write_mod_info() {
    local MSG=$*
    echo "[mod-init] $MSG"
}

write_mod_error() {
    local MSG=$*
    echo "[mod-init] (ERROR) $MSG"
}

write_mod_debug() {
    local MSG=$*
    if [[ ${DOCKER_MODS_DEBUG,,} = "true" ]]; then echo "[mod-init] (DEBUG) $MSG"; fi
}

# Use different filtering depending on URL
get_blob_sha() {
    MULTIDIGEST=$(curl  -f --retry 10 --retry-max-time 60 --retry-connrefused \
        ${CURL_NOISE_LEVEL} \
        --location \
        --header "Accept: application/vnd.docker.distribution.manifest.v2+json" \
        --header "Accept: application/vnd.oci.image.index.v1+json" \
        --header "Authorization: Bearer ${1}" \
        --user-agent "${MOD_UA}" \
        "${2}/${3}")
    if jq -e '.layers // empty' <<< "${MULTIDIGEST}" >/dev/null 2>&1; then
        # If there's a layer element it's a single-arch manifest so just get that digest
        jq -r '.layers[0].digest' <<< "${MULTIDIGEST}";
    else
        # Otherwise it's multi-arch or has manifest annotations
        if jq -e '.manifests[]?.annotations // empty' <<< "${MULTIDIGEST}" >/dev/null 2>&1; then
            # Check for manifest annotations and delete if found
            write_mod_debug "Mod has one or more manifest annotations" >&2
            MULTIDIGEST=$(jq 'del(.manifests[] | select(.annotations))' <<< "${MULTIDIGEST}")
        fi
        if [[ $(jq '.manifests | length' <<< "${MULTIDIGEST}") -gt 1 ]]; then
            # If there's still more than one digest, it's multi-arch
            write_mod_debug "Mod has a multi-arch manifest" >&2
            MULTIDIGEST=$(jq -r ".manifests[] | select(.platform.architecture == \"${4}\").digest?" <<< "${MULTIDIGEST}")
            if [[ -z "${MULTIDIGEST}" ]]; then
                exit 1
            fi
        else
            # Otherwise it's single arch
            write_mod_debug "Mod only has a single arch manifest" >&2
            MULTIDIGEST=$(jq -r ".manifests[].digest?" <<< "${MULTIDIGEST}")
        fi
        if DIGEST=$(curl  -f --retry 10 --retry-max-time 60 --retry-connrefused \
            ${CURL_NOISE_LEVEL} \
            --location \
            --header "Accept: application/vnd.docker.distribution.manifest.v2+json" \
            --header "Accept: application/vnd.oci.image.manifest.v1+json" \
            --header "Authorization: Bearer ${1}" \
            --user-agent "${MOD_UA}" \
            "${2}/${MULTIDIGEST}"); then
            jq -r '.layers[0].digest' <<< "${DIGEST}";
        fi
    fi
}

get_auth_url() {
    local auth_header
    local realm_url
    local service
    local scope
    # Call to get manifests and extract www-authenticate header
    auth_header=$(curl -sLI ${CURL_NOISE_LEVEL} "${1}/${2}" | grep -i www-authenticate | tr -d '\r')
    if [[ -n "${auth_header}" ]]; then
        write_mod_debug "${auth_header}" >&2
        # Extract realm URL from www-authenticate header
        realm_url=$(echo "$auth_header" | awk -F'[="]+' '/realm=/{print $2}')
        service=$(echo "$auth_header" | awk -F'[="]+' '/service=/{print $4}')
        scope=$(echo "$auth_header" | awk -F'[="]+' '/scope=/{print $6}')
        echo "$realm_url?service=$service&scope=$scope"
    else
        exit 1
    fi
}

get_arch(){
    local arch

    if [[ -f /sbin/apk ]]; then
        arch=$(apk --print-arch)
    elif [[ -f /usr/bin/dpkg ]]; then
        arch=$(dpkg --print-architecture)
    else
        arch=$(uname -m)
    fi

    case "${arch}" in
    x86_64 )
        arch="amd64"
        ;;
    aarch64 )
        arch="arm64"
        ;;
    esac

    echo "${arch}"
}

# Main run logic
run_mods() {
    write_mod_info "Running Docker Modification Logic"
    write_mod_debug "Running in debug mode"
    write_mod_debug "Mod script version ${MOD_SCRIPT_VER}"
    for DOCKER_MOD in $(echo "${DOCKER_MODS}" | tr '|' '\n'); do
        # Support alternative endpoints
        case "${DOCKER_MOD}" in
        linuxserver/* )
            [[ ${DOCKER_MODS_FORCE_REGISTRY,,} = "true" ]] && REGISTRY="registry-1.docker.io" || REGISTRY="lscr.io"
            ;;
        docker.io/linuxserver/* )
            [[ ${DOCKER_MODS_FORCE_REGISTRY,,} = "true" ]] && REGISTRY="registry-1.docker.io" || REGISTRY="lscr.io"
            DOCKER_MOD="${DOCKER_MOD#docker.io/*}"
            ;;
        ghcr.io/linuxserver/* )
            [[ ${DOCKER_MODS_FORCE_REGISTRY,,} = "true" ]] && REGISTRY="ghcr.io" || REGISTRY="lscr.io"
            DOCKER_MOD="${DOCKER_MOD#ghcr.io/*}"
            ;;
        docker.io/* )
            REGISTRY="registry-1.docker.io"
            DOCKER_MOD="${DOCKER_MOD#docker.io/*}"
            ;;
        * )
            # Default assumption is docker.io
            REGISTRY="registry-1.docker.io"
            MOD="${DOCKER_MOD%/*}"
            # If mod still has a / after stripping off the image name it's not docker.io
            if [[ $MOD == */* ]]; then
                REGISTRY="${MOD%%/*}"
                DOCKER_MOD="${DOCKER_MOD#"$REGISTRY"/*}"
            # If "repo" name has . in it, then assume it's actually a registry with no repo
            elif [[ ${DOCKER_MOD%%/*} =~ \. ]]; then
                REGISTRY="${DOCKER_MOD%%/*}"
                MOD="${DOCKER_MOD##*/}"
            fi
            ;;
        esac
        ENDPOINT="${DOCKER_MOD%%:*}"
        USERNAME="${DOCKER_MOD%%/*}"
        REPO="${ENDPOINT#*/}"
        TAG="${DOCKER_MOD#*:}"
        if [[ "${TAG}" == "${DOCKER_MOD}" ]]; then
            TAG="latest"
        fi
        FILENAME="${USERNAME}.${REPO}.${TAG}"
        MANIFEST_URL="https://${REGISTRY}/v2/${ENDPOINT}/manifests"
        BLOB_URL="https://${REGISTRY}/v2/${ENDPOINT}/blobs/"
        MOD_UA="Mozilla/5.0 (Linux $(uname -m)) linuxserver.io ${REGISTRY}/${ENDPOINT}:${TAG}"
        write_mod_debug "Registry='${REGISTRY}', Repository='${USERNAME}', Image='${ENDPOINT}', Tag='${TAG}'"
        case "${REGISTRY}" in
            "lscr.io") AUTH_URL="https://ghcr.io/token?scope=repository%3A${USERNAME}%2F${REPO}%3Apull";;
            "ghcr.io") AUTH_URL="https://ghcr.io/token?scope=repository%3A${USERNAME}%2F${REPO}%3Apull";;
            "quay.io") AUTH_URL="https://quay.io/v2/auth?service=quay.io&scope=repository%3A${USERNAME}%2F${REPO}%3Apull";;
            "registry-1.docker.io") AUTH_URL="https://auth.docker.io/token?service=registry.docker.io&scope=repository:${ENDPOINT}:pull";;
            *) AUTH_URL=$(get_auth_url "${MANIFEST_URL}" "${TAG}")
        esac
        # Kill off modification logic if any of the usernames are banned
        for BANNED in $(curl -s https://raw.githubusercontent.com/linuxserver/docker-mods/master/blacklist.txt); do
            if [[ "${BANNED,,}" == "${USERNAME,,}" ]]; then
                if [[ -z ${RUN_BANNED_MODS+x} ]]; then
                    write_mod_info "${DOCKER_MOD} is banned from use due to reported abuse, skipping mod"
                    continue
                else
                    write_mod_info "You have chosen to run banned mods, ${DOCKER_MOD} will be applied"
                fi
            fi
        done
        if [[ -n "${AUTH_URL}" ]]; then
            # Get registry token for api operations
            TOKEN="$(
                curl -f --retry 10 --retry-max-time 60 --retry-connrefused \
                    ${CURL_NOISE_LEVEL} \
                    "${AUTH_URL}" |
                    jq -r '.token'
            )"
        else
            write_mod_info "Could not fetch auth URL from registry for ${DOCKER_MOD}, attempting unauthenticated fetch"
        fi
        write_mod_info "Adding ${DOCKER_MOD} to container"
        # If we're using lscr try and get the manifest from ghcr, if it fails re-request a token from Docker Hub
        if [[ "${REGISTRY}" == "lscr.io" ]]; then
            if [[ -n $(curl --user-agent "${MOD_UA}" -sLH "Authorization: Bearer ${TOKEN}" "${MANIFEST_URL}/${TAG}" | jq -r '.errors' >/dev/null 2>&1) ]]; then
                write_mod_debug "Couldn't fetch manifest from ghcr.io, trying docker.io"
                AUTH_URL="https://auth.docker.io/token?service=registry.docker.io&scope=repository:${ENDPOINT}:pull"
                TOKEN="$(
                    curl -f --retry 10 --retry-max-time 60 --retry-connrefused \
                        ${CURL_NOISE_LEVEL} \
                        "${AUTH_URL}" |
                        jq -r '.token'
                )"
            fi
        fi
        if [[ -n "${AUTH_URL}" ]]; then
            write_mod_debug "Using ${AUTH_URL} as auth endpoint"
        fi
        ARCH=$(get_arch)
        write_mod_debug "Arch detected as ${ARCH}"
        # Determine first and only layer of image
        SHALAYER=$(get_blob_sha "${TOKEN}" "${MANIFEST_URL}" "${TAG}" "${ARCH:=-amd64}")
        if [[ $? -eq 1 ]]; then
            write_mod_error "No manifest available for arch ${ARCH:=-amd64}, cannot fetch mod"
            continue
        elif [[ -z "${SHALAYER}" ]]; then
            write_mod_error "${DOCKER_MOD} digest could not be fetched from ${REGISTRY}"
            continue
        fi
        # Check if we have allready applied this layer
        if [[ -f "/${FILENAME}" ]] && [[ "${SHALAYER}" == "$(cat /"${FILENAME}")" ]]; then
            write_mod_info "${DOCKER_MOD} at ${SHALAYER} has been previously applied skipping"
        else
            write_mod_info "Downloading ${DOCKER_MOD} from ${REGISTRY}"
            # Download and extract layer to /
            curl -f --retry 10 --retry-max-time 60 --retry-all-errors \
                ${CURL_NOISE_LEVEL} \
                --location \
                --header "Authorization: Bearer ${TOKEN}" \
                --user-agent "${MOD_UA}" \
                "${BLOB_URL}${SHALAYER}" -o \
                /modtarball.tar.xz
            mkdir -p /tmp/mod
            if ! tar -tzf /modtarball.tar.xz >/dev/null 2>&1; then
                write_mod_error "Invalid tarball, could not download ${DOCKER_MOD} from ${REGISTRY}"
                continue
            fi
            write_mod_info "Installing ${DOCKER_MOD}"
            tar xzf /modtarball.tar.xz -C /tmp/mod
            # Remove any v2 mod elements as they're no longer supported
            if [[ -d /tmp/mod/etc/cont-init.d ]]; then
                rm -rf /tmp/mod/etc/cont-init.d
            fi
            if [[ -d /tmp/mod/etc/services.d ]]; then
                rm -rf /tmp/mod/etc/services.d
            fi
            shopt -s dotglob
            cp -R /tmp/mod/* /
            shopt -u dotglob
            rm -rf /tmp/mod
            rm -rf /modtarball.tar.xz
            echo "${SHALAYER}" >"/${FILENAME}"
            write_mod_info "${DOCKER_MOD} applied to container"
        fi
    done
}

run_mods_local() {
    write_mod_info "Running Local Docker Modification Logic"
    for DOCKER_MOD in $(echo "${DOCKER_MODS}" | tr '|' '\n'); do
        # Check mod file exists
        if [[ -n "$(/bin/ls -A "/mods/${DOCKER_MOD}.tar" 2>/dev/null)" ]]; then
            # Caculate mod bits
            FILENAME="${DOCKER_MOD}.local"
            SHALAYER=$(sha256sum "/mods/${DOCKER_MOD}.tar" | cut -d " " -f 1)
            # Check if we have allready applied this layer
            if [[ -f "/${FILENAME}" ]] && [[ "${SHALAYER}" == "$(cat /"${FILENAME}")" ]]; then
                write_mod_info "${DOCKER_MOD} at ${SHALAYER} has been previously applied, skipping"
            else
                write_mod_info "Installing ${DOCKER_MOD}"
                mkdir -p "/tmp/mod/${DOCKER_MOD}"
                tar xf "/mods/${DOCKER_MOD}.tar" -C /tmp/mod --strip-components=1
                tar xf "/tmp/mod/layer.tar" -C "/tmp/mod/${DOCKER_MOD}"
                # Remove any v2 mod elements as they're no longer supported
                if [[ -d "/tmp/mod/${DOCKER_MOD}/etc/cont-init.d" ]]; then
                    rm -rf "/tmp/mod/${DOCKER_MOD}/etc/cont-init.d"
                fi
                if [[ -d "/tmp/mod/${DOCKER_MOD}/etc/services.d" ]]; then
                    rm -rf "/tmp/mod/${DOCKER_MOD}/etc/services.d"
                fi
                shopt -s dotglob
                cp -R "/tmp/mod/${DOCKER_MOD}"/* /
                shopt -u dotglob
                rm -rf "/tmp/mod/${DOCKER_MOD}"
                echo "${SHALAYER}" >"/${FILENAME}.local"
                write_mod_info "${DOCKER_MOD} applied to container"
            fi
        else
            write_mod_error "${DOCKER_MOD}.tar not found in /mods, skipping"
        fi
    done
}

if [[ -n "${DOCKER_MODS}" ]]; then
    curl_check
    run_mods
fi