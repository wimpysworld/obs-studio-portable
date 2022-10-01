#!/usr/bin/env bash
set -ex
LC_ALL=C

# https://obsproject.com/wiki/Build-Instructions-For-Linux

# Plugins to consider:
# - https://git.vrsal.xyz/alex/Durchblick
# - https://github.com/norihiro/obs-async-audio-filter
# - https://github.com/norihiro/obs-source-record-async
# - https://github.com/norihiro/obs-color-monitor
# - https://github.com/norihiro/obs-output-filter
# - https://github.com/norihiro/obs-main-view-source
# - https://github.com/norihiro/obs-vnc

OBS_MAJ_VER=""
if [ -n "${1}" ]; then
    OBS_MAJ_VER="${1}"
fi

BASE_DIR="${HOME}/obs-${OBS_MAJ_VER}"
BUILD_DIR="${BASE_DIR}/build"
BUILD_PORTABLE="${BASE_DIR}/build_portable"
BUILD_SYSTEM="${BASE_DIR}/build_system"
PLUGIN_DIR="${BASE_DIR}/plugins"
SOURCE_DIR="${BASE_DIR}/source"
TARBALL_DIR="${BASE_DIR}/tarballs"

case ${OBS_MAJ_VER} in
    clean)
        rm -rf "${BASE_DIR}/"{build,build_portable,build_system,plugins}
        rm -rf "${SOURCE_DIR}/ntv2/build/"
        exit 0;;
    veryclean)
        rm -rf "${BASE_DIR}/"{build,build_portable,build_system,plugins,source}
        rm -rf "${SOURCE_DIR}/ntv2/build/"
        exit 0;;
    28)
        AJA_VER="v16.2-bugfix5"
        OBS_VER="28.0.2"
        CEF_VER="5060";;
    27)
        AJA_VER="v16.2-bugfix5"
        OBS_VER="27.2.4"
        CEF_VER="4638";;
    26)
        AJA_VER=""
        OBS_VER="26.1.2"
        CEF_VER="4280";;
    25)
        AJA_VER=""
        OBS_VER="25.0.8"
        CEF_VER="3770"
        echo "ERROR! Unsupported version: ${OBS_MAJ_VER}"
        exit 1;;
  *)
        echo "ERROR! Unsupported version: ${OBS_MAJ_VER}"
        exit 1;;
esac

if [ -e /etc/os-release ] && grep --quiet UBUNTU_CODENAME /etc/os-release; then
    DISTRO_CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d'=' -f2 | sed 's/"//g')
    DISTRO_VERSION=$(grep VERSION_ID /etc/os-release | cut -d'=' -f2 | sed 's/"//g')
    DISTRO_CMP_VER="${DISTRO_VERSION//./}"
    if [ "${DISTRO_CMP_VER}" -lt 2004 ]; then
        echo "Unsupported Ubuntu version: ${DISTRO_VERSION}"
        exit 1
    fi
else
    echo "Unsupported Linux distribution."
    exit 1
fi

# Make the directories
mkdir -p "${BASE_DIR}"/{build,build_portable,build_system,plugins,source,tarballs}
STAMP=$(date +%y%j)
INSTALL_DIR="obs-portable-${OBS_VER}-r${STAMP}-ubuntu-${DISTRO_VERSION}"

function download_file() {
    local URL="${1}"
    local FILE="${URL##*/}"
    local PROJECT=""

    if [[ "${URL}" == *"github"* ]]; then
      PROJECT=$(echo "${URL}" | cut -d'/' -f5)
      FILE="${PROJECT}-${FILE}"
    fi

    # Check the file passes decompression test
    if [ -e "${TARBALL_DIR}/${FILE}" ]; then
        EXT="${FILE##*.}"
        case "${EXT}" in
            bzip2|bz2) FILE_TEST="bzip2 -t";;
            gzip|gz) FILE_TEST="gzip -t";;
            xz) FILE_TEST="xz -t";;
            zip) FILE_TEST="unzip -qq -t";;
            *) FILE_TEST="";;
        esac
        if [ -n "${FILE_TEST}" ]; then
            if ! ${FILE_TEST} "${TARBALL_DIR}/${FILE}"; then
                echo "Testing ${TARBALL_DIR}/${FILE} integrity failed. Deleting it."
                rm "${TARBALL_DIR}/${FILE}" 2>/dev/null
                exit 1
            fi
        fi
    elif ! wget --quiet --show-progress --progress=bar:force:noscroll "${URL}" -O "${TARBALL_DIR}/${FILE}"; then
        echo "Failed to download ${URL}. Deleting ${TARBALL_DIR}/${FILE}..."
        rm "${TARBALL_DIR}/${FILE}" 2>/dev/null
        exit 1
    fi
}

