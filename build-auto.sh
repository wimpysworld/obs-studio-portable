#!/usr/bin/env bash

if [ -z "${SUDO_USER}" ]; then
    echo "ERROR! You must use sudo to run this script: sudo ./$(basename "${0}")"
    exit 1
else
    SUDO_HOME=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
fi

if [ -z "${1}" ] || [ -z "${2}" ]; then
    echo "Usage: $(basename "${0}") <codename> <obs_ver|all>"
    exit 1
fi

case "${1}" in
    focal|jammy|kinetic) DISTRO="${1}";;
    *) echo "ERROR! Unknown Ubuntu release: ${1}"
      exit 1;;
esac

case "${2}" in
    26|27|28) OBS_VERS="${2}";;
    all)      OBS_VERS="26 27 28";;
    *) echo "ERROR! Unsupported OBS Studio version: ${2}"
       exit 1;;
esac

for OBS_VER in ${OBS_VERS}; do
    if [ "${DISTRO}" == "kinetic" ] && [ "${OBS_VER}" -le 27 ]; then
        # Do not try and build old OBS versions on Ubuntu 22.10
        continue
    fi
    ./build-trash.sh "${DISTRO}"
    ./build-bootstrap.sh "${DISTRO}"
    ./build-enter.sh "${DISTRO}" "/root/obs-portable.sh ${OBS_VER}"
    ./build-get-artefacts.sh "${DISTRO}" "${OBS_VER}"
done
