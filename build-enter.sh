#!/usr/bin/env bash

if [ -z "${SUDO_USER}" ]; then
    echo "ERROR! You must use sudo to run this script: sudo ./$(basename "${0}")"
    exit 1
else
    BUILDS_DIR="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
fi

BUILDS_DIR="${OVERRIDE_BUILDS_DIR:-$BUILDS_DIR}"

if [ -z "${1}" ]; then
    echo "Usage: $(basename "${0}") <codename>"
    exit 1
fi
DISTRO="${1}"

if [ -n "${2}" ]; then
    CMD="${2}"
else
    CMD="/bin/bash"
fi

. "$(dirname "$0")/build-config"

if [[ "${TARGETABLE_DISTROS[@]}" =~ "${DISTRO}" ]]; then
    true
else
    echo "ERROR! Unknown version: ${DISTRO}"
    exit 1
fi

R="${BUILDS_DIR}/Builds/obs-builder-${DISTRO}"
APT_CACHE_IP=$(ip route get 1.1.1.1 | head -n 1 | cut -d' ' -f 7)

if pidof -q apt-cacher-ng && [ -d "${R}/etc/apt/apt.conf.d" ]; then
    echo "Acquire::http { Proxy \"http://${APT_CACHE_IP}:3142\"; }" > "${R}/etc/apt/apt.conf.d/90cache"
fi

echo "nameserver 1.1.1.1" > "/tmp/resolv-${DISTRO}.conf"
systemd-nspawn \
    --bind-ro="/tmp/resolv-${DISTRO}.conf":/etc/resolv.conf \
    --chdir=/root \
    --directory "${R}" \
    --hostname="${DISTRO}" \
    --machine="${DISTRO}" \
    --resolv-conf=off \
    --setenv=TWITCH_CLIENT_ID \
    --setenv=TWITCH_HASH \
    --setenv=RESTREAM_CLIENTID \
    --setenv=RESTREAM_HASH \
    --setenv=YOUTUBE_CLIENTID \
    --setenv=YOUTUBE_CLIENTID_HASH \
    --setenv=YOUTUBE_SECRET \
    --setenv=YOUTUBE_SECRET_HASH \
    ${CMD}

if [ -e "${R}/etc/apt/apt.conf.d/90cache" ]; then
    rm -f "${R}/etc/apt/apt.conf.d/90cache"
fi
