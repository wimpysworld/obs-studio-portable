#!/usr/bin/env bash

DISTRO="${1}"
OBS_VER="${2}"
OBS_MAJ_VER="${OBS_VER%%.*}"

if [ "${DISTRO}" == "focal" ] && [ "${OBS_MAJ_VER}" -ge 30 ]; then
    # OBS Studio 30+ is not supported on Ubuntu 20.04
    exit 1
fi

# Build is allowed to proceed
echo "Building OBS ${OBS_VER} on ${DISTRO}"
exit 0
