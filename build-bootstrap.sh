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
