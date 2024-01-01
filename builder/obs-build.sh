#!/usr/bin/env bash
set -ex
LC_ALL=C

BUILD_TYPE="Release"
OBS_VER=""
STAMP=$(date +%y%j)
if [ -n "${1}" ]; then
    OBS_VER="${1}"
    OBS_MAJ_VER="${OBS_VER%%.*}"
fi

case ${OBS_MAJ_VER} in
    30)
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
    if [ "${DISTRO_CMP_VER}" -le 2004 ]; then
        echo "Unsupported Ubuntu version: ${DISTRO_VERSION}"
        exit 1
    fi
else
    echo "Unsupported Linux distribution."
    exit 1
fi

DIR_BASE="${HOME}/obs-${OBS_MAJ_VER}"
DIR_BUILD="${DIR_BASE}/build"
DIR_DOWNLOAD="${DIR_BASE}/downloads"
DIR_PLUGIN="${DIR_BASE}/plugins"
DIR_PORTABLE="${DIR_BASE}/build_portable"
DIR_SOURCE="${DIR_BASE}/source"
DIR_SYSTEM="${DIR_BASE}/build_system"
for DIRECTORY in "${DIR_BUILD}" "${DIR_PORTABLE}" "${DIR_SYSTEM}" "${DIR_DOWNLOAD}" "${DIR_PLUGIN}" "${DIR_SOURCE}"; do
    mkdir -p "${DIRECTORY}"
done

DIR_INSTALL="${DIR_BASE}/obs-portable-${OBS_VER}-r${STAMP}-ubuntu-${DISTRO_VERSION}"
PLUGIN_LIST="auxiliary"
if [ "${2}" == "essential" ]; then
    DIR_INSTALL+="-essential"
    PLUGIN_LIST="essential"
fi

#shellcheck disable=SC1091
if [ -e ./obs-options.sh ]; then
    source ./obs-options.sh
fi

function download_file() {
    local URL="${1}"
    local FILE="${URL##*/}"
    local FILE_EXTENSION="${FILE##*.}"
    local FILE_OUTPUT="${DIR_DOWNLOAD}/${FILE}"
    local FILE_TEST=""

    # Use the second argument as the output file if provided
    if [ -n "${2}" ]; then
        FILE_OUTPUT="${2}"
        mkdir -p "$(dirname "${FILE_OUTPUT}")"
    fi

    until wget --continue --quiet --show-progress --progress=bar:force:noscroll "${URL}" -O "${FILE_OUTPUT}"; do
        echo "Failed to download ${URL}. Deleting ${FILE}..."
        rm "${FILE_OUTPUT}" 2>/dev/null
    done

    # Check the file passes decompression test
    case "${FILE_EXTENSION}" in
        bzip2|bz2) FILE_TEST="bzip2 -t";;
        gzip|gz) FILE_TEST="gzip -t";;
        xz) FILE_TEST="xz -t";;
        zip) FILE_TEST="unzip -qq -t";;
    esac

    if [ -n "${FILE_TEST}" ]; then
        if ! ${FILE_TEST} "${FILE_OUTPUT}"; then
            echo "Testing ${FILE} integrity failed. Deleting it."
            rm "${FILE_OUTPUT}" 2>/dev/null
            download_file "${URL}"
        fi
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
            until git clone "${REPO}" --filter=tree:0 --recurse-submodules --shallow-submodules "${DIR}"; do
                echo "Retrying git clone ${REPO}..."
                rm -rf "${DIR}"
            done
            pushd "${DIR}"
            git checkout "${BRANCH}"
            popd
        else
            until git clone "${REPO}" --filter=tree:0 --recurse-submodules --shallow-submodules --branch "${BRANCH}" "${DIR}"; do
                echo "Retrying git clone ${REPO}..."
                rm -rf "${DIR}"
            done
        fi
    fi
}

