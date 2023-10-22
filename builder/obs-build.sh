#!/usr/bin/env bash
set -ex
LC_ALL=C

OBS_VER=""
if [ -n "${1}" ]; then
    OBS_VER="${1}"
    OBS_MAJ_VER="${OBS_VER%%.*}"
fi

BASE_DIR="${HOME}/obs-${OBS_MAJ_VER}"
BUILD_DIR="${BASE_DIR}/build"
BUILD_PORTABLE="${BASE_DIR}/build_portable"
BUILD_SYSTEM="${BASE_DIR}/build_system"
BUILD_TYPE="Release"
PLUGIN_LIST="auxiliary"
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
    29|30)
        AJA_VER="v16.2-bugfix5"
        CEF_VER="5060";;
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
PLUGIN_LIST="auxiliary"
if [ "${2}" == "essential" ]; then
    INSTALL_DIR="obs-portable-${OBS_VER}-r${STAMP}-ubuntu-${DISTRO_VERSION}-essential"
    PLUGIN_LIST="essential"
fi

#shellcheck disable=SC1091
if [ -e ./obs-options.sh ]; then
    source ./obs-options.sh
fi

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

    mkdir -p "${DIR}"
    # Only download and extract if the directory is empty
    if [ -z "$(ls -A "${DIR}")" ]; then
        download_file "${URL}"
        bsdtar --strip-components=1 -xf "${TARBALL_DIR}/${FILE}" -C "${DIR}"
    fi
}

function clone_source() {
    local REPO="${1}"
    local BRANCH="${2}"
    local BRANCH_LEN=""
    local DIR="${3}"

    if [ ! -d "${DIR}/.git" ]; then
        BRANCH_LEN=$(echo -n "${BRANCH}" | wc -m);
        if [ "${BRANCH_LEN}" -eq 40 ]; then
            git clone "${REPO}" --filter=tree:0 --recurse-submodules --shallow-submodules "${DIR}"
            pushd "${DIR}"
            git checkout "${BRANCH}"
            popd
        else
            git clone "${REPO}" --filter=tree:0 --recurse-submodules --shallow-submodules --branch "${BRANCH}" "${DIR}"
        fi
    fi
}

