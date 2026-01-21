#!/bin/bash

# USD build script with LTE custom namespace
# - Custom namespace: lte
# - Minimal dependencies
# - RelWithDebInfo build type
# - Python bindings enabled

set -e

# Get script directory (resolve symlinks)
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
INSTALL_DIR="${1:-/tmp/usd-lte-install}"
BUILD_TYPE="relwithdebuginfo"
NUM_CORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

echo "========================================="
echo "USD LTE Build Configuration"
echo "========================================="
echo "Install Directory: ${INSTALL_DIR}"
echo "Build Type: ${BUILD_TYPE}"
echo "Parallel Jobs: ${NUM_CORES}"
echo "Custom Namespace: lte"
echo "========================================="

# Build USD with minimal dependencies
python "${SCRIPT_DIR}/build_scripts/build_usd.py" \
    "${INSTALL_DIR}" \
    --build-variant ${BUILD_TYPE} \
    --build-args USD,"-DPXR_SET_EXTERNAL_NAMESPACE=lte -DPXR_ENABLE_PYTHON_SUPPORT=TRUE -DPXR_BUILD_IMAGING=FALSE -DPXR_BUILD_USD_TOOLS=FALSE -DPXR_BUILD_TESTS=FALSE" \
    -j ${NUM_CORES} \
    --no-imaging \
    --no-examples \
    --no-tutorials \
    --no-tools \
    --no-docs \
    --no-draco \
    --no-materialx

echo ""
echo "========================================="
echo "Build Complete!"
echo "========================================="
echo "Install location: ${INSTALL_DIR}"
echo ""
echo "To use this build, set:"
echo "  export PYTHONPATH=${INSTALL_DIR}/lib/python:\${PYTHONPATH}"
echo "  export LD_LIBRARY_PATH=${INSTALL_DIR}/lib:\${LD_LIBRARY_PATH}"
echo "  export PATH=${INSTALL_DIR}/bin:\${PATH}"
echo "========================================="
