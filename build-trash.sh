#!/usr/bin/env bash

if [ -z "${SUDO_USER}" ]; then
    echo "ERROR! You must use sudo to run this script: sudo ./$(basename "${0}")"
    exit 1
else
    BUILDS_DIR="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
fi

BUILDS_DIR="${OVERRIDE_BUILDS_DIR:-$BUILDS_DIR}"

if [ -z "${1}" ]; then
    echo "Usage: $(basename "${0}") <codename>"
    exit 1
fi

. "$(dirname "$0")/build-config"

DISTRO="${1}"
if [[ "${TARGETABLE_DISTROS[@]}" =~ "${DISTRO}" ]]; then
    true
else
    echo "ERROR! Unknown version: ${DISTRO}"
    exit 1
fi

R="${BUILDS_DIR}/Builds/obs-builder-${DISTRO}"
if [ -d "${R}" ]; then
    rm -rf "${R}"
fi
