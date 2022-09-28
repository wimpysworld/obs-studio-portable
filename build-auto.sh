#!/usr/bin/env bash

if [ -z "${SUDO_USER}" ]; then
    echo "ERROR! You must use sudo to run this script: sudo ./$(basename "${0}")"
    exit 1
else
    SUDO_HOME=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
fi

if [ -z "${1}" ]; then
    echo "Usage: $(basename "${0}") <codename>"
    exit 1
fi
DISTRO="${1}"

case "${DISTRO}" in
    focal|jammy|kinetic) true;;
    *) echo "ERROR! Unknown Ubuntu release: ${DISTRO}"
      exit 1;;
esac

for OBS_VER in 27 28; do
    if [ "${DISTRO}" == "kinetic" ] && [ "${OBS_VER}" == "27" ]; then
        continue
    fi
    ./build-trash.sh "${DISTRO}"
    ./build-bootstrap.sh "${DISTRO}"
    ./build-enter.sh "${DISTRO}" "/root/obs-portable.sh ${OBS_VER}"
    ./build-get-artefacts.sh "${DISTRO}" "${OBS_VER}"
done
