#!/usr/bin/env bash

DISTRO="${1}"
OBS_VER="${2}"
OBS_MAJ_VER="${OBS_VER%%.*}"

if [ "${DISTRO}" == "focal" ] && [ "${OBS_MAJ_VER}" -ge 30 ]; then
    # OBS Studio 30+ is not support on Ubuntu 20.04
    exit 1
fi

# Build is allowed to proceed
exit 0
