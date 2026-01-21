#!/bin/bash
# TBB Build Script
# Downloads and builds Intel oneTBB from source
# Build Type: RelWithDebInfo
# Target: ../dist-tbb-reldeb

set -e

# Get script directory (resolve symlinks) and repo root
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -P "${SCRIPT_DIR}/.." && pwd)"

# Set paths
TBB_INSTALL_DIR="${ROOT_DIR}/dist-tbb-reldeb"
TBB_SRC_DIR="${ROOT_DIR}/tbb-src"
TBB_BUILD_DIR="${ROOT_DIR}/tbb-build"

# TBB version and URL
TBB_VERSION="v2021.12.0"
TBB_URL="https://github.com/oneapi-src/oneTBB/archive/refs/tags/${TBB_VERSION}.tar.gz"

echo "========================================"
echo "Building Intel oneTBB from source"
echo "========================================"
echo "Version: ${TBB_VERSION}"
echo "Install Directory: ${TBB_INSTALL_DIR}"
echo "Source Directory: ${TBB_SRC_DIR}"
echo "Build Directory: ${TBB_BUILD_DIR}"
echo "========================================"

# Download TBB if not already present
if [ ! -d "${TBB_SRC_DIR}" ]; then
    echo "Downloading TBB..."
    mkdir -p "$(dirname "${TBB_SRC_DIR}")"
    cd "$(dirname "${TBB_SRC_DIR}")"

    if command -v curl >/dev/null 2>&1; then
        curl -L "${TBB_URL}" -o tbb.tar.gz
    elif command -v wget >/dev/null 2>&1; then
        wget "${TBB_URL}" -O tbb.tar.gz
    else
        echo "Error: Neither curl nor wget found. Please install one of them."
        exit 1
    fi

    echo "Extracting TBB..."
    tar -xzf tbb.tar.gz
    mv oneTBB-* tbb-src
    rm tbb.tar.gz
    echo "Download complete: ${TBB_SRC_DIR}"
else
    echo "Using existing TBB source at ${TBB_SRC_DIR}"
fi

# Create build directory
mkdir -p "${TBB_BUILD_DIR}"
cd "${TBB_BUILD_DIR}"

# Get number of cores for parallel build
if command -v nproc >/dev/null 2>&1; then
    NUM_CORES=$(nproc)
elif command -v sysctl >/dev/null 2>&1; then
    NUM_CORES=$(sysctl -n hw.ncpu)
else
    NUM_CORES=4
fi

echo ""
echo "========================================"
echo "Configuring TBB with CMake"
echo "========================================"
echo "Build Type: RelWithDebInfo"
echo "Parallel Jobs: ${NUM_CORES}"
echo "========================================"

# Detect generator
if command -v ninja >/dev/null 2>&1; then
    GENERATOR="Ninja"
else
    GENERATOR="Unix Makefiles"
fi

# Configure TBB with CMake
cmake \
    -G "${GENERATOR}" \
    -DCMAKE_INSTALL_PREFIX="${TBB_INSTALL_DIR}" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DTBB_TEST=OFF \
    -DTBB_STRICT=OFF \
    -DBUILD_SHARED_LIBS=ON \
    "${TBB_SRC_DIR}"

if [ $? -ne 0 ]; then
    echo "========================================"
    echo "TBB CMake configuration failed!"
    echo "========================================"
    exit 1
fi

echo ""
echo "========================================"
echo "Building TBB"
echo "========================================"

# Build and install TBB
cmake --build . --config RelWithDebInfo --target install -j "${NUM_CORES}"

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "TBB build completed successfully!"
    echo "========================================"
    echo "Install location: ${TBB_INSTALL_DIR}"
    echo ""
    echo "TBB is now ready to use for USD builds."
    echo "========================================"
else
    echo "========================================"
    echo "TBB build failed!"
    echo "========================================"
    exit 1
fi
