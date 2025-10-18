#!/bin/bash

declare -g -x -a striptracks_skip_profile

profileName="$1"
striptracks_skip_profile+=("abc")
striptracks_skip_profile+=("My Profile")
striptracks_skip_profile+=("SD")


if [ ${#striptracks_skip_profile[@]} -gt 0 ]; then
    for skip_profile in "${striptracks_skip_profile[@]}"; do
        if [ "$skip_profile" = "$profileName" ]; then
            message="Info|Skipping processing because quality profile '$profileName' is configured to be skipped."
            echo "$message"
            exit 0
        fi
    done
    echo "Debug|Quality profile '$profileName' does not match any configured to skip: '$(printf "%s," "${striptracks_skip_profile[@]}" | sed -e 's/,$//')'"
fi

