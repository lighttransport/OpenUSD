#!/bin/bash
# OpenUSD CMake Configuration Script
# Build Type: RelWithDebInfo
# Target: ../dist-usd-reldeb
# Custom Namespace: pxr_lte
# Library Prefix: lte
# Features: Python bindings only (minimal build)

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set paths
SOURCE_DIR="${SCRIPT_DIR}"
BUILD_DIR="${SOURCE_DIR}/build-reldeb"
INSTALL_DIR="${SOURCE_DIR}/../dist-usd-reldeb"
TBB_ROOT="${SOURCE_DIR}/../dist-tbb-reldeb"

# Detect Python from uv installation (not venv)
PYTHON3_ROOT_DIR=""
if command -v uv >/dev/null 2>&1; then
    UV_PYTHON_DIR=$(uv python dir 2>/dev/null || true)
    if [ -n "${UV_PYTHON_DIR}" ] && [ -d "${UV_PYTHON_DIR}" ]; then
        # Find the latest installed cpython version
        LATEST_CPYTHON=$(ls -d "${UV_PYTHON_DIR}"/cpython-* 2>/dev/null | sort -V | tail -1)
        if [ -n "${LATEST_CPYTHON}" ] && [ -d "${LATEST_CPYTHON}" ]; then
            PYTHON3_ROOT_DIR="${LATEST_CPYTHON}"
            echo "Detected uv-installed Python at ${PYTHON3_ROOT_DIR}"
        fi
    fi
fi

# Check if TBB exists
if [ ! -d "${TBB_ROOT}" ] || [ ! -f "${TBB_ROOT}/include/oneapi/tbb.h" ]; then
    echo "========================================"
    echo "ERROR: TBB not found at ${TBB_ROOT}"
    echo "========================================"
    echo "Please build TBB first by running:"
    echo "  ./build-tbb.sh"
    echo ""
    echo "Or provide a custom TBB_ROOT path."
    echo "========================================"
    exit 1
else
    echo "Using existing TBB at ${TBB_ROOT}"
fi

# Create build directory if it doesn't exist
mkdir -p "${BUILD_DIR}"

# Set TBB environment variable for FindTBB module
export TBB_INSTALL_DIR="${TBB_ROOT}"

# Change to build directory
cd "${BUILD_DIR}"

echo "========================================"
echo "Configuring OpenUSD with CMake"
echo "========================================"
echo "Source: ${SOURCE_DIR}"
echo "Build: ${BUILD_DIR}"
echo "Install: ${INSTALL_DIR}"
echo "TBB: ${TBB_ROOT}"
if [ -n "${PYTHON3_ROOT_DIR}" ]; then
    echo "Python3: ${PYTHON3_ROOT_DIR}"
fi
echo "Build Type: RelWithDebInfo"
echo "Custom Namespace: pxr_lte"
echo "Library Prefix: lte"
echo "========================================"

# Detect generator
if command -v ninja >/dev/null 2>&1; then
    GENERATOR="Ninja"
else
    GENERATOR="Unix Makefiles"
fi

# Build cmake arguments
CMAKE_ARGS=(
    -G "${GENERATOR}"
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"
    -DCMAKE_BUILD_TYPE=RelWithDebInfo
    -DPXR_SET_EXTERNAL_NAMESPACE=pxr_lte
    -DPXR_LIB_PREFIX=lte
    -DPXR_ENABLE_PYTHON_SUPPORT=ON
    -DPXR_USE_DEBUG_PYTHON=OFF
    -DBUILD_SHARED_LIBS=ON
    -DTBB_USE_DEBUG_BUILD=OFF
    -DTBB_ROOT_DIR="${TBB_ROOT}"
    -DPXR_BUILD_TESTS=OFF
    -DPXR_BUILD_EXAMPLES=OFF
    -DPXR_BUILD_TUTORIALS=OFF
    -DPXR_BUILD_DOCUMENTATION=OFF
    -DPXR_BUILD_USD_TOOLS=ON
    -DPXR_BUILD_IMAGING=OFF
    -DPXR_BUILD_USD_IMAGING=OFF
    -DPXR_BUILD_USDVIEW=OFF
    -DPXR_BUILD_ALEMBIC_PLUGIN=OFF
    -DPXR_BUILD_DRACO_PLUGIN=OFF
    -DPXR_ENABLE_MATERIALX_SUPPORT=OFF
    -DPXR_ENABLE_PTEX_SUPPORT=OFF
    -DPXR_ENABLE_OPENVDB_SUPPORT=OFF
    -DPXR_BUILD_OPENIMAGEIO_PLUGIN=OFF
    -DPXR_BUILD_OPENCOLORIO_PLUGIN=OFF
    -DPXR_BUILD_EMBREE_PLUGIN=OFF
    -DPXR_ENABLE_VULKAN_SUPPORT=OFF
)

# Add Python3_ROOT_DIR if uv-managed Python was detected
if [ -n "${PYTHON3_ROOT_DIR}" ]; then
    CMAKE_ARGS+=(-DPython3_ROOT_DIR="${PYTHON3_ROOT_DIR}")
fi

# Configure with CMake
cmake "${CMAKE_ARGS[@]}" "${SOURCE_DIR}"

if [ $? -eq 0 ]; then
    echo "========================================"
    echo "CMake configuration completed successfully!"
    echo "Build directory: ${BUILD_DIR}"
    echo "To build, run: ./build-lte-build.sh"
    echo "========================================"
else
    echo "========================================"
    echo "CMake configuration failed!"
    echo "========================================"
    exit 1
fi
