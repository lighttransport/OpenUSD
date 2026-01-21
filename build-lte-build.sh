#!/bin/bash
# OpenUSD Build and Install Script
# Builds the configured OpenUSD project

set -e

# Get script directory (resolve symlinks) and repo root
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -P "${SCRIPT_DIR}/.." && pwd)"

# Set paths
SOURCE_DIR="${SCRIPT_DIR}"
BUILD_DIR="${SOURCE_DIR}/build-reldeb"
INSTALL_DIR="${ROOT_DIR}/dist-usd-reldeb"

# Check if build directory exists
if [ ! -d "${BUILD_DIR}" ]; then
    echo "========================================"
    echo "Build directory does not exist!"
    echo "Please run ./build-lte-configure.sh first"
    echo "========================================"
    exit 1
fi

# Change to build directory
cd "${BUILD_DIR}"

# Get number of cores for parallel build
if command -v nproc >/dev/null 2>&1; then
    NUM_CORES=$(nproc)
elif command -v sysctl >/dev/null 2>&1; then
    NUM_CORES=$(sysctl -n hw.ncpu)
else
    NUM_CORES=4
fi

echo "========================================"
echo "Building OpenUSD"
echo "========================================"
echo "Build directory: ${BUILD_DIR}"
echo "Install directory: ${INSTALL_DIR}"
echo "Build Type: RelWithDebInfo"
echo "Using ${NUM_CORES} parallel jobs"
echo "========================================"

# Build and install
cmake --build . --config RelWithDebInfo --target install -j "${NUM_CORES}"

if [ $? -eq 0 ]; then
    echo "========================================"
    echo "Build and install completed successfully!"
    echo "Install location: ${INSTALL_DIR}"
    echo "========================================"
    echo ""
    echo "To use this build, set:"
    echo "  export PYTHONPATH=${INSTALL_DIR}/lib/python:\${PYTHONPATH}"
    echo "  export LD_LIBRARY_PATH=${INSTALL_DIR}/lib:\${LD_LIBRARY_PATH}"
    echo "  export PATH=${INSTALL_DIR}/bin:\${PATH}"
    echo "========================================"
else
    echo "========================================"
    echo "Build failed!"
    echo "========================================"
    exit 1
fi
