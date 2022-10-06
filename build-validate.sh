#!/usr/bin/env bash

if [ "${1}" = "kinetic" ] && [ "${2}" -le 27 ]; then
    # Do not try and build old OBS versions on Ubuntu 22.10
    exit 1
fi

# Build is allowed to proceed
exit 0
