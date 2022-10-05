#!/usr/bin/env bash

if [ -z "${SUDO_USER}" ]; then
    echo "ERROR! You must use sudo to run this script: sudo ./$(basename "${0}")"
    exit 1
else
    BUILDS_DIR=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
fi

BUILDS_DIR="${OVERRIDE_BUILDS_DIR:-$BUILDS_DIR}"

if [ -z "${1}" ]; then
    echo "Usage: $(basename "${0}") <codename>"
    exit 1
fi

. "$(dirname "$0")/build-config"

DISTRO="${1}"
if [[ "${TARGETABLE_DISTROS[@]}" =~ "${DISTRO}" ]]; then
    true
else
    echo "ERROR! Unknown version: ${DISTRO}"
    exit 1
fi

R="${BUILDS_DIR}/Builds/obs-builder-${DISTRO}"

if [ ! -d "${R}" ]; then
    apt-get -y install debootstrap systemd-container debian-archive-keyring ubuntu-keyring

    if pidof apt-cacher-ng; then
        REPO="http://localhost:3142/gb.archive.ubuntu.com/ubuntu/"
    else
        REPO="http://gb.archive.ubuntu.com/ubuntu/"
    fi

    debootstrap \
        --components=main,restricted,universe,multiverse \
        --exclude=ubuntu-minimal,ubuntu-advantage-tools \
        --include=nano,systemd-container \
        "${DISTRO}" "${R}" "${REPO}"

    # Make sure the container has a machine-id
    systemd-machine-id-setup --root "${R}" --print
    echo "127.0.0.1    localhost ${DISTRO}" > "${R}/etc/hosts"

    # Set locale to C.UTF-8 by default.
    # https://git.launchpad.net/livecd-rootfs/tree/live-build/auto/build#n159
    echo "LANG=C.UTF-8" > "${R}/etc/default/locale"

    echo "
deb http://gb.archive.ubuntu.com/ubuntu/ ${DISTRO} main restricted universe multiverse
deb http://gb.archive.ubuntu.com/ubuntu/ ${DISTRO}-updates main restricted universe multiverse
deb http://gb.archive.ubuntu.com/ubuntu/ ${DISTRO}-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu ${DISTRO}-security main restricted universe multiverse" > "${R}/etc/apt/sources.list"
else
    echo "WARNING! ${R} already exists!"
    echo "         Updating OBS build scripts only."
fi

cp builder/* "${R}/root/"