function stage_01_get_apt() {
    local PKG_LIST="binutils bzip2 clang-format clang-tidy cmake curl file git libarchive-tools libc6-dev make meson ninja-build patch pkg-config tree unzip wget"

    if [ "${DISTRO_CMP_VER}" -eq 2004 ]; then
        # Newer cmake, ninja-build, meson for Ubuntu 20.04
        apt-get -y update
        apt-get -y install --no-install-recoomends software-properties-common
        add-apt-repository -y --no-update ppa:flexiondotorg/build-tools
        PKG_LIST+=" gcc-10 g++-10 golang-1.16-go"
    elif [ "${DISTRO_CMP_VER}" -ge 2310 ]; then
        PKG_LIST+=" gcc-12 g++-12 golang-go"
    else
        PKG_LIST+=" gcc g++ golang-go"
    fi

    if [ "${DISTRO_CMP_VER}" -ge 2204 ]; then
        PKG_LIST+=" qt6-base-dev qt6-base-private-dev qt6-wayland libqt6svg6-dev"
    elif [ "${DISTRO_CMP_VER}" -ge 2304 ]; then
        PKG_LIST+=" qt6-base-dev qt6-base-private-dev qt6-svg-dev qt6-wayland"
    else
        PKG_LIST+=" qtbase5-dev qtbase5-private-dev qtwayland5 libqt5svg5-dev libqt5x11extras5-dev"
    fi

    # Core OBS
    # libvulkan-dev and libxdamage-dev are not documented as dependencies in
    # the upstream OBS build instructions
    PKG_LIST+=" libavcodec-dev libavdevice-dev libavfilter-dev libavformat-dev \
libavutil-dev libswresample-dev libswscale-dev libcmocka-dev libcurl4-openssl-dev \
libgl1-mesa-dev libgles2-mesa-dev libglvnd-dev libjansson-dev libluajit-5.1-dev \
libmbedtls-dev libpci-dev libvulkan-dev libwayland-dev libx11-dev libx11-xcb-dev \
libx264-dev libxcb-composite0-dev libxcb-randr0-dev libxcb-shm0-dev libxcb-xfixes0-dev \
libxcb-xinerama0-dev libxcb1-dev libxcomposite-dev libxdamage-dev libxinerama-dev \
libxss-dev python3-dev swig"

    # SRT & RIST Protocol Support
    if [ "${DISTRO_CMP_VER}" -ge 2210 ]; then
        PKG_LIST+=" librist-dev libsrt-openssl-dev"
    fi

    # OBS Core Plugins
    PKG_LIST+=" libasound2-dev libdrm-dev libfdk-aac-dev libfontconfig-dev \
libfreetype6-dev libjack-jackd2-dev libpulse-dev libsndio-dev libspeexdsp-dev \
libudev-dev libv4l-dev libva-dev libvlc-dev"

    # CEF Browser runtime requirements
    PKG_LIST+=" libatk-bridge2.0-0 libcups2 libnspr4 libnss3 libxtst6"

    # OBS Studio 29.1.0 new deps, mostly related to OBS Websocket 5.2 support
    # - https://github.com/obsproject/obs-studio/pull/8194
    if [ "${OBS_MAJ_VER}" -ge 29 ]; then
        PKG_LIST+=" libasio-dev libwebsocketpp-dev nlohmann-json3-dev"
    fi

    # OBS Studio 30.0.0 added qrcode and oneVPL
    if [ "${OBS_MAJ_VER}" -ge 30 ]; then
        # https://github.com/obsproject/obs-studio/pull/8943
        PKG_LIST+=" libqrcodegencpp-dev"
        if [ "${DISTRO_CMP_VER}" -ge 2204 ]; then
            # Intel® oneAPI Video Processing Library (oneVPL)
            PKG_LIST+=" libvpl-dev libvpl2"
        fi
    fi

    # Pipewire
    if [ "${DISTRO_CMP_VER}" -ge 2204 ]; then
        PKG_LIST+=" libpipewire-0.3-dev"
    else
        PKG_LIST+=" libpipewire-0.2-dev"
    fi

    # Screne Switcher
    PKG_LIST+=" libopencv-dev libxss-dev libxtst-dev"
    case "${DISTRO_CMP_VER}" in
        23*) PKG_LIST+=" libproc2-dev";;
        *)   PKG_LIST+=" libprocps-dev";;
    esac

    # Waveform
    PKG_LIST+=" libfftw3-dev"
    # Facetracker
    PKG_LIST+=" libatlas-base-dev libblas-dev libblas64-dev libgsl-dev liblapack-dev libopenblas-dev"
    # Pthread Text
    PKG_LIST+=" libcairo2-dev libpango1.0-dev libpng-dev"
    # Gstreamer
    PKG_LIST+=" libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev libgstreamer-plugins-bad1.0-dev"
    # Tuna
    PKG_LIST+=" libdbus-1-dev libmpdclient-dev libtag1-dev"

    if [ "${DISTRO_CMP_VER}" -ge 2204 ]; then
        # VKCapture
        PKG_LIST+=" glslang-dev glslang-tools"
        #AV1
        PKG_LIST+=" libaom-dev"
        # URL Source
        PKG_LIST+=" libidn2-dev libpsl-dev libpugixml-dev libssl-dev"
    fi

    apt-get -y update
    apt-get -y upgrade
    #shellcheck disable=SC2086
    apt-get -y install --no-install-recommends ${PKG_LIST}

    if [ "${DISTRO_CMP_VER}" -eq 2004 ]; then
        update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 800 --slave /usr/bin/g++ g++ /usr/bin/g++-10
        update-alternatives --install /usr/bin/go go /usr/lib/go-1.16/bin/go 10
    elif [ "${DISTRO_CMP_VER}" -ge 2310 ]; then
        update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 800 --slave /usr/bin/g++ g++ /usr/bin/g++-12
    fi
}

function stage_02_get_obs() {
    clone_source "https://github.com/obsproject/obs-studio.git" "${OBS_VER}" "${SOURCE_DIR}"
}

function stage_03_get_cef() {
    download_tarball "https://cdn-fastly.obsproject.com/downloads/cef_binary_${CEF_VER}_linux_x86_64_v3.tar.xz" "${BUILD_DIR}/cef"
    mkdir -p "${BASE_DIR}/${INSTALL_DIR}/cef"
    cp -a "${BUILD_DIR}/cef/Release/"* "${BASE_DIR}/${INSTALL_DIR}/cef/"
    cp -a "${BUILD_DIR}/cef/Resources/"* "${BASE_DIR}/${INSTALL_DIR}/cef/"
    cp "${BUILD_DIR}/cef/"{LICENSE.txt,README.txt} "${BASE_DIR}/${INSTALL_DIR}/cef/"
    chmod 755 "${BASE_DIR}/${INSTALL_DIR}/cef/locales"
}

