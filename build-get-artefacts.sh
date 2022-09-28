#!/usr/bin/env bash

if [ -z "${SUDO_USER}" ]; then
    echo "ERROR! You must use sudo to run this script: sudo ./$(basename "${0}")"
    exit 1
else
    SUDO_HOME=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
fi

if [ -z "${1}" ] || [ -z "${2}" ]; then
    echo "Usage: $(basename "${0}") <codename> <obs_ver>"
    exit 1
fi

DISTRO="${1}"
OBS_VER="${2}"

case "${DISTRO}" in
    focal) DISTRO_VER="20.04";;
    jammy) DISTRO_VER="22.04";;
    kinetic) DISTRO_VER="22.10";;
    *) echo "ERROR! Unknown Ubuntu release: ${DISTRO}"
      exit 1;;
esac

case "${OBS_VER}" in
    27|28) true;;
    *) echo "ERROR! Unsupported OBS Studio version: ${OBS_VER}"
      exit 1;;
esac

if [ -d "${SUDO_HOME}/Builds/obs-builder-${DISTRO}/root/obs-${OBS_VER}" ]; then
    cp -v "${SUDO_HOME}/Builds/obs-builder-${DISTRO}/root/obs-${OBS_VER}"/obs-portable-${OBS_VER}*-ubuntu-${DISTRO_VER}.* artefacts/
    chown "${SUDO_USER}":"${SUDO_USER}" artefacts/obs-portable-${OBS_VER}*-ubuntu-${DISTRO_VER}.*
fi
