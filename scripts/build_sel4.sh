#!/bin/sh

set -e

. "$(pwd)/.config"

if test "x$(pwd)" != "x/workspace"; then
  exec docker/enter_container.sh -i sel4 -d "$(pwd)" scripts/build_sel4.sh $@
fi

BUILDDIR="$1"
shift
SRCDIR="$1"
shift

# Validate input arguments.
# Build and source directories
# are required.
#
if test -z "$BUILDDIR"; then
	printf "ERROR: Build directory required!" >&2;
  exit 1
fi

if test -z "$SRCDIR"; then
	printf "ERROR: Source directory required!" >&2;
  exit 1
fi

rm -rf "${BUILDDIR}"
mkdir -p "${BUILDDIR}"
ln -s ../tools/seL4/cmake-tool/init-build.sh "${BUILDDIR}"
ln -s "/workspace/${SRCDIR}/easy-settings.cmake" "${BUILDDIR}"
cd "${BUILDDIR}"
./init-build.sh -B . -DAARCH64=1 -DPLATFORM="${PLATFORM}" -DCROSS_COMPILER_PREFIX="${CROSS_COMPILE}" $@
ninja

# Generate U-Boot script
./scripts/generate_uboot_bootscript.sh -b "${BUILDDIR}" -t images -s elfloader/elfloader

echo "------------------------------------------------"
echo "------------------------------------------------"
echo "------------------------------------------------"
echo "                                                "
echo "Here are your binaries in "${BUILDDIR}/images": "
echo "                                                "
ls -la ./images
