#!/usr/bin/env bash

DISTRO="${1}"
OBS_VER="${2}"
OBS_MAJ_VER="${OBS_VER%%.*}"

if [ "${DISTRO}" == "focal" ]; then
    # Ubuntu 20.04 is no longer supported
    exit 1
fi

# Build is allowed to proceed
echo "Building OBS ${OBS_VER} on ${DISTRO}"
exit 0