function stage_01_get_apt() {
    local PKG_LIST="binutils bzip2 clang-format clang-tidy cmake curl file git gzip libarchive-tools libc6-dev make meson ninja-build patch pkg-config tree unzip wget xz-utils"

    if [ "${DISTRO_CMP_VER}" -ge 2310 ]; then
        PKG_LIST+=" gcc-12 g++-12 golang-go"
    else
        PKG_LIST+=" gcc g++ golang-go"
    fi

    PKG_LIST+=" qt6-base-dev qt6-base-private-dev qt6-wayland"
    if [ "${DISTRO_CMP_VER}" -ge 2204 ]; then
        PKG_LIST+=" libqt6svg6-dev"
    elif [ "${DISTRO_CMP_VER}" -ge 2304 ]; then
        PKG_LIST+=" qt6-svg-dev"
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

    # New deps added in OBS Studio 29.1.0, mostly related to OBS Websocket 5.2 support
    # - https://github.com/obsproject/obs-studio/pull/8194
    PKG_LIST+=" libasio-dev libwebsocketpp-dev nlohmann-json3-dev"

    # OBS Studio 30.0.0 added qrcode and oneVPL
    # https://github.com/obsproject/obs-studio/pull/8943
    PKG_LIST+=" libqrcodegencpp-dev"
    if [ "${DISTRO_CMP_VER}" -ge 2204 ]; then
        # Intel® oneAPI Video Processing Library (oneVPL)
        PKG_LIST+=" libvpl-dev libvpl2"
    fi

    # Pipewire
    if [ "${DISTRO_CMP_VER}" -ge 2204 ]; then
        PKG_LIST+=" libpipewire-0.3-dev"
    else
        PKG_LIST+=" libpipewire-0.2-dev"
    fi

    # Screne Switcher
    PKG_LIST+=" libleptonica-dev libopencv-dev libtesseract-dev libxss-dev libxtst-dev"
    if [ "${DISTRO_CMP_VER}" -ge 2304 ]; then
        PKG_LIST+=" libproc2-dev"
    else
        PKG_LIST+=" libprocps-dev"
    fi

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
    # Async Audio Filter
    PKG_LIST+=" libsamplerate0-dev  libsndfile1-dev"

    if [ "${DISTRO_CMP_VER}" -ge 2204 ]; then
        # VKCapture
        PKG_LIST+=" glslang-dev glslang-tools"
        #AV1
        PKG_LIST+=" libaom-dev"
        # URL Source
        PKG_LIST+=" libidn2-dev libpsl-dev libssl-dev"
    fi

    DEBIAN_FRONTEND=noninteractive apt-get -y update
    DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
    #shellcheck disable=SC2086
    DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends ${PKG_LIST}

    if [ "${DISTRO_CMP_VER}" -ge 2310 ]; then
        update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 800 --slave /usr/bin/g++ g++ /usr/bin/g++-12
    fi
}

function stage_02_get_obs() {
    clone_source "https://github.com/obsproject/obs-studio.git" "${OBS_VER}" "${DIR_SOURCE}"
}

function stage_03_get_cef() {
    download_file "https://cdn-fastly.obsproject.com/downloads/cef_binary_${CEF_VER}_linux_x86_64_v3.tar.xz"
    mkdir -p "${DIR_BUILD}/cef"
    bsdtar --strip-components=1 -xf "${DIR_DOWNLOAD}/cef_binary_${CEF_VER}_linux_x86_64_v3.tar.xz" -C "${DIR_BUILD}/cef"
    mkdir -p "${DIR_INSTALL}/cef"
    cp -a "${DIR_BUILD}/cef/Release/"* "${DIR_INSTALL}/cef/"
    cp -a "${DIR_BUILD}/cef/Resources/"* "${DIR_INSTALL}/cef/"
    cp "${DIR_BUILD}/cef/"{LICENSE.txt,README.txt} "${DIR_INSTALL}/cef/"
    chmod 755 "${DIR_INSTALL}/cef/locales"
}

function stage_04_build_aja() {
    download_file "https://github.com/aja-video/ntv2/archive/refs/tags/${AJA_VER}.tar.gz"
    mkdir -p "${DIR_SOURCE}/ntv2"
    bsdtar --strip-components=1 -xf "${DIR_DOWNLOAD}/${AJA_VER}.tar.gz" -C "${DIR_SOURCE}/ntv2"
    cmake -S "${DIR_SOURCE}/ntv2/" -B "${DIR_SOURCE}/ntv2/build/" -G Ninja \
        -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
        -DAJA_BUILD_OPENSOURCE=ON \
        -DAJA_BUILD_APPS=OFF \
        -DAJA_INSTALL_HEADERS=ON | tee "${DIR_BUILD}/cmake-aja.log"
    cmake --build "${DIR_SOURCE}/ntv2/build/"
    cmake --install "${DIR_SOURCE}/ntv2/build/" --prefix "${DIR_BUILD}/aja"
}