function download_tarball() {
    local URL="${1}"
    local DIR="${2}"
    local FILE="${URL##*/}"
    local PROJECT=""

    if [[ "${URL}" == *"github"* ]]; then
        PROJECT=$(echo "${URL}" | cut -d'/' -f5)
        FILE="${PROJECT}-${FILE}"
    fi

    if [ ! -d "${DIR}" ]; then
        mkdir -p "${DIR}"
    fi

    # Only download and extract if the directory is empty
    if [ -d "${DIR}" ] && [ -z "$(ls -A "${DIR}")" ]; then
        download_file "${URL}"
        bsdtar --strip-components=1 -xf "${TARBALL_DIR}/${FILE}" -C "${DIR}"
    else
        echo " - ${DIR} already exists. Skipping..."
    fi
    echo " - ${URL}" >> "${BUILD_DIR}/obs-manifest.txt"
}

function clone_source() {
    local REPO="${1}"
    local BRANCH="${2}"
    local CWD=""
    local BRANCH_LEN=""
    local DIR="${3}"

    if [ ! -d "${DIR}/.git" ]; then
        BRANCH_LEN=$(echo -n "${BRANCH}" | wc -m);
        if [ "${BRANCH_LEN}" -eq 40 ]; then
            CWD=$(pwd)
            git clone "${REPO}" --filter=tree:0 --recurse-submodules --shallow-submodules "${DIR}"
            cd "${DIR}"
            git checkout "${BRANCH}"
            cd "${CWD}"
        else
            git clone "${REPO}" --filter=tree:0 --recurse-submodules --shallow-submodules --branch "${BRANCH}" "${DIR}"
        fi
    fi
    echo " - ${REPO} (${BRANCH})" >> "${BUILD_DIR}/obs-manifest.txt"
}

