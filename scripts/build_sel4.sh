#!/usr/bin/env bash

set -e
#set -x

# Find utility functions
SCRIPT_DIR="$(realpath $0)"
SCRIPT_DIR="${SCRIPT_DIR%/*}"
. "${SCRIPT_DIR}"/utils.sh


# Variables
WORKSPACE_ROOT=
SOURCE_DIR=


# Check if we are in container yet.
# With 'container' variable we support native builds too:
# export container="skip", or similar, before calling make, 
# and entering container is skipped.

if [[ -z "${container}" ]] \
&& [[ -z "${IN_CONTAINER}" ]]; then

  if [[ "$#" -eq 4 ]] \
  || [[ "$#" -gt 4 ]]; then
    # shellcheck disable=SC2068
    exec docker/enter_container.sh "$1" "$2" "$3" "scripts/build_sel4.sh" "/workspace" "$4"
  else
    die "Invalid # of arguments!" 
  fi
fi


# Parse arguments, and check them
# after this conditional.
if [[ "$#" -eq 2 ]]; then

  # We entered container above, have 
  # only needed arguments left.
  WORKSPACE_ROOT="$1"
  SOURCE_DIR="$2"

elif [[ "$#" -eq 4 ]]; then

  # We were already in container or
  # we skipped entering it, 
  # discard unnecessary args.
  WORKSPACE_ROOT="$1"
  SOURCE_DIR="$4"

else
  die "Invalid # of arguments!" 
fi

[[ -z "${WORKSPACE_ROOT}" ]] && die "Invalid workspace root directory!"
[[ -z "${SOURCE_DIR}" ]] && die "Invalid source directory!"

WORKSPACE_ROOT="$(realpath "${WORKSPACE_ROOT}")"
SOURCE_DIR="$(realpath "${SOURCE_DIR}")"

# Set suffix to the basename of the source directory.
BUILD_DIR_SUFFIX="${SOURCE_DIR##*/}"

# Get config
# shellcheck disable=SC1091
. "${WORKSPACE_ROOT}/.config"

BUILD_DIR="${WORKSPACE_ROOT}/build_${PLATFORM}_${BUILD_DIR_SUFFIX}"
BUILD_DIR_LINK="${WORKSPACE_ROOT}/build"

if [[ -e "${BUILD_DIR}" ]] \
&& [[ -d "${BUILD_DIR}" ]]; then
  rm -rf "${BUILD_DIR}"
  rm -f "${BUILD_DIR_LINK}"
fi

mkdir -p "${BUILD_DIR}"
ln -rs "${BUILD_DIR}" "${BUILD_DIR_LINK}"

ln -rs "${WORKSPACE_ROOT}/tools/seL4/cmake-tool/init-build.sh" "${BUILD_DIR}"
ln -rs "${SOURCE_DIR}/easy-settings.cmake" "${BUILD_DIR}"

cd "${BUILD_DIR}" || die "Failed to enter build directory!"

# shellcheck disable=SC2068
#./init-build.sh -B . -DAARCH64=1 -DPLATFORM="${PLATFORM}" -DCROSS_COMPILER_PREFIX="${CROSS_COMPILE}" $@
./init-build.sh -B . -DPLATFORM="${PLATFORM}" -DRELEASE=FALSE -DSIMULATION=TRUE
ninja

echo "Here are your binaries in ${BUILD_DIR}: "
ls -lA "${BUILD_DIR}"/

echo "Link to build directory: ${BUILD_DIR_LINK}"
