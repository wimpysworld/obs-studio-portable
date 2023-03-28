#!/usr/bin/env bash

if [ -z "${SUDO_USER}" ]; then
    echo "ERROR! You must use sudo to run this script: sudo ./$(basename "${0}")"
    exit 1
else
    BUILDS_DIR="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
fi

BUILDS_DIR="${OVERRIDE_BUILDS_DIR:-$BUILDS_DIR}"

if [ -z "${1}" ] || [ -z "${2}" ]; then
    echo "Usage: $(basename "${0}") <codename> <obs_ver>"
    exit 1
fi

DISTRO="${1}"
case "${DISTRO}" in
    focal) DISTRO_VER="20.04";;
    jammy) DISTRO_VER="22.04";;
    kinetic) DISTRO_VER="22.10";;
    lunar) DISTRO_VER="23.04";;
    *) echo "ERROR! Unknown Ubuntu release: ${DISTRO}"
      exit 1;;
esac

OBS_VER="${2}"
OBS_MAJ_VER="${OBS_VER%%.*}"
case "${OBS_MAJ_VER}" in
    26|27|28|29)
        if [ -d "${BUILDS_DIR}/Builds/obs-builder-${DISTRO}/root/obs-${OBS_MAJ_VER}" ]; then
            cp -v "${BUILDS_DIR}/Builds/obs-builder-${DISTRO}/root/obs-${OBS_MAJ_VER}/obs-portable-${OBS_VER}"*-ubuntu-${DISTRO_VER}.* artefacts/
            chown "${SUDO_USER}":"${SUDO_USER}" "artefacts/obs-portable-${OBS_VER}"*-ubuntu-${DISTRO_VER}.*
        fi;;
    *) echo "ERROR! Unsupported OBS Studio version: ${OBS_VER}"
       exit 1;;
esac