function stage_05_build_obs() {
    local BUILD_TO="${DIR_SYSTEM}"
    local INSTALL_TO="/usr"
    local OPTIONS="-DENABLE_BROWSER=ON -DENABLE_RTMPS=ON -DENABLE_VST=ON"

    if [ "${1}" == "portable" ]; then
        BUILD_TO="${DIR_PORTABLE}"
        INSTALL_TO="${DIR_INSTALL}"
        OPTIONS+=" -DLINUX_PORTABLE=ON"
    else
        OPTIONS+=" -DLINUX_PORTABLE=OFF"
    fi

    if [ "${DISTRO_CMP_VER}" -ge 2204 ]; then
        OPTIONS+=" -DENABLE_PIPEWIRE=ON"
    else
        OPTIONS+=" -DENABLE_PIPEWIRE=OFF"
    fi

    if [ "${DISTRO_CMP_VER}" -ge 2210 ]; then
        OPTIONS+=" -DENABLE_NEW_MPEGTS_OUTPUT=ON"
    else
        OPTIONS+=" -DENABLE_NEW_MPEGTS_OUTPUT=OFF"
    fi

    # libdatachannel is not available in any Ubuntu release
    if [ "${OBS_MAJ_VER}" -ge 30 ]; then
        OPTIONS+=" -DENABLE_WEBRTC=OFF"
    fi

    local TWITCH_OPTIONS=""
    if [ "${TWITCH_CLIENTID}" ] && [ "${TWITCH_HASH}" ]; then
        #shellcheck disable=SC2089
        TWITCH_OPTIONS="-DTWITCH_CLIENTID='${TWITCH_CLIENTID}' -DTWITCH_HASH='${TWITCH_HASH}'"
    fi

    local RESTREAM_OPTIONS=""
    if [ "${RESTREAM_CLIENTID}" ] && [ "${RESTREAM_HASH}" ]; then
        #shellcheck disable=SC2089
        RESTREAM_OPTIONS="-DRESTREAM_CLIENTID='${RESTREAM_CLIENTID}' -DRESTREAM_HASH='${RESTREAM_HASH}'"
    fi

    local YOUTUBE_OPTIONS=""
    if [ "${YOUTUBE_CLIENTID}" ] && [ "${YOUTUBE_CLIENTID_HASH}" ] && [ "${YOUTUBE_SECRET}" ] && [ "${YOUTUBE_SECRET_HASH}" ]; then
        #shellcheck disable=SC2089
        YOUTUBE_OPTIONS="-DYOUTUBE_CLIENTID='${YOUTUBE_CLIENTID}' -DYOUTUBE_CLIENTID_HASH='${YOUTUBE_CLIENTID_HASH}' -DYOUTUBE_SECRET='${YOUTUBE_SECRET}' -DYOUTUBE_SECRET_HASH='${YOUTUBE_SECRET_HASH}'"
    fi

    #shellcheck disable=SC2086,SC2090
    cmake -S "${DIR_SOURCE}/" -B "${BUILD_TO}/" -G Ninja \
      -DCALM_DEPRECATION=ON \
      -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
      -DCMAKE_INSTALL_PREFIX="${INSTALL_TO}" \
      -DENABLE_AJA=ON \
      -DAJA_LIBRARIES_INCLUDE_DIR="${DIR_BUILD}"/aja/include/ \
      -DAJA_NTV2_LIB="${DIR_BUILD}"/aja/lib/libajantv2.a \
      -DCEF_ROOT_DIR="${DIR_BUILD}/cef" \
      -DENABLE_ALSA=OFF \
      -DENABLE_JACK=ON \
      -DENABLE_LIBFDK=ON \
      -DENABLE_PULSEAUDIO=ON \
      -DENABLE_VLC=ON \
      -DENABLE_WAYLAND=ON \
      ${OPTIONS} ${RESTREAM_OPTIONS} ${TWITCH_OPTIONS} ${YOUTUBE_OPTIONS} \
      -Wno-dev --log-level=ERROR | tee "${DIR_BUILD}/cmake-obs-${TARGET}.log"
    cmake --build "${BUILD_TO}/"
    cmake --install "${BUILD_TO}/" --prefix "${INSTALL_TO}"
}

