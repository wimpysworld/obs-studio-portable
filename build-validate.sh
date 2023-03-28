#!/usr/bin/env bash

DISTRO="${1}"
OBS_VER="${2}"
OBS_MAJ_VER="${OBS_VER%%.*}"

# Do not try and build old OBS versions on Ubuntu 22.10 or newer
if [ "${DISTRO}" == "lunar" ] && [ "${OBS_MAJ_VER}" -le 27 ]; then
    exit 1
elif [ "${DISTRO}" == "kinetic" ] && [ "${OBS_MAJ_VER}" -le 27 ]; then
    exit 1
fi

# Build is allowed to proceed
exit 0
