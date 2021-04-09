#!/usr/bin/env bash
set -eEo pipefail

### Set Debug Mode
if [ "$DEBUG_MODE" = "TRUE" ] || [ "$DEBUG_MODE" = "true" ]; then
    set -x
fi

export GOSS_FILES_STRATEGY=cp

services=( $(yq r docker-compose.yml -j | jq '.services | keys' | yq r - | cut -d ' ' -f 2) )

for j in "${!services[@]}"; do
    service="${services[j]}"
    printf "### Testing service %s with goss\n" "${service}"
    image=$(yq r docker-compose.yml services.["${service}"] -j | jq .image | yq r -)
    context=$(yq r docker-compose.yml services.["${service}"] -j | jq .build.context | yq r -)
    (
        if [ -f "${context}/goss.yaml" ]; then
            GOSS_FILES_PATH="${context}"
        fi
        if [ -f "goss.yaml" ]; then
            GOSS_FILES_PATH="."
        fi

        printf "Testing with gossfile %s/goss.yaml\n" "${GOSS_FILES_PATH}"

        if [ -f "${context}/vars" ]; then
            VARS_FILE="${context}/vars"
        fi
        if [ -f "vars" ]; then
            VARS_FILE="vars"
        fi
        if [ -n "${VARS_FILE}" ]; then
            printf "Additional vars:\n"
            cat "${VARS_FILE}"
            printf "\n"
            set -o allexport
            source "${VARS_FILE}"
            set +o allexport
        fi

        if [ "$DEBUG_MODE" = "TRUE" ] || [ "$DEBUG_MODE" = "true" ]; then
            set -x
        fi
        set -eEo pipefail
        GOSS_FILES_PATH="${GOSS_FILES_PATH}" dgoss-ci run "${image}"

    )
    printf "### Testing service %s with dive\n" "${service}"
    CI=true dive "${image}"
    unset GOSS_FILES_PATH
    unset VARS_FILE
done