function stage_04_build_aja() {
    download_tarball "https://github.com/aja-video/ntv2/archive/refs/tags/${AJA_VER}.tar.gz" "${SOURCE_DIR}/ntv2"
    cmake -S "${SOURCE_DIR}/ntv2/" -B "${SOURCE_DIR}/ntv2/build/" -G Ninja \
        -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
        -DAJA_BUILD_OPENSOURCE=ON \
        -DAJA_BUILD_APPS=OFF \
        -DAJA_INSTALL_HEADERS=ON | tee "${BUILD_DIR}/cmake-aja.log"
    cmake --build "${SOURCE_DIR}/ntv2/build/"
    cmake --install "${SOURCE_DIR}/ntv2/build/" --prefix "${BUILD_DIR}/aja"
}

function stage_05_build_obs() {
    local OPTIONS=""
    local TARGET="system"
    if [ "${1}" == "portable" ]; then
        TARGET="portable"
    fi

    case "${TARGET}" in
      portable)
        BUILD_TO="${BUILD_PORTABLE}"
        INSTALL_TO="${BASE_DIR}/${INSTALL_DIR}"
        OPTIONS="-DLINUX_PORTABLE=ON";;
      system)
        BUILD_TO="${BUILD_SYSTEM}"
        INSTALL_TO="/usr"
        OPTIONS="-DLINUX_PORTABLE=OFF";;
    esac

    if [ "${DISTRO_CMP_VER}" -ge 2204 ]; then
        OPTIONS+=" -DENABLE_PIPEWIRE=ON"
    else
        OPTIONS+=" -DENABLE_PIPEWIRE=OFF"
    fi

    OPTIONS+=" -DENABLE_RTMPS=ON"
    if [ "${DISTRO_CMP_VER}" -ge 2210 ]; then
        OPTIONS+=" -DENABLE_NEW_MPEGTS_OUTPUT=ON"
    else
        OPTIONS+=" -DENABLE_NEW_MPEGTS_OUTPUT=OFF"
    fi
    OPTIONS+=" -DENABLE_BROWSER=ON"
    OPTIONS+=" -DENABLE_VST=ON"

    # libdatachannel is not available in any Ubuntu release
    if [ "${OBS_MAJ_VER}" -ge 30 ]; then
        OPTIONS+=" -DENABLE_WEBRTC=OFF"
    fi

    local TWITCH_OPTIONS=""
    if [ "${TWITCH_CLIENTID}" ] && [ "${TWITCH_HASH}" ]; then
        TWITCH_OPTIONS="-DTWITCH_CLIENTID='${TWITCH_CLIENTID}' -DTWITCH_HASH='${TWITCH_HASH}'"
    fi

    local RESTREAM_OPTIONS=""
    if [ "${RESTREAM_CLIENTID}" ] && [ "${RESTREAM_HASH}" ]; then
        RESTREAM_OPTIONS="-DRESTREAM_CLIENTID='${RESTREAM_CLIENTID}' -DRESTREAM_HASH='${RESTREAM_HASH}'"
    fi

    local YOUTUBE_OPTIONS=""
    if [ "${YOUTUBE_CLIENTID}" ] && [ "${YOUTUBE_CLIENTID_HASH}" ] && [ "${YOUTUBE_SECRET}" ] && [ "{YOUTUBE_SECRET_HASH}" ]; then
        YOUTUBE_OPTIONS="-DYOUTUBE_CLIENTID='${YOUTUBE_CLIENTID}' -DYOUTUBE_CLIENTID_HASH='${YOUTUBE_CLIENTID_HASH}' -DYOUTUBE_SECRET='${YOUTUBE_SECRET}' -DYOUTUBE_SECRET_HASH='${YOUTUBE_SECRET_HASH}'"
    fi

    #shellcheck disable=SC2086,SC2090
    cmake -S "${SOURCE_DIR}/" -B "${BUILD_TO}/" -G Ninja \
      -DCALM_DEPRECATION=ON \
      -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
      -DCMAKE_INSTALL_PREFIX="${INSTALL_TO}" \
      -DENABLE_AJA=ON \
      -DAJA_LIBRARIES_INCLUDE_DIR="${BUILD_DIR}"/aja/include/ \
      -DAJA_NTV2_LIB="${BUILD_DIR}"/aja/lib/libajantv2.a \
      -DCEF_ROOT_DIR="${BUILD_DIR}/cef" \
      -DENABLE_ALSA=OFF \
      -DENABLE_JACK=ON \
      -DENABLE_LIBFDK=ON \
      -DENABLE_PULSEAUDIO=ON \
      -DENABLE_VLC=ON \
      -DENABLE_WAYLAND=ON \
      ${RESTREAM_OPTIONS} \
      ${TWITCH_OPTIONS} \
      ${YOUTUBE_OPTIONS} \
      -Wno-dev --log-level=ERROR ${OPTIONS} | tee "${BUILD_DIR}/cmake-obs-${TARGET}.log"
    cmake --build "${BUILD_TO}/"
    cmake --install "${BUILD_TO}/" --prefix "${INSTALL_TO}"
}