function stage_01_get_apt() {
    echo -e "\nBuild dependencies\n" >> "${BUILD_DIR}/obs-manifest.txt"

    if [ "${DISTRO_CMP_VER}" -eq 2004 ]; then
        # Newer cmake, ninja-build, meson for Ubuntu 20.04
        apt-get -y update
        apt-get -y install software-properties-common
        add-apt-repository -y ppa:flexiondotorg/build-tools
        COMPILERS="gcc-10 g++-10 golang-1.16-go"
    else
        apt-get -y update
        COMPILERS="gcc g++ golang-go"
    fi

    apt-get -y upgrade

    PKG_TOOLCHAIN="bzip2 clang-format clang-tidy cmake curl ${COMPILERS} file git libarchive-tools libc6-dev make meson ninja-build pkg-config unzip wget"
    echo " - Toolchain   : ${PKG_TOOLCHAIN}" >> "${BUILD_DIR}/obs-manifest.txt"
    #shellcheck disable=SC2086
    apt-get -y install ${PKG_TOOLCHAIN}

    if [ "${DISTRO_CMP_VER}" -eq 2004 ]; then
        update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 800 --slave /usr/bin/g++ g++ /usr/bin/g++-10
        update-alternatives --install /usr/bin/go go /usr/lib/go-1.16/bin/go 10
    fi

    if [ "${OBS_MAJ_VER}" -ge 28 ] && [ "${DISTRO_CMP_VER}" -ge 2204 ]; then
        PKG_OBS_QT="qt6-base-dev qt6-base-private-dev qt6-wayland libqt6svg6-dev"
    else
        PKG_OBS_QT="qtbase5-dev qtbase5-private-dev qtwayland5 libqt5svg5-dev libqt5x11extras5-dev"
    fi
    echo " - Qt          : ${PKG_OBS_QT}" >> "${BUILD_DIR}/obs-manifest.txt"
    #shellcheck disable=SC2086
    apt-get -y install ${PKG_OBS_QT}

    PKG_OBS_CORE="libavcodec-dev libavdevice-dev libavfilter-dev libavformat-dev \
libavutil-dev libswresample-dev libswscale-dev libcmocka-dev libcurl4-openssl-dev \
libgl1-mesa-dev libgles2-mesa-dev libglvnd-dev libjansson-dev libluajit-5.1-dev \
libmbedtls-dev libpci-dev libvulkan-dev libwayland-dev libx11-dev libx11-xcb-dev \
libx264-dev libxcb-composite0-dev libxcb-randr0-dev libxcb-shm0-dev libxcb-xfixes0-dev \
libxcb-xinerama0-dev libxcb1-dev libxcomposite-dev libxinerama-dev libxss-dev \
python3-dev swig"

    # SRT & RIST Protocol Support
    if [ "${OBS_MAJ_VER}" -ge 28 ] && [ "${DISTRO_CMP_VER}" -ge 2210 ]; then
        PKG_OBS_CORE+=" librist-dev libsrt-openssl-dev"
    fi
    echo " - OBS Core    : ${PKG_OBS_CORE}" >> "${BUILD_DIR}/obs-manifest.txt"
    #shellcheck disable=SC2086
    apt-get -y install ${PKG_OBS_CORE}

    PKG_OBS_PLUGINS="libasound2-dev libdrm-dev libfdk-aac-dev libfontconfig-dev \
libfreetype6-dev libjack-jackd2-dev libpulse-dev libspeexdsp-dev \
libudev-dev libv4l-dev libva-dev libvlc-dev"

    # CEF Browser runtime requirements
    PKG_OBS_PLUGINS+=" libatk-bridge2.0-0 libcups2 libnspr4 libnss3 libxtst6"

    if [ "${DISTRO_CMP_VER}" -ge 2204 ]; then
        PKG_OBS_PLUGINS+=" libpipewire-0.3-dev"
    else
        PKG_OBS_PLUGINS+=" libpipewire-0.2-dev"
    fi

    echo " - OBS Plugins : ${PKG_OBS_PLUGINS}" >> "${BUILD_DIR}/obs-manifest.txt"
    #shellcheck disable=SC2086
    apt-get -y install ${PKG_OBS_PLUGINS}

    echo " - 3rd Party Plugins" >> "${BUILD_DIR}/obs-manifest.txt"
    # 3rd party plugin dependencies:
    PKG_OBS_SCENESWITCHER="libprocps-dev libxss-dev libxtst-dev"
    if [ "${OBS_MAJ_VER}" -ge 27 ]; then
        PKG_OBS_SCENESWITCHER+=" libopencv-dev"
    fi
    echo "   - SceneSwitcher  : ${PKG_OBS_SCENESWITCHER}" >> "${BUILD_DIR}/obs-manifest.txt"
    #shellcheck disable=SC2086
    apt-get -y install ${PKG_OBS_SCENESWITCHER}

    PKG_OBS_WAVEFORM="libfftw3-dev"
    echo "   - Waveform       : ${PKG_OBS_WAVEFORM}" >> "${BUILD_DIR}/obs-manifest.txt"
    apt-get -y install ${PKG_OBS_WAVEFORM}

    PKG_OBS_FACETRACKER="liblapack-dev libopenblas-dev"
    case "${DISTRO_CMP_VER}" in
        2204|2210) PKG_OBS_FACETRACKER+=" libcublas11";;
        2004)      PKG_OBS_FACETRACKER+=" libcublas10";;
    esac
    echo "   - Face Tracker   : ${PKG_OBS_FACETRACKER}" >> "${BUILD_DIR}/obs-manifest.txt"
    #shellcheck disable=SC2086
    apt-get -y install ${PKG_OBS_FACETRACKER}

    PKG_OBS_TEXT="libcairo2-dev libpango1.0-dev libpng-dev"
    echo "   - Pango/PThread  : ${PKG_OBS_TEXT}" >> "${BUILD_DIR}/obs-manifest.txt"
    #shellcheck disable=SC2086
    apt-get -y install ${PKG_OBS_TEXT}

    PKG_OBS_GSTREAMER="libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev"
    echo "   - GStreamer      : ${PKG_OBS_GSTREAMER}" >> "${BUILD_DIR}/obs-manifest.txt"
    #shellcheck disable=SC2086
    apt-get -y install ${PKG_OBS_GSTREAMER}

    PKG_OBS_VKCAPTURE="glslang-dev glslang-tools"
    echo "   - Game Capture   : ${PKG_OBS_VKCAPTURE}" >> "${BUILD_DIR}/obs-manifest.txt"
    #shellcheck disable=SC2086
    apt-get -y install ${PKG_OBS_VKCAPTURE}

    if [ "${DISTRO_CMP_VER}" -ge 2204 ] && [ "${OBS_MAJ_VER}" -ge 27 ]; then
        PKG_OBS_STREAMFX="libaom-dev"
        echo "   - StreamFX       : ${PKG_OBS_STREAMFX}" >> "${BUILD_DIR}/obs-manifest.txt"
        apt-get -y install ${PKG_OBS_STREAMFX}
    fi
}

function stage_02_get_obs() {
    echo -e "\nOBS Studio\n" >> "${BUILD_DIR}/obs-manifest.txt"
    clone_source "https://github.com/obsproject/obs-studio.git" "${OBS_VER}" "${SOURCE_DIR}"
}

function stage_03_get_cef() {
    download_tarball "https://cdn-fastly.obsproject.com/downloads/cef_binary_${CEF_VER}_linux64.tar.bz2" "${BUILD_DIR}/cef"
    mkdir -p "${BASE_DIR}/${INSTALL_DIR}/cef"
    cp -a "${BUILD_DIR}/cef/Release/"* "${BASE_DIR}/${INSTALL_DIR}/cef/"
    cp -a "${BUILD_DIR}/cef/Resources/"* "${BASE_DIR}/${INSTALL_DIR}/cef/"
    cp "${BUILD_DIR}/cef/"{LICENSE.txt,README.txt} "${BASE_DIR}/${INSTALL_DIR}/cef/"
    chmod 755 "${BASE_DIR}/${INSTALL_DIR}/cef/locales"
}

