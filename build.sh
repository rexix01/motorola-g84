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

source deviceinfo
source "$SCRIPT/common_functions.sh"
source "$SCRIPT/setup_repositories.sh" "${TMPDOWN}"

KERNEL_DIR="$(basename "${deviceinfo_kernel_source}")"
KERNEL_DIR="${KERNEL_DIR%.*}"

./build/build.sh "${args[@]}" -b "$BUILD_DIR"
