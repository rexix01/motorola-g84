#!/bin/bash
set -xe
shopt -s extglob

BUILD_DIR=workdir

# From https://stackoverflow.com/a/48808214
args=("$@")
for ((i=0; i<"${#args[@]}"; ++i)); do
    case ${args[i]} in
        -b) BUILD_DIR=${args[i+1]}; unset args[i]; unset args[i+1]; break;;
    esac
done

[ -d build ] || git clone https://gitlab.com/ubports/community-ports/halium-generic-adaptation-build-tools build

HERE=$(pwd)
SCRIPT="$(dirname "$(realpath "$0")")"/build
if [ ! -d "$SCRIPT" ]; then
    SCRIPT="$(dirname "$SCRIPT")"
fi
TMPDOWN="$BUILD_DIR/downloads"
mkdir -p "$TMPDOWN"

source deviceinfo
source "$SCRIPT/common_functions.sh"
source "$SCRIPT/setup_repositories.sh" "${TMPDOWN}"

KERNEL_DIR="$(basename "${deviceinfo_kernel_source}")"
KERNEL_DIR="${KERNEL_DIR%.*}"
echo $KERNEL_DIR

cd "$TMPDOWN/$KERNEL_DIR"

BRANCH="odm/dev/target/13/fp5"
DTS_BRANCH="kernel/13/fp5"
GERRIT_URL="https://gerrit-public.fairphone.software"
PLATFORM_VENDOR_URL="${GERRIT_URL}/platform/vendor"

# Clone kernel subfolder repositories
[ -d techpack/audio ] || git clone -b ${BRANCH} ${PLATFORM_VENDOR_URL}/opensource/audio-kernel techpack/audio
[ -d techpack/camera ] || git clone -b ${BRANCH} ${PLATFORM_VENDOR_URL}/opensource/camera-kernel techpack/camera
[ -d techpack/dataipa ] || git clone -b ${BRANCH} ${PLATFORM_VENDOR_URL}/opensource/dataipa techpack/dataipa
[ -d techpack/display ] || git clone -b ${BRANCH} ${PLATFORM_VENDOR_URL}/opensource/display-drivers techpack/display
[ -d techpack/video ] || git clone -b ${BRANCH} ${PLATFORM_VENDOR_URL}/opensource/video-driver techpack/video
[ -d drivers/staging/wlan-qc/fw-api ] || git clone -b ${BRANCH} ${PLATFORM_VENDOR_URL}/qcom-opensource/wlan/fw-api drivers/staging/wlan-qc/fw-api
[ -d drivers/staging/wlan-qc/qca-wifi-host-cmn ] || git clone -b ${BRANCH} ${PLATFORM_VENDOR_URL}/qcom-opensource/wlan/qca-wifi-host-cmn drivers/staging/wlan-qc/qca-wifi-host-cmn
[ -d drivers/staging/wlan-qc/qcacld-3.0 ] || git clone -b ${BRANCH} ${PLATFORM_VENDOR_URL}/qcom-opensource/wlan/qcacld-3.0 drivers/staging/wlan-qc/qcacld-3.0
[ -d arch/arm64/boot/dts/vendor ] || git clone -b ${DTS_BRANCH} ${GERRIT_URL}/kernel/msm-extra/devicetree arch/arm64/boot/dts/vendor

# Generate fp5_ALLYES_GKI.config from fp5_GKI.config
./scripts/gki/fragment_allyesconfig.sh arch/arm64/configs/vendor/fp5_GKI.config arch/arm64/configs/vendor/fp5_ALLYES_GKI.config

# Workaround for symlinks in techpack folder
mkdir -p "../../kernel"
ln -sf "$(pwd)" "../../kernel/msm-5.4"

cd "$HERE"

./build/build.sh "${args[@]}" -b "$BUILD_DIR"