function stage_04_get_aja() {
    if [ "${OBS_MAJ_VER}" -ge 27 ]; then
        download_tarball "https://github.com/aja-video/ntv2/archive/refs/tags/${AJA_VER}.tar.gz" "${SOURCE_DIR}/ntv2"
        cmake -S "${SOURCE_DIR}/ntv2/" -B "${SOURCE_DIR}/ntv2/build/" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DAJA_BUILD_OPENSOURCE=ON \
        -DAJA_BUILD_APPS=OFF \
        -DAJA_INSTALL_HEADERS=ON | tee "${BUILD_DIR}/cmake-aja.log"
        cmake --build "${SOURCE_DIR}/ntv2/build/"
        cmake --install "${SOURCE_DIR}/ntv2/build/" --prefix "${BUILD_DIR}/aja"
    fi
}

function stage_05_build_obs() {
    local TARGET="system"
    if [ -n "${1}" ]; then
        TARGET="${1}"
    fi

    if [ "${DISTRO_CMP_VER}" -ge 2204 ]; then
        PIPEWIRE_OPTIONS="-DENABLE_PIPEWIRE=ON"
    else
        PIPEWIRE_OPTIONS="-DENABLE_PIPEWIRE=OFF"
    fi

    if [ "${OBS_MAJ_VER}" -ge 28 ]; then
        RTMPS_OPTIONS="-DENABLE_RTMPS=ON"
        BROWSER_OPTIONS="-DENABLE_BROWSER=ON"
        VST_OPTIONS="-DENABLE_VST=ON"
        if [ "${DISTRO_CMP_VER}" -ge 2210 ]; then
            RTMPS_OPTIONS+=" -DENABLE_NEW_MPEGTS_OUTPUT=ON"
        else
            RTMPS_OPTIONS+=" -DENABLE_NEW_MPEGTS_OUTPUT=OFF"
        fi
    else
        RTMPS_OPTIONS="-DWITH_RTMPS=ON"
        BROWSER_OPTIONS="-DBUILD_BROWSER=ON"
        VST_OPTIONS="-DBUILD_VST=ON"
    fi

    case "${TARGET}" in
      portable)
        BUILD_TO="${BUILD_PORTABLE}"
        INSTALL_TO="${BASE_DIR}/${INSTALL_DIR}"
        if [ "${OBS_MAJ_VER}" -ge 28 ]; then
          PORTABLE_OPTIONS="-DLINUX_PORTABLE=ON"
        else
          PORTABLE_OPTIONS="-DUNIX_STRUCTURE=OFF"
        fi
        STREAMFX_OPTIONS="-DStreamFX_ENABLE_CLANG=OFF -DStreamFX_ENABLE_FRONTEND=OFF -DStreamFX_ENABLE_UPDATER=OFF"
        ;;
      system)
        BUILD_TO="${BUILD_SYSTEM}"
        INSTALL_TO="/usr"
        if [ "${OBS_MAJ_VER}" -ge 28 ]; then
          PORTABLE_OPTIONS="-DLINUX_PORTABLE=OFF"
        else
          PORTABLE_OPTIONS="-DUNIX_STRUCTURE=ON"
        fi;;
    esac

    #shellcheck disable=SC1091
    if [ -e ./obs-options.sh ]; then
        source ./obs-options.sh
        #shellcheck disable=SC2089
        if [ -n "${RESTREAM_CLIENTID}" ] && [ -n "${RESTREAM_HASH}" ]; then
            RESTREAM_OPTIONS="-DRESTREAM_CLIENTID='${RESTREAM_CLIENTID}' -DRESTREAM_HASH='${RESTREAM_HASH}'"
        fi
        #shellcheck disable=SC2089
        if [ -n "${TWITCH_CLIENTID}" ] && [ -n "${TWITCH_HASH}" ]; then
            TWITCH_OPTIONS="-DTWITCH_CLIENTID='${TWITCH_CLIENTID}' -DTWITCH_HASH='${TWITCH_HASH}'"
        fi
        #shellcheck disable=SC2089
        if [ "${OBS_MAJ_VER}" -ge 27 ] && [ -n "${YOUTUBE_CLIENTID}" ] && [ -n "${YOUTUBE_CLIENTID_HASH}" ] && [ -n "${YOUTUBE_SECRET}" ] &&  [ -n "${YOUTUBE_SECRET_HASH}" ]; then
            YOUTUBE_OPTIONS="-DYOUTUBE_CLIENTID='${YOUTUBE_CLIENTID}' -DYOUTUBE_CLIENTID_HASH='${YOUTUBE_CLIENTID_HASH}' -DYOUTUBE_SECRET='${YOUTUBE_SECRET}' -DYOUTUBE_SECRET_HASH='${YOUTUBE_SECRET_HASH}'"
        fi
    fi

    #shellcheck disable=SC2086,SC2090
    cmake -S "${SOURCE_DIR}/" -B "${BUILD_TO}/" -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${INSTALL_TO}" \
      -DENABLE_AJA=ON \
      -DAJA_LIBRARIES_INCLUDE_DIR="${BUILD_DIR}"/aja/include/ \
      -DAJA_NTV2_LIB="${BUILD_DIR}"/aja/lib/libajantv2.a \
      ${BROWSER_OPTIONS} \
      -DCEF_ROOT_DIR="${BUILD_DIR}/cef" \
      -DENABLE_ALSA=OFF \
      -DENABLE_JACK=ON \
      -DENABLE_LIBFDK=ON \
      ${PIPEWIRE_OPTIONS} \
      -DENABLE_PULSEAUDIO=ON \
      -DENABLE_VLC=ON \
      ${VST_OPTIONS} \
      -DENABLE_WAYLAND=ON \
      ${RTMPS_OPTIONS} \
      ${STREAMFX_OPTIONS} \
      ${YOUTUBE_OPTIONS} \
      ${TWITCH_OPTIONS} \
      ${RESTREAM_OPTIONS} \
      ${PORTABLE_OPTIONS} | tee "${BUILD_DIR}/cmake-obs-${TARGET}.log"

    cmake --build "${BUILD_TO}/"
    cmake --install "${BUILD_TO}/" --prefix "${INSTALL_TO}"

    # Make sure the libcaption headers are discoverable
    # Required by some out of tree plugins for OBS 26
    if [ "${OBS_MAJ_VER}" -eq 26 ] && [ "${TARGET}" == "system" ]; then
      mkdir -p /usr/include/caption/ || true
      cp "${SOURCE_DIR}/deps/libcaption/caption/"*.h "${SNAPCRAFT_STAGE}/usr/include/caption/"
    fi
}