function stage_06_plugins() {
    local BRANCH=""
    local ERROR=""
    local EXTRA=""
    local PLUGIN=""
    local STATUS=""
    local URL=""

    #shellcheck disable=SC2162
    while read REPO; do
        URL="$(echo "${REPO}" | cut -d',' -f 1)"
        BRANCH="$(echo "${REPO}" | cut -d',' -f 2)"
        STATUS="$(echo "${REPO}" | cut -d',' -f 3 | sed 's/ //g')"
        PLUGIN="$(echo "${URL}" | cut -d'/' -f 5)"

        # Ignore disabled or auxillary plugins if instructed to build only the essential plugins
        if [ "${STATUS}" == "disabled" ]; then
            continue
        elif [ "${PLUGIN_LIST}" == "essential" ] && [ "${STATUS}" == "auxiliary" ]; then
            continue
        fi

        clone_source "${URL}.git" "${BRANCH}" "${DIR_PLUGIN}/${PLUGIN}"

        ERROR=""
        EXTRA=""
        if [ "${PLUGIN}" == "obs-teleport" ]; then
            # Requires Go 1.17, which is not available in Ubuntu 20.04
            export CGO_CPPFLAGS="${CPPFLAGS}"
            export CGO_CFLAGS="${CFLAGS} -I/usr/include/obs"
            export CGO_CXXFLAGS="${CXXFLAGS}"
            export CGO_LDFLAGS="${LDFLAGS} -ljpeg -lobs -lobs-frontend-api"
            export GOFLAGS="-buildmode=c-shared -trimpath -mod=readonly -modcacherw"
            pushd "${DIR_PLUGIN}/${PLUGIN}"
            go build -ldflags "-linkmode external -X main.version=${BRANCH}" -v -o "${DIR_INSTALL}/obs-plugins/64bit/${PLUGIN}.so" .
            mv "${DIR_INSTALL}/obs-plugins/64bit/${PLUGIN}.h" "${DIR_INSTALL}/include/" || true
            popd
        elif [ "${PLUGIN}" == "obs-gstreamer" ] || [ "${PLUGIN}" == "obs-vaapi" ]; then
            if [ "${DISTRO_CMP_VER}" -le 2204 ]; then
                meson --buildtype=${BUILD_TYPE,,} --prefix="${DIR_INSTALL}" --libdir="${DIR_INSTALL}" "${DIR_PLUGIN}/${PLUGIN}" "${DIR_PLUGIN}/${PLUGIN}/build"
            else
                meson setup --buildtype=${BUILD_TYPE,,} --prefix="${DIR_INSTALL}" --libdir="${DIR_INSTALL}" "${DIR_PLUGIN}/${PLUGIN}" "${DIR_PLUGIN}/${PLUGIN}/build"
            fi
            ninja -C "${DIR_PLUGIN}/${PLUGIN}/build"
            ninja -C "${DIR_PLUGIN}/${PLUGIN}/build" install
            if [ -e "${DIR_INSTALL}/obs-plugins/${PLUGIN}.so" ]; then
                mv "${DIR_INSTALL}/obs-plugins/${PLUGIN}.so" "${DIR_INSTALL}/obs-plugins/64bit/" || true
            elif [ -e "${DIR_INSTALL}/${PLUGIN}.so" ]; then
                mv "${DIR_INSTALL}/${PLUGIN}.so" "${DIR_INSTALL}/obs-plugins/64bit/" || true
            fi
        else
            if grep 'BUILD_OUT_OF_TREE' "${DIR_PLUGIN}/${PLUGIN}/CMakeLists.txt"; then
                EXTRA+=" -DBUILD_OUT_OF_TREE=ON"
            fi
            if grep '"name": "linux-x86_64"' "${DIR_PLUGIN}/${PLUGIN}/CMakePresets.json"; then
                EXTRA+=" --preset linux-x86_64"
            fi
            # Some plugins use deprecated OBS APIs such as obs_frontend_add_dock()
            if grep -R obs_frontend_add_dock "${DIR_PLUGIN}/${PLUGIN}"/* || grep -R obs_service_get_output_type "${DIR_PLUGIN}/${PLUGIN}"/*; then
                ERROR+=" -Wno-error=deprecated-declarations"
            fi
            case "${PLUGIN}" in
                obs-face-tracker)
                    EXTRA+=" -DQT_VERSION=6"
                    # Add face detection models for face tracker plugin
                    download_file "https://github.com/norihiro/obs-face-tracker/releases/download/0.7.0-hogdata/frontal_face_detector.dat.bz2" "${DIR_INSTALL}/data/obs-plugins/obs-face-tracker/data/dlib_hog_model/frontal_face_detector.dat.bz2"
                    download_file "https://github.com/davisking/dlib-models/raw/master/mmod_human_face_detector.dat.bz2" "${DIR_INSTALL}/data/obs-plugins/obs-face-tracker/data/dlib_cnn_model/mmod_human_face_detector.dat.bz2"
                    download_file "https://github.com/davisking/dlib-models/raw/master/shape_predictor_5_face_landmarks.dat.bz2" "${DIR_INSTALL}/data/obs-plugins/obs-face-tracker/data/dlib_face_landmark_model/shape_predictor_5_face_landmarks.dat.bz2"
                    bunzip2 -f "${DIR_INSTALL}/data/obs-plugins/obs-face-tracker/data/dlib_hog_model/frontal_face_detector.dat.bz2"
                    bunzip2 -f "${DIR_INSTALL}/data/obs-plugins/obs-face-tracker/data/dlib_cnn_model/mmod_human_face_detector.dat.bz2"
                    bunzip2 -f "${DIR_INSTALL}/data/obs-plugins/obs-face-tracker/data/dlib_face_landmark_model/shape_predictor_5_face_landmarks.dat.bz2";;
                obs-multi-rtmp)
                    ERROR+=" -Wno-error=conversion -Wno-error=float-conversion -Wno-error=shadow -Wno-error=sign-compare";;
                obs-ndi)
                    download_file "https://github.com/obs-ndi/obs-ndi/releases/download/4.11.1/libndi5_5.5.3-1_amd64.deb"
                    download_file "https://github.com/obs-ndi/obs-ndi/releases/download/4.11.1/libndi5-dev_5.5.3-1_amd64.deb"
                    DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends "${DIR_DOWNLOAD}"/*.deb
                    cp -v /usr/lib/libndi.so "${DIR_INSTALL}/lib/";;
                obs-source-dock)
                    ERROR+=" -Wno-error=switch";;
                obs-stroke-glow-shadow)
                    ERROR+=" -Wno-error=stringop-overflow";;
                obs-urlsource)
                    ERROR+=" -Wno-error=conversion -Wno-error=float-conversion -Wno-error=shadow";;
                tuna)
                    # Use system libmpdclient and taglib
                    # https://aur.archlinux.org/packages/obs-tuna
                    download_file "https://aur.archlinux.org/cgit/aur.git/plain/FindLibMPDClient.cmake?h=obs-tuna" "${DIR_PLUGIN}/${PLUGIN}/cmake/external/FindLibMPDClient.cmake"
                    download_file "https://aur.archlinux.org/cgit/aur.git/plain/FindTaglib.cmake?h=obs-tuna" "${DIR_PLUGIN}/${PLUGIN}/cmake/external/FindTaglib.cmake"
                    download_file "https://aur.archlinux.org/cgit/aur.git/plain/deps_CMakeLists.txt?h=obs-tuna" "${DIR_PLUGIN}/${PLUGIN}/deps/CMakeLists.txt"
                    sed -i '13 a find_package(LibMPDClient REQUIRED)\nfind_package(Taglib REQUIRED)' "${DIR_PLUGIN}/${PLUGIN}/CMakeLists.txt"
                    EXTRA+=" -DCREDS=MISSING -DLASTFM_CREDS=MISSING";;
            esac
            # Build process for OBS Studio 28 and newer
            #shellcheck disable=SC2086
            cmake -S "${DIR_PLUGIN}/${PLUGIN}" -B "${DIR_PLUGIN}/${PLUGIN}/build" -G Ninja \
              -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
              -DCMAKE_CXX_FLAGS="${ERROR}" \
              -DCMAKE_C_FLAGS="${ERROR}" \
              -DCMAKE_INSTALL_PREFIX="${DIR_INSTALL}" \
              ${EXTRA} -Wno-dev | tee "${DIR_BUILD}/cmake-${PLUGIN}.log"
            cmake --build "${DIR_PLUGIN}/${PLUGIN}/build"
            cmake --install "${DIR_PLUGIN}/${PLUGIN}/build" --prefix "${DIR_INSTALL}/"
        fi
    done < ./plugins-"${OBS_MAJ_VER}".csv

    # Re-organise misplaced plugins
    mv -v "${DIR_INSTALL}/lib/obs-plugins/"*.so "${DIR_INSTALL}/obs-plugins/64bit/"
    cp -av "${DIR_INSTALL}/share/obs/obs-plugins/"* "${DIR_INSTALL}/data/obs-plugins/"
    rm -rf "${DIR_INSTALL}/share/obs/obs-plugins"
    # Re-organsise waveform plugin
    if [ -d "${DIR_INSTALL}/waveform" ]; then
        mv -v "${DIR_INSTALL}/waveform/bin/64bit/"*.so "${DIR_INSTALL}/obs-plugins/64bit/"
        mkdir -p "${DIR_INSTALL}/data/obs-plugins/waveform"
        mv -v "${DIR_INSTALL}/waveform/data/"* "${DIR_INSTALL}/data/obs-plugins/waveform/"
        rm -rf "${DIR_INSTALL}/waveform/"
    fi
    # Re-organise multi-rtmp plugin
    if [ -d "${DIR_INSTALL}/dist/obs-multi-rtmp" ]; then
        mv -v "${DIR_INSTALL}/dist/obs-multi-rtmp/bin/64bit/"*.so "${DIR_INSTALL}/obs-plugins/64bit/"
        mkdir -p "${DIR_INSTALL}/data/obs-plugins/obs-multi-rtmp"
        mv -v "${DIR_INSTALL}/dist/obs-multi-rtmp/data/"* "${DIR_INSTALL}/data/obs-plugins/obs-multi-rtmp/"
        rm -rf "${DIR_INSTALL}/dist/obs-multi-rtmp"
    fi
    # Re-organsise libonnxruntime
    mv -v "${DIR_INSTALL}/lib/obs-plugins/obs-backgroundremoval/libonnxruntime"* "${DIR_INSTALL}/lib/" || true
}

function stage_07_themes() {
    download_file "https://obsproject.com/forum/resources/yami-resized.1611/version/5246/download" "${DIR_DOWNLOAD}/Yami-Resized-1.2.zip"
    unzip -o -qq "${DIR_DOWNLOAD}/Yami-Resized-1.2.zip" -d "${DIR_INSTALL}/data/obs-studio/themes"
}

function stage_08_finalise() {
    # Remove CEF files that are lumped in with obs-plugins
    # Prevents OBS from enumating the .so files to determine if they can be loaded as a plugin
    rm -rf "${DIR_INSTALL}/obs-plugins/64bit/locales" || true
    rm -rf "${DIR_INSTALL}/obs-plugins/64bit/swiftshader" || true
    for CEF_FILE in chrome-sandbox *.pak icudtl.dat libcef.so libEGL.so \
        libGLESv2.so libvk_swiftshader.so libvulkan.so.1 snapshot_blob.bin \
        v8_context_snapshot.bin vk_swiftshader_icd.json; do
        #shellcheck disable=SC2086
        rm -f "${DIR_INSTALL}/obs-plugins/64bit/"${CEF_FILE} || true
    done

    # Remove empty directories
    find "${DIR_INSTALL}" -type d -empty -delete

    # Strip binaries and correct permissions
    if [ "${BUILD_TYPE}" == "Release" ]; then
        for DIR in "${DIR_INSTALL}/cef" \
            "${DIR_INSTALL}/bin/64bit" \
            "${DIR_INSTALL}/obs-plugins/64bit" \
            "${DIR_INSTALL}/data/obs-scripting/64bit" \
            "${DIR_INSTALL}/lib"; do
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
        sed "s|TARGET_CODENAME|${DISTRO_CODENAME}|g" "./${SCRIPT}" > "${DIR_INSTALL}/${SCRIPT}"
        sed -i "s|TARGET_VERSION|${DISTRO_VERSION}|g" "${DIR_INSTALL}/${SCRIPT}"
        chmod 755 "${DIR_INSTALL}/${SCRIPT}"
    done

    # Populate the dependencies file
    echo "DEBIAN_FRONTEND=noninteractive sudo apt-get -y --no-install-recommends install \\" >> "${DIR_INSTALL}/obs-dependencies"
    echo "DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \\" >> "${DIR_INSTALL}/obs-container-dependencies"

    # Build a list of all the linked libraries
    rm -f obs-libs.txt 2>/dev/null || true
    for DIR in "${DIR_INSTALL}/cef" "${DIR_INSTALL}/bin/64bit" "${DIR_INSTALL}/obs-plugins/64bit" "${DIR_INSTALL}/data/obs-scripting/64bit"; do
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
        echo "$(dpkg -S "${LIB}" 2>/dev/null | cut -d ':' -f1 | grep -Fv -e '-dev' -e 'i386' -e 'pulseaudio' | sort -u)" >> obs-pkgs.txt
    done < <(sort -u obs-libs.txt)

    # Add the packages to the dependencies file
    #shellcheck disable=SC2162
    while read PKG; do
        if [ -n "${PKG}" ] && [ "${PKG}" != "libc6" ]; then
            echo -e "\t${PKG} \\" | tee -a "${DIR_INSTALL}/obs-dependencies" "${DIR_INSTALL}/obs-container-dependencies"
        fi
    done < <(sort -u obs-pkgs.txt)

    # Provide additional runtime requirements
    #shellcheck disable=SC1003
    echo -e '\tqt6-image-formats-plugins \\\n\tqt6-qpa-plugins \\\n\tqt6-wayland \\' | tee -a "${DIR_INSTALL}/obs-dependencies" "${DIR_INSTALL}/obs-container-dependencies"
    #shellcheck disable=SC1003
    echo -e '\tgstreamer1.0-plugins-good \\\n\tgstreamer1.0-plugins-bad \\\n\tgstreamer1.0-plugins-ugly \\\n\tgstreamer1.0-x \\' | tee -a "${DIR_INSTALL}/obs-dependencies" "${DIR_INSTALL}/obs-container-dependencies"
    #shellcheck disable=SC1003
    echo -e '\tlibgles2-mesa \\\n\tlibvlc5 \\\n\tvlc-plugin-base \\\n\tstterm' | tee -a "${DIR_INSTALL}/obs-dependencies"
    #shellcheck disable=SC1003
    echo -e '\tlibgles2-mesa \\\n\tlibvlc5 \\\n\tvlc-plugin-base \\\n\tstterm \\' | tee -a "${DIR_INSTALL}/obs-container-dependencies"
    #shellcheck disable=SC1003
    echo -e '\tmesa-vdpau-drivers \\\n\tmesa-va-drivers && \\' | tee -a "${DIR_INSTALL}/obs-container-dependencies"
    #shellcheck disable=SC1003
    echo -e 'apt-get -y clean && rm -rd /var/lib/apt/lists/*' | tee -a "${DIR_INSTALL}/obs-container-dependencies"
}

function stage_10_make_tarball() {
    local DIR_TARBALL=""
    DIR_TARBALL=$(basename "${DIR_INSTALL}")
    cd "${DIR_BASE}"
    tar cjf "${DIR_TARBALL}.tar.bz2" --exclude cmake --exclude include --exclude lib/pkgconfig "${DIR_TARBALL}"
    sha256sum "${DIR_TARBALL}.tar.bz2" > "${DIR_TARBALL}.tar.bz2.sha256"
    sed -i -r "s/ .*\/(.+)/  \1/g" "${DIR_TARBALL}.tar.bz2.sha256"
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
