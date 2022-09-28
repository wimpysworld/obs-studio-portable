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

if [ -n "${2}" ]; then
    CMD="${2}"
else
    CMD="/bin/bash"
fi

case "${DISTRO}" in
    focal|jammy|kinetic) true;;
    *) echo "ERROR! Unknown version: ${DISTRO}"
       exit 1
       ;;
esac

R="${SUDO_HOME}/Builds/obs-builder-${DISTRO}"
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
    ${CMD}

if [ -e "${R}/etc/apt/apt.conf.d/90cache" ]; then
    rm -f "${R}/etc/apt/apt.conf.d/90cache"
fi