function stage_06_plugins_in_tree() {
    echo -e "\nPlugins (in tree)\n" >> "${BUILD_DIR}/obs-manifest.txt"
    local BRANCH=""
    local DIRECTORY=""
    local PLUGIN=""
    local URL=""

    #shellcheck disable=SC2162
    while read REPO; do
        URL="$(echo "${REPO}" | cut -d'/' -f1-5)"
        PLUGIN="$(echo "${REPO}" | cut -d'/' -f5)"
        BRANCH="$(echo "${REPO}" | cut -d'/' -f6)"
        DIRECTORY="$(echo "${REPO}" | cut -d':' -f7-)"
        clone_source "${URL}.git" "${BRANCH}" "${SOURCE_DIR}/${DIRECTORY}/${PLUGIN}"
        grep -qxF "add_subdirectory(${PLUGIN})" "${SOURCE_DIR}/${DIRECTORY}/CMakeLists.txt" || echo "add_subdirectory(${PLUGIN})" >> "${SOURCE_DIR}/${DIRECTORY}/CMakeLists.txt"
    done < ./plugins-"${OBS_MAJ_VER}"-in-tree.txt

    # Monkey patch cmake VERSION for Ubuntu 20.04
    if [ "${DISTRO_CMP_VER}" -eq 2004 ]; then
        if [ "${OBS_MAJ_VER}" -ge 28 ]; then
            sed -i 's/VERSION 3\.21/VERSION 3\.18/' "${SOURCE_DIR}/UI/frontend-plugins/SceneSwitcher/CMakeLists.txt" || true
        fi
    fi
}

