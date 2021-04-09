#!/usr/bin/env bash
set -eEo pipefail

### Set Debug Mode
if [ "$DEBUG_MODE" = "TRUE" ] || [ "$DEBUG_MODE" = "true" ]; then
    set -x
fi

services=($(yq r docker-compose.yml -j | jq '.services | keys' | yq r - | cut -d ' ' -f 2))

for j in "${!services[@]}"; do
    service="${services[j]}"
    printf "###Testing service %s\n" "${service}"
    image=$(yq r docker-compose.yml services.["${service}"] -j | jq .image | yq r -)
    docker image rm -f "${image}"
done
