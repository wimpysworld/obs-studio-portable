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
    *) echo "ERROR! Unknown version: ${DISTRO}"
      exit 1
      ;;
esac

R="${SUDO_HOME}/Builds/obs-builder-${DISTRO}"
if [ -d "${R}" ]; then
    rm -rf "${R}"
fi