function stage_07_plugins_out_tree() {
    echo -e "\nPlugins (out of tree)\n" >> "${BUILD_DIR}/obs-manifest.txt"
    local BRANCH=""
    local CWD=""
    local DIRECTORY=""
    local PLUGIN=""
    local URL=""

    CWD="$(pwd)"
    #shellcheck disable=SC2162
    while read REPO; do
        URL="$(echo "${REPO}" | cut -d'/' -f1-5)"
        PLUGIN="$(echo "${REPO}" | cut -d'/' -f5)"
        BRANCH="$(echo "${REPO}" | cut -d'/' -f6)"

        # Insufficient Golang and PipeWire support in Ubuntu 20.04
        # obs-midi-ng requires Qt 6 which is not available in Ubuntu 20.04
        if [ "${DISTRO_CMP_VER}" -le 2004 ]; then
            if [ "${PLUGIN}" == "obs-midi-mg" ] || [ "${PLUGIN}" == "obs-pipewire-audio-capture" ] || [ "${PLUGIN}" == "obs-teleport" ]; then
                continue
            fi
        fi

        clone_source "${URL}.git" "${BRANCH}" "${PLUGIN_DIR}/${PLUGIN}"

        # Patch obs-websocket 4.9.1 (not the compat release) so it builds against OBS 27.2.4
        # https://github.com/obsproject/obs-websocket/issues/916#issuecomment-1193399097
        if [ "${PLUGIN}" == "obs-websocket" ] && [ "${BRANCH}" == "4.9.1" ]; then
            sed -r -i 's/OBS(.+?)AutoRelease/OBS\1AutoRelease_OBSWS/g' \
            "${PLUGIN_DIR}/${PLUGIN}"/src/*.h \
            "${PLUGIN_DIR}/${PLUGIN}"/src/*/*.h \
            "${PLUGIN_DIR}/${PLUGIN}"/src/*.cpp \
            "${PLUGIN_DIR}/${PLUGIN}"/src/*/*.cpp
        fi

        # obs-face-tracker requires that QT_VERSION is set
        local QT_VER="6"
        if [ "${OBS_MAJ_VER}" -le 27 ] || [ "${DISTRO_CMP_VER}" -le 2004 ] ; then
            QT_VER="5"
        fi

        if [ "${PLUGIN}" == "obs-gstreamer" ] || [ "${PLUGIN}" == "obs-vaapi" ]; then
            meson --buildtype=release --prefix="${BASE_DIR}/${INSTALL_DIR}/" --libdir="${BASE_DIR}/${INSTALL_DIR}/" "${PLUGIN_DIR}/${PLUGIN}" "${PLUGIN_DIR}/${PLUGIN}/build"
            ninja -C "${PLUGIN_DIR}/${PLUGIN}/build"
            ninja -C "${PLUGIN_DIR}/${PLUGIN}/build" install
            mv "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/${PLUGIN}.so" "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/${PLUGIN}.so"
            chmod 644 "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/${PLUGIN}.so"
        elif [ "${PLUGIN}" == "obs-teleport" ] && [ "${DISTRO_CMP_VER}" -ge 2204 ]; then
            # Requires Go 1.17, which is not available in Ubuntu 20.04
            export CGO_CPPFLAGS="${CPPFLAGS}"
            export CGO_CFLAGS="${CFLAGS} -I/usr/include/obs"
            export CGO_CXXFLAGS="${CXXFLAGS}"
            export CGO_LDFLAGS="${LDFLAGS} -ljpeg -lobs -lobs-frontend-api"
            export GOFLAGS="-buildmode=c-shared -trimpath -mod=readonly -modcacherw"
            cd "${PLUGIN_DIR}/${PLUGIN}"
            go build -ldflags "-linkmode external -X main.version=${BRANCH}" -v -o "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/${PLUGIN}.so" .
            mv "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/${PLUGIN}.h" "${BASE_DIR}/${INSTALL_DIR}/include/" || true
            cd "${CWD}"
        elif [ "${OBS_MAJ_VER}" -ge 28 ] || [ "${PLUGIN}" == "obs-soundboard" ]; then
            # Build process of OBS Studio 28
            cmake -S "${PLUGIN_DIR}/${PLUGIN}" -B "${PLUGIN_DIR}/${PLUGIN}/build" -G Ninja \
              -DCMAKE_BUILD_TYPE=Release \
              -DCMAKE_INSTALL_PREFIX="${BASE_DIR}/${INSTALL_DIR}" \
              -DQT_VERSION="${QT_VER}"  | tee "${BUILD_DIR}/cmake-${PLUGIN}.log"
            cmake --build "${PLUGIN_DIR}/${PLUGIN}/build"
            cmake --install "${PLUGIN_DIR}/${PLUGIN}/build" --prefix "${BASE_DIR}/${INSTALL_DIR}/"
        else
            # Build process for OBS Studio 27 and older
            cd "${PLUGIN_DIR}/${PLUGIN}"
            cmake -S "${PLUGIN_DIR}/${PLUGIN}" -B "${PLUGIN_DIR}/${PLUGIN}/build" \
              -DCMAKE_BUILD_TYPE=Release \
              -DCMAKE_INSTALL_PREFIX="${BASE_DIR}/${INSTALL_DIR}" \
              -DQT_VERSION="${QT_VER}" | tee "${BUILD_DIR}/cmake-${PLUGIN}.log"
            make -C "${PLUGIN_DIR}/${PLUGIN}/build"
            make -C "${PLUGIN_DIR}/${PLUGIN}/build" install
            cd "${CWD}"
        fi

        # Reorgansise some misplaced plugins
        case ${PLUGIN} in
            obs-pipewire-audio-capture|obs-vkcapture)
                # The plugins share a common patten
                NEW_PLUGIN=$(echo "${PLUGIN}" | cut -d'-' -f2-3)
                mv -v "${BASE_DIR}/${INSTALL_DIR}/lib/obs-plugins/linux-${NEW_PLUGIN}.so" "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/" || true
                rm -rf "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/linux-${NEW_PLUGIN}" || true
                mkdir -p "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/linux-${NEW_PLUGIN}"
                mv -v "${BASE_DIR}/${INSTALL_DIR}/share/obs/obs-plugins/linux-${NEW_PLUGIN}"/* "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/linux-${NEW_PLUGIN}/" || true
                ;;
            obs-text-pango)
                mv -v "${BASE_DIR}/${INSTALL_DIR}/bin/libtext-pango.so" "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/" || true;;
            waveform)
                mv -v "${BASE_DIR}/${INSTALL_DIR}"/waveform/bin/64bit/*waveform.so "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/" || true
                rm -rf "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/waveform"
                mkdir -p "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/waveform"
                mv -v "${BASE_DIR}/${INSTALL_DIR}/waveform/data/"* "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/waveform/" || true
                ;;
        esac

        mv -v "${BASE_DIR}/${INSTALL_DIR}/lib/obs-plugins/${PLUGIN}.so" "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/" || true
        if [ -d "${BASE_DIR}/${INSTALL_DIR}/share/obs/obs-plugins/${PLUGIN}" ]; then
            rm -rf "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/${PLUGIN}" || true
            mkdir -p "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/${PLUGIN}"
            mv -v "${BASE_DIR}/${INSTALL_DIR}/share/obs/obs-plugins/${PLUGIN}"/* "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/${PLUGIN}/" || true
        fi
    done < ./plugins-"${OBS_MAJ_VER}"-out-tree.txt
}

function stage_08_plugins_prebuilt() {
    echo -e "\nPlugins (pre-built)\n" >> "${BUILD_DIR}/obs-manifest.txt"
    local URL=""
    local ZIP=""

    #shellcheck disable=SC2162
    while read URL; do
        ZIP="${URL##*/}"
        if [ "${ZIP}" == "download" ]; then
            ZIP="rgb-levels.zip"
        fi
        echo " - ${URL}" >> "${BUILD_DIR}/obs-manifest.txt"
        wget --quiet --show-progress --progress=bar:force:noscroll "${URL}" -O "${TARBALL_DIR}/${ZIP}"
        unzip -o -qq "${TARBALL_DIR}/${ZIP}" -d "${PLUGIN_DIR}/$(basename "${ZIP}" .zip)"
    done < ./plugins-prebuilt.txt

    # Reorgansise plugins
    mv -v "${PLUGIN_DIR}/dvd-screensaver.v1.1.linux.x64/dvd-screensaver/bin/64bit/dvd-screensaver.so" "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/"
    rm -rf "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/dvd-screensaver"
    mkdir -p "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/dvd-screensaver"
    mv -v "${PLUGIN_DIR}/dvd-screensaver.v1.1.linux.x64/dvd-screensaver/data/"* "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/dvd-screensaver/"

    mv -v "${PLUGIN_DIR}/rgb-levels/usr/lib/obs-plugins/obs-rgb-levels-filter.so" "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/"
    mkdir -p "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/obs-rgb-levels-filter/"
    mv -v "${PLUGIN_DIR}/rgb-levels/usr/share/obs/obs-plugins/obs-rgb-levels-filter/"*.effect "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/obs-rgb-levels-filter/"
}