function stage_06_plugins() {
    local BRANCH=""
    local CHAR1=""
    local ERROR=""
    local EXTRA=""
    local PLUGIN=""
    local PRIORITY=""
    local URL=""

    #shellcheck disable=SC2162
    while read REPO; do
        # ignore commented lines
        CHAR1=$(echo "${REPO}" | sed 's/ *$//g' | cut -c1)
        if [ "${CHAR1}" == "#" ]; then
            continue
        fi

        # ignore auxillary plugins if instructed to build only then essential plugins
        PRIORITY="$(echo "${REPO}" | cut -d',' -f2 | sed 's/ //g')"
        if [ "${PLUGIN_LIST}" == "essential" ] && [ "${PRIORITY}" == "auxiliary" ]; then
            continue
        fi

        URL="$(echo "${REPO}" | cut -d',' -f1 | cut -d'/' -f1-5)"
        AUTHOR="$(echo "${REPO}" | cut -d',' -f1  | cut -d'/' -f4)"
        PLUGIN="$(echo "${REPO}" | cut -d',' -f1  | cut -d'/' -f5)"
        BRANCH="$(echo "${REPO}" | cut -d',' -f1  | cut -d'/' -f6)"

        # obs-face-tracker requires that QT_VERSION is set
        local QT_VER="6"

        # Insufficient Golang or PipeWire or Qt support in Ubuntu 20.04 to build these plugins
        if [ "${DISTRO_CMP_VER}" -le 2004 ]; then
            QT_VER="5"
            if [ "${PLUGIN}" == "obs-backgroundremoval" ] || \
               [ "${PLUGIN}" == "obs-localvocal" ] || \
               [ "${PLUGIN}" == "obs-pipewire-audio-capture" ] || \
               [ "${PLUGIN}" == "obs-rtspserver" ] || \
               [ "${PLUGIN}" == "obs-teleport" ] || \
               [ "${PLUGIN}" == "obs-urlsource" ] || \
               [ "${PLUGIN}" == "obs-vertical-canvas" ] || \
               [ "${PLUGIN}" == "obs-vkcapture" ] || \
               [ "${PLUGIN}" == "pixel-art" ] || \
               [ "${PLUGIN}" == "tuna" ]; then
                 echo "Skipping ${PLUGIN} (not supported on ${DISTRO} ${DISTRO_VER})"
                 continue
            elif [ "${PLUGIN}" == "SceneSwitcher" ] && [ "${OBS_MAJ_VER}" -ge 29 ]; then
                # SceneSwitcher 1.20 FTBFS on Ubuntu 20.04
                BRANCH="1.19.2"
            fi
        fi

        clone_source "${URL}.git" "${BRANCH}" "${PLUGIN_DIR}/${PLUGIN}"

        ERROR=""
        EXTRA=""
        if [ "${PLUGIN}" == "obs-StreamFX" ]; then
            # Monkey patch the needlessly exagerated and inconsistent cmake version requirements
            if [ "${OBS_MAJ_VER}" -ge 29 ]; then
                sed -i 's/VERSION 3\.26/VERSION 3\.18/' "${PLUGIN_DIR}/${PLUGIN}/CMakeLists.txt" || true
                sed -i 's/VERSION 3\.20/VERSION 3\.18/' "${PLUGIN_DIR}/${PLUGIN}/cmake/clang/Clang.cmake" || true
            fi
            # Only enable stable features supported on Linux; see README.md for more details
            cmake -S "${PLUGIN_DIR}/${PLUGIN}" -B "${PLUGIN_DIR}/${PLUGIN}/build" \
              -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
              -DENABLE_ENCODER_AOM_AV1=OFF \
              -DENABLE_ENCODER_FFMPEG=ON \
              -DENABLE_ENCODER_FFMPEG_AMF=OFF \
              -DENABLE_ENCODER_FFMPEG_NVENC=ON \
              -DENABLE_ENCODER_FFMPEG_PRORES=ON \
              -DENABLE_ENCODER_FFMPEG_DNXHR=ON \
              -DENABLE_ENCODER_FFMPEG_CFHD=ON \
              -DENABLE_FILTER_AUTOFRAMING=OFF \
              -DENABLE_FILTER_AUTOFRAMING_NVIDIA=OFF \
              -DENABLE_FILTER_BLUR=OFF \
              -DENABLE_FILTER_COLOR_GRADE=ON \
              -DENABLE_FILTER_DENOISING=OFF \
              -DENABLE_FILTER_DENOISING_NVIDIA=OFF \
              -DENABLE_FILTER_DYNAMIC_MASK=ON \
              -DENABLE_FILTER_SDF_EFFECTS=OFF \
              -DENABLE_FILTER_SHADER=OFF \
              -DENABLE_FILTER_TRANSFORM=OFF \
              -DENABLE_FILTER_UPSCALING=OFF \
              -DENABLE_FILTER_UPSCALING_NVIDIA=OFF \
              -DENABLE_FILTER_VIRTUAL_GREENSCREEN=OFF \
              -DENABLE_FILTER_VIRTUAL_GREENSCREEN_NVIDIA=OFF \
              -DENABLE_SOURCE_MIRROR=OFF \
              -DENABLE_SOURCE_SHADER=OFF \
              -DENABLE_TRANSITION_SHADER=OFF \
              -DENABLE_CLANG=OFF \
              -DENABLE_LTO=ON \
              -DENABLE_FRONTEND=OFF \
              -DENABLE_UPDATER=OFF \
              -DCMAKE_INSTALL_PREFIX="${BASE_DIR}/${INSTALL_DIR}" | tee "${BUILD_DIR}/cmake-${PLUGIN}.log"
            cmake --build "${PLUGIN_DIR}/${PLUGIN}/build"
            cmake --install "${PLUGIN_DIR}/${PLUGIN}/build" --prefix "${BASE_DIR}/${INSTALL_DIR}/"
            # Reorganise the StreamFX plugin files to match the OBS plugin directory structure
            mv "${BASE_DIR}/${INSTALL_DIR}/plugins/StreamFX/bin/64bit/"* "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/" || true
            mkdir -p "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/StreamFX"
            cp -a "${BASE_DIR}/${INSTALL_DIR}/plugins/StreamFX/data/"* "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/StreamFX/" || true
            rm -rf "${BASE_DIR}/${INSTALL_DIR}/plugins"
        elif [ "${PLUGIN}" == "obs-teleport" ]; then
            # Requires Go 1.17, which is not available in Ubuntu 20.04
            export CGO_CPPFLAGS="${CPPFLAGS}"
            export CGO_CFLAGS="${CFLAGS} -I/usr/include/obs"
            export CGO_CXXFLAGS="${CXXFLAGS}"
            export CGO_LDFLAGS="${LDFLAGS} -ljpeg -lobs -lobs-frontend-api"
            export GOFLAGS="-buildmode=c-shared -trimpath -mod=readonly -modcacherw"
            pushd "${PLUGIN_DIR}/${PLUGIN}"
            go build -ldflags "-linkmode external -X main.version=${BRANCH}" -v -o "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/${PLUGIN}.so" .
            mv "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/${PLUGIN}.h" "${BASE_DIR}/${INSTALL_DIR}/include/" || true
            popd
        elif [ "${PLUGIN}" == "obs-gstreamer" ] || [ "${PLUGIN}" == "obs-vaapi" ]; then
            if [ "${DISTRO_CMP_VER}" -le 2204 ]; then
                meson --buildtype=${BUILD_TYPE,,} --prefix="${BASE_DIR}/${INSTALL_DIR}" --libdir="${BASE_DIR}/${INSTALL_DIR}" "${PLUGIN_DIR}/${PLUGIN}" "${PLUGIN_DIR}/${PLUGIN}/build"
            else
                meson setup --buildtype=${BUILD_TYPE,,} --prefix="${BASE_DIR}/${INSTALL_DIR}" --libdir="${BASE_DIR}/${INSTALL_DIR}" "${PLUGIN_DIR}/${PLUGIN}" "${PLUGIN_DIR}/${PLUGIN}/build"
            fi
            ninja -C "${PLUGIN_DIR}/${PLUGIN}/build"
            ninja -C "${PLUGIN_DIR}/${PLUGIN}/build" install
            if [ -e "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/${PLUGIN}.so" ]; then
                mv "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/${PLUGIN}.so" "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/" || true
            elif [ -e "${BASE_DIR}/${INSTALL_DIR}/${PLUGIN}.so" ]; then
                mv "${BASE_DIR}/${INSTALL_DIR}/${PLUGIN}.so" "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/" || true
            fi
        else
            if [ "${AUTHOR}" == "ujifgc" ] || [ "${AUTHOR}" == "exeldro" ] || [ "${AUTHOR}" == "Aitum" ] || [ "${AUTHOR}" == "andilippi" ] || [ "${AUTHOR}" == "FiniteSingularity" ] || [ "${PLUGIN}" == "obs-scale-to-sound" ]; then
                EXTRA="-DBUILD_OUT_OF_TREE=ON"
            fi
            case "${PLUGIN}" in
                obs-backgroundremoval)
                    EXTRA="--preset linux-x86_64";;
                obs-face-tracker)
                    # Add face detection models for face tracker plugin
                    mkdir -p "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/obs-face-tracker"
                    wget --quiet --show-progress --progress=bar:force:noscroll "https://github.com/norihiro/obs-face-tracker/releases/download/0.7.0-hogdata/frontal_face_detector.dat.bz2" -O "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/obs-face-tracker/frontal_face_detector.dat.bz2"
                    wget --quiet --show-progress --progress=bar:force:noscroll "https://github.com/davisking/dlib-models/raw/master/shape_predictor_5_face_landmarks.dat.bz2" -O "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/obs-face-tracker/shape_predictor_5_face_landmarks.dat.bz2"
                    bunzip2 -f "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/obs-face-tracker/frontal_face_detector.dat.bz2"
                    bunzip2 -f "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/obs-face-tracker/shape_predictor_5_face_landmarks.dat.bz2";;
                obs-localvocal)
                    EXTRA="--preset linux-x86_64 -DUSE_SYSTEM_CURL=ON";;
                obs-ndi)
                    download_file "https://github.com/obs-ndi/obs-ndi/releases/download/4.11.1/libndi5_5.5.3-1_amd64.deb"
                    download_file "https://github.com/obs-ndi/obs-ndi/releases/download/4.11.1/libndi5-dev_5.5.3-1_amd64.deb"
                    apt-get -y install --no-install-recommends "${TARBALL_DIR}"/*.deb
                    cp -v /usr/lib/libndi.so "${BASE_DIR}/${INSTALL_DIR}/lib/";;
                obs-replay-source)
                    # Make uthash and libcaption headers discoverable by obs-replay-source
                    cp "${SOURCE_DIR}/deps/uthash/uthash/uthash.h" /usr/include/obs/util/
                    mkdir -p /usr/include/caption/
                    cp "${SOURCE_DIR}/deps/libcaption/caption/"*.h /usr/include/caption/;;
                obs-source-dock)
                    ERROR="-Wno-error=switch";;
                obs-stroke-glow-shadow)
                    ERROR="-Wno-error=stringop-overflow";;
                obs-urlsource)
                    EXTRA="--preset linux-x86_64 -DUSE_SYSTEM_CURL=ON -DUSE_SYSTEM_PUGIXML=ON"
                    ERROR="-Wno-error=conversion -Wno-error=shadow";;
                SceneSwitcher)
                    # Adjust cmake VERSION SceneSwitch on Ubuntu 20.04
                    if [ "${DISTRO_CMP_VER}" -eq 2004 ]; then
                        sed -i 's/VERSION 3\.21/VERSION 3\.18/' "${SOURCE_DIR}/UI/frontend-plugins/SceneSwitcher/CMakeLists.txt" || true
                    fi;;
                tuna)
                    # Use system libmpdclient and taglib
                    # https://aur.archlinux.org/packages/obs-tuna
                    wget -q "https://aur.archlinux.org/cgit/aur.git/plain/FindLibMPDClient.cmake?h=obs-tuna" -O "${PLUGIN_DIR}/${PLUGIN}/cmake/external/FindLibMPDClient.cmake"
                    wget -q "https://aur.archlinux.org/cgit/aur.git/plain/FindTaglib.cmake?h=obs-tuna" -O "${PLUGIN_DIR}/${PLUGIN}/cmake/external/FindTaglib.cmake"
                    wget -q "https://aur.archlinux.org/cgit/aur.git/plain/deps_CMakeLists.txt?h=obs-tuna" -O "${PLUGIN_DIR}/${PLUGIN}/deps/CMakeLists.txt"
                    sed -i '13 a find_package(LibMPDClient REQUIRED)\nfind_package(Taglib REQUIRED)' "${PLUGIN_DIR}/${PLUGIN}/CMakeLists.txt"
                    EXTRA="-DCREDS=MISSING -DLASTFM_CREDS=MISSING";;
            esac
            # Build process for OBS Studio 28 and newer
            # -Wno-error=deprecated-declarations is for some plugins that use deprecated OBS APIs such as obs_frontend_add_dock()
            cmake -S "${PLUGIN_DIR}/${PLUGIN}" -B "${PLUGIN_DIR}/${PLUGIN}/build" -G Ninja \
              -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
              -DCMAKE_CXX_FLAGS="-Wno-error=deprecated-declarations ${ERROR}" \
              -DCMAKE_C_FLAGS="-Wno-error=deprecated-declarations ${ERROR}" \
              -DCMAKE_INSTALL_PREFIX="${BASE_DIR}/${INSTALL_DIR}" \
              -DQT_VERSION="${QT_VER}" ${EXTRA} \
              -Wno-dev | tee "${BUILD_DIR}/cmake-${PLUGIN}.log"
            cmake --build "${PLUGIN_DIR}/${PLUGIN}/build"
            cmake --install "${PLUGIN_DIR}/${PLUGIN}/build" --prefix "${BASE_DIR}/${INSTALL_DIR}/"
        fi
    done < ./plugins-"${OBS_MAJ_VER}".csv
    
    # Re-organise misplaced plugins
    mv -v "${BASE_DIR}/${INSTALL_DIR}/lib/obs-plugins/"*.so "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/"
    cp -av "${BASE_DIR}/${INSTALL_DIR}/share/obs/obs-plugins/"* "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/"
    rm -rf "${BASE_DIR}/${INSTALL_DIR}/share/obs/obs-plugins"
    # Re-organsise waveform plugin
    mv -v "${BASE_DIR}/${INSTALL_DIR}/waveform/bin/64bit/"*.so "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit/"
    mkdir -p "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/waveform"
    mv -v "${BASE_DIR}/${INSTALL_DIR}/waveform/data/"* "${BASE_DIR}/${INSTALL_DIR}/data/obs-plugins/waveform/" || true
    rm -rf "${BASE_DIR}/${INSTALL_DIR}/waveform/"
    # Re-organsise libonnxruntime
    mv -v "${BASE_DIR}/${INSTALL_DIR}/lib/obs-plugins/obs-backgroundremoval/libonnxruntime"* "${BASE_DIR}/${INSTALL_DIR}/lib/" || true
}

function stage_07_themes() {
    local FILE=""
    local URL=""

    URL="https://obsproject.com/forum/resources/yami-resized.1611/version/4885/download"
    FILE="Yami-Resized-1.1.1.zip"
    wget --quiet --show-progress --progress=bar:force:noscroll "${URL}" -O "${TARBALL_DIR}/${FILE}"
    unzip -o -qq "${TARBALL_DIR}/${FILE}" -d "${BASE_DIR}/${INSTALL_DIR}/data/obs-studio/themes"
}

function stage_08_finalise() {
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

    # Remove empty directories
    find "${BASE_DIR}/${INSTALL_DIR}" -type d -empty -delete

    # Strip binaries and correct permissions
    if [ "${BUILD_TYPE}" == "Release" ]; then
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
    fi
}

function stage_09_make_scripts() {
    # Create scripts
    local SCRIPTS="obs-container-dependencies obs-dependencies obs-portable obs-gamecapture"

    # Template scripts with correct Ubuntu versions
    for SCRIPT in ${SCRIPTS}; do
        sed "s|TARGET_CODENAME|${DISTRO_CODENAME}|g" "./${SCRIPT}" > "${BASE_DIR}/${INSTALL_DIR}/${SCRIPT}"
        sed -i "s|TARGET_VERSION|${DISTRO_VERSION}|g" "${BASE_DIR}/${INSTALL_DIR}/${SCRIPT}"
        chmod 755 "${BASE_DIR}/${INSTALL_DIR}/${SCRIPT}"
    done

    # Populate the dependencies file
    echo "sudo apt-get --no-install-recommends install \\" >> "${BASE_DIR}/${INSTALL_DIR}/obs-dependencies"
    echo "DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \\" >> "${BASE_DIR}/${INSTALL_DIR}/obs-container-dependencies"

    # Build a list of all the linked libraries
    rm -f obs-libs.txt 2>/dev/null || true
    for DIR in "${BASE_DIR}/${INSTALL_DIR}/cef" "${BASE_DIR}/${INSTALL_DIR}/bin/64bit" "${BASE_DIR}/${INSTALL_DIR}/obs-plugins/64bit" "${BASE_DIR}/${INSTALL_DIR}/data/obs-scripting/64bit"; do
        #shellcheck disable=SC2162
        while read FILE; do
            while read LIB; do
                echo "${LIB}" >> obs-libs.txt
            done < <(ldd "${FILE}" | grep "=>" | awk '{print $1}')
        done < <(find "${DIR}" -type f)
    done

    # Map the library to the package it belongs to
    rm -f obs-pkgs.txt 2>/dev/null || true
    #shellcheck disable=SC2162
    while read LIB; do
        #shellcheck disable=SC2005
        echo "$(dpkg -S "${LIB}" 2>/dev/null | cut -d ':' -f1 | grep -Fv -e '-dev' -e 'i386' -e 'libc' -e 'pulseaudio' | sort -u)" >> obs-pkgs.txt
    done < <(sort -u obs-libs.txt)

    # Add the packages to the dependencies file
    #shellcheck disable=SC2162
    while read PKG; do
        if [ -n "${PKG}" ]; then
            echo -e "\t${PKG} \\" | tee -a "${BASE_DIR}/${INSTALL_DIR}/obs-dependencies" "${BASE_DIR}/${INSTALL_DIR}/obs-container-dependencies"
        fi
    done < <(sort -u obs-pkgs.txt)

    # Provide additional runtime requirements
    #shellcheck disable=SC1003
    if [ "${DISTRO_CMP_VER}" -ge 2204 ]; then
        echo -e '\tqt6-image-formats-plugins \\\n\tqt6-qpa-plugins \\\n\tqt6-wayland \\' | tee -a "${BASE_DIR}/${INSTALL_DIR}/obs-dependencies" "${BASE_DIR}/${INSTALL_DIR}/obs-container-dependencies"
    else
        echo -e '\tqtwayland5 \\' | tee -a "${BASE_DIR}/${INSTALL_DIR}/obs-dependencies" "${BASE_DIR}/${INSTALL_DIR}/obs-container-dependencies"
    fi
    echo -e '\tgstreamer1.0-plugins-good \\\n\tgstreamer1.0-plugins-bad \\\n\tgstreamer1.0-plugins-ugly \\\n\tgstreamer1.0-x \\' | tee -a "${BASE_DIR}/${INSTALL_DIR}/obs-dependencies" "${BASE_DIR}/${INSTALL_DIR}/obs-container-dependencies"
    echo -e '\tlibgles2-mesa \\\n\tlibvlc5 \\\n\tvlc-plugin-base \\\n\tstterm' >> "${BASE_DIR}/${INSTALL_DIR}/obs-dependencies"
    echo -e '\tlibgles2-mesa \\\n\tlibvlc5 \\\n\tvlc-plugin-base \\\n\tstterm \\' >> "${BASE_DIR}/${INSTALL_DIR}/obs-container-dependencies"
    echo -e '\tmesa-vdpau-drivers \\\n\tmesa-va-drivers && \\' >> "${BASE_DIR}/${INSTALL_DIR}/obs-container-dependencies"
    echo -e 'apt-get -y clean && rm -rd /var/lib/apt/lists/*' >> "${BASE_DIR}/${INSTALL_DIR}/obs-container-dependencies"
}

function stage_10_make_tarball() {
    cd "${BASE_DIR}"
    tar cjf "${INSTALL_DIR}.tar.bz2" --exclude cmake --exclude include --exclude lib/pkgconfig "${INSTALL_DIR}"
    sha256sum "${INSTALL_DIR}.tar.bz2" > "${BASE_DIR}/${INSTALL_DIR}.tar.bz2.sha256"
    sed -i -r "s/ .*\/(.+)/  \1/g" "${BASE_DIR}/${INSTALL_DIR}.tar.bz2.sha256"
}

stage_01_get_apt
stage_02_get_obs
stage_03_get_cef
stage_04_build_aja
stage_05_build_obs system
stage_05_build_obs portable
stage_06_plugins
stage_07_themes
stage_08_finalise
stage_09_make_scripts
stage_10_make_tarball
