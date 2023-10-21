#!/usr/bin/env bash

if [ -z "${SUDO_USER}" ]; then
    echo "ERROR! You must use sudo to run this script: sudo ./$(basename "${0}")"
    exit 1
fi

if [ -z "${1}" ] || [ -z "${2}" ]; then
    echo "Usage: $(basename "${0}") <codename> <obs_ver|all>"
    exit 1
fi

. "$(dirname "$0")/build-config"

if [ "${1}" = "all" ]; then
    DISTROS="${TARGETABLE_DISTROS[@]}"
elif [[ "${TARGETABLE_DISTROS[@]}" =~ "${1}" ]]; then
    DISTROS="${1}"
else
    echo "ERROR! Unknown Ubuntu release: ${1}"
    exit 1
fi

if [ "${2}" = "all" ]; then
    OBS_VERS="${TARGETABLE_VERSIONS[@]}"
elif [[ "${TARGETABLE_VERSIONS[@]}" =~ "${2}" ]]; then
    OBS_VERS="${2}"
else
    echo "ERROR! Unsupported OBS Studio version: ${2}"
    exit 1
fi

PLUGIN_LIST="auxiliary"
if [ "${3}" == "essential" ]; then
    PLUGIN_LIST="essential"
fi

for DISTRO in ${DISTROS}; do
    for OBS_VER in ${OBS_VERS}; do
        ./build-validate.sh "${DISTRO}" "${OBS_VER}" || continue
        ./build-trash.sh "${DISTRO}"
        ./build-bootstrap.sh "${DISTRO}"
        ./build-enter.sh "${DISTRO}" "/root/obs-build.sh ${OBS_VER}" "${PLUGIN_LIST}"
        ./build-get-artefacts.sh "${DISTRO}" "${OBS_VER}" "${PLUGIN_LIST}"
    done
done