function stage_09_finalise() {
    # Remove CEF files that are lumped in with obs-plugins
    # Prevents OBS from enumating the .so files to determine if they can be loaded as a plugin
    rm -rf "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/locales" || true
    rm -rf "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/swiftshader" || true
    for CEF_FILE in chrome-sandbox *.pak icudtl.dat libcef.so libEGL.so \
        libGLESv2.so libvk_swiftshader.so libvulkan.so.1 snapshot_blob.bin \
        v8_context_snapshot.bin vk_swiftshader_icd.json; do
        #shellcheck disable=SC2086
        rm -f "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/"${CEF_FILE} || true
    done

    # The StreamFX log entries show it tries to load libaom.so from data/obs-plugins/StreamFX
    #09:20:39.424: [StreamFX] <encoder::aom::av1> Loading of '../../data/obs-plugins/StreamFX/libaom.so' failed.
    #09:20:39.424: [StreamFX] <encoder::aom::av1> Loading of 'libaom' failed.
    if [ -d "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/StreamFX" ]; then
        case "${DISTRO_CMP_VER}" in
            2204) AOM_VER="3.3.0";;
            2210) AOM_VER="3.4.0";;
        esac
        cp /usr/lib/x86_64-linux-gnu/libaom.so."${AOM_VER}" "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/StreamFX/libaom.so" || true
    fi

    # Remove empty directories
    find "${BASE_DIR}/${INSTALL_DIR}" -type d -empty -delete

    # Strip binaries and correct permissions
    for DIR in "${BASE_DIR}/${INSTALL_DIR}/cef" \
        "${BASE_DIR}/${INSTALL_DIR}/bin/64bit" \
        "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit" \
        "${BASE_DIR}/${INSTALL_DIR}/data/obs-scripting/64bit" \
        "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/StreamFX/" \
        "${BASE_DIR}/${INSTALL_DIR}/lib"; do
        #shellcheck disable=SC2162
        while read FILE; do
            TYPE=$(file "${FILE}" | cut -d':' -f2 | awk '{print $1}')
            if [ "${TYPE}" == "ELF" ]; then
                strip --strip-unneeded "${FILE}" || true
                if [[ "${FILE}" == *.so* ]]; then
                  chmod 644 "${FILE}"
                fi
            else
                chmod 644 "${FILE}"
            fi
        done < <(find "${DIR}" -type f)
    done

    # Create scripts
    # Create scripts
    local SCRIPTS="obs-dependencies obs-portable"
    if [ "${OBS_MAJ_VER}" -ge 28 ]; then
        SCRIPTS+=" obs-gamecapture"
    fi

    for SCRIPT in ${SCRIPTS}; do
        sed "s|TARGET_CODENAME|${DISTRO_CODENAME}|g" "./${SCRIPT}" > "${BASE_DIR}/${INSTALL_DIR}/${SCRIPT}"
        sed -i "s|TARGET_VERSION|${DISTRO_VERSION}|g" "${BASE_DIR}/${INSTALL_DIR}/${SCRIPT}"
        chmod 755 "${BASE_DIR}/${INSTALL_DIR}/${SCRIPT}"
    done

    # Populate the dependencies file
    echo "sudo apt-get install \\" >> "${BASE_DIR}/${INSTALL_DIR}/obs-dependencies"

    # Build a list of all the linked libraries
    rm -f obs-libs.txt 2>/dev/null || true
    for DIR in "${BASE_DIR}/${INSTALL_DIR}/cef" "${BASE_DIR}/${INSTALL_DIR}/bin/64bit" "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit" "${BASE_DIR}/${INSTALL_DIR}/data/obs-scripting/64bit"; do
        #shellcheck disable=SC2162
        while read FILE; do
            while read LIB; do
                echo "${LIB}" >> obs-libs.txt
            done < <(ldd "${FILE}" | awk '{print $1}')
        done < <(find "${DIR}" -type f)
    done

    # Map the library to the package it belongs to
    rm -f obs-pkgs.txt 2>/dev/null || true
    #shellcheck disable=SC2162
    while read LIB; do
        #shellcheck disable=SC2005
        echo "$(dpkg -S "${LIB}" | grep -Fv -e 'i386' -e '-dev' | cut -d ':' -f1 | sort -u)" >> obs-pkgs.txt
    done < <(sort -u obs-libs.txt)

    # Add the packages to the dependencies file
    #shellcheck disable=SC2162
    while read PKG; do
        echo -e "\t${PKG} \\" >> "${BASE_DIR}/${INSTALL_DIR}/obs-dependencies"
    done < <(sort -u obs-pkgs.txt)

    # Provide additional runtime requirements
    #shellcheck disable=SC1003
    if [ "${OBS_MAJ_VER}" -ge 28 ] && [ "${DISTRO_CMP_VER}" -ge 2204 ]; then
        echo -e '\tqt6-qpa-plugins \\\n\tqt6-wayland \\' >> "${BASE_DIR}/${INSTALL_DIR}/obs-dependencies"
    else
        echo -e '\tqtwayland5 \\' >> "${BASE_DIR}/${INSTALL_DIR}/obs-dependencies"
    fi
    echo -e '\tlibvlc5 \\\n\tvlc-plugin-base \\\n\tv4l2loopback-dkms \\\n\tv4l2loopback-utils' >> "${BASE_DIR}/${INSTALL_DIR}/obs-dependencies"
}

function stage_10_make_tarball() {
    cd "${BASE_DIR}"
    cp "${BUILD_DIR}/obs-manifest.txt" "${BASE_DIR}/${INSTALL_DIR}/manifest.txt"
    tar cjf "${INSTALL_DIR}.tar.bz2" --exclude bin --exclude cmake --exclude include --exclude lib/pkgconfig "${INSTALL_DIR}"
    sha256sum "${INSTALL_DIR}.tar.bz2" > "${BASE_DIR}/${INSTALL_DIR}.tar.bz2.sha256"
    sed -i -r "s/ .*\/(.+)/  \1/g" "${BASE_DIR}/${INSTALL_DIR}.tar.bz2.sha256"
    cp "${BUILD_DIR}/obs-manifest.txt" "${BASE_DIR}/${INSTALL_DIR}.txt"
}

echo -e "Portable OBS Studio ${OBS_VER} for Ubuntu ${DISTRO_VERSION} manifest (r${STAMP})\n\n" > "${BUILD_DIR}/obs-manifest.txt"
echo -e "  - https://github.com/wimpysworld/obs-studio-portable/\n"                           >> "${BUILD_DIR}/obs-manifest.txt"
stage_01_get_apt
stage_02_get_obs
stage_03_get_cef
stage_04_get_aja
stage_05_build_obs system
stage_06_plugins_in_tree
stage_05_build_obs portable
stage_07_plugins_out_tree
stage_08_plugins_prebuilt
stage_09_finalise
stage_10_make_tarball
