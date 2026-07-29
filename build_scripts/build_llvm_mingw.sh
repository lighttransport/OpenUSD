#!/usr/bin/env bash
# Build a minimal monolithic OpenUSD Windows x64 package from Ubuntu using
# the prebuilt LLVM-MinGW cross compiler.

set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LLVM_MINGW_VERSION="${LLVM_MINGW_VERSION:-20260616}"
LLVM_MINGW_RELEASE="${LLVM_MINGW_RELEASE:-20260616}"
LLVM_MINGW_ARCHIVE="llvm-mingw-${LLVM_MINGW_VERSION}-ucrt-ubuntu-22.04-x86_64.tar.xz"
LLVM_MINGW_URL="https://github.com/mstorsjo/llvm-mingw/releases/download/${LLVM_MINGW_RELEASE}/${LLVM_MINGW_ARCHIVE}"
ONETBB_VERSION="${ONETBB_VERSION:-2021.12.0}"
ONETBB_ARCHIVE="oneTBB-${ONETBB_VERSION}.zip"
ONETBB_URL="https://github.com/oneapi-src/oneTBB/archive/refs/tags/v${ONETBB_VERSION}.zip"

BUILD_ROOT="${BUILD_ROOT:-${SOURCE_DIR}/build-llvm-mingw}"
LLVM_MINGW_ROOT="${LLVM_MINGW_ROOT:-${BUILD_ROOT}/${LLVM_MINGW_ARCHIVE%.tar.xz}}"
TBB_SOURCE_DIR="${BUILD_ROOT}/oneTBB-${ONETBB_VERSION}"
TBB_BUILD_DIR="${BUILD_ROOT}/tbb-build"
INSTALL_PREFIX="${INSTALL_PREFIX:-${BUILD_ROOT}/install}"
USD_BUILD_DIR="${USD_BUILD_DIR:-${BUILD_ROOT}/usd-build}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)}"

usage() {
    cat <<EOF
Usage: $(basename "$0") [clean]

Builds a minimal monolithic OpenUSD Windows x64 package with Ubuntu LLVM-MinGW.
The following environment variables may be overridden:
  BUILD_ROOT, LLVM_MINGW_ROOT, INSTALL_PREFIX, USD_BUILD_DIR, JOBS
  LLVM_MINGW_VERSION, LLVM_MINGW_RELEASE, ONETBB_VERSION

Output: INSTALL_PREFIX (default: ${INSTALL_PREFIX})
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

if [[ "${1:-}" == "clean" ]]; then
    rm -rf "${BUILD_ROOT}"
fi

for tool in cmake curl ninja tar unzip; do
    command -v "${tool}" >/dev/null || {
        echo "error: required command not found: ${tool}" >&2
        exit 1
    }
done

mkdir -p "${BUILD_ROOT}" "${INSTALL_PREFIX}"

if [[ ! -x "${LLVM_MINGW_ROOT}/bin/x86_64-w64-mingw32-clang++" ]]; then
    archive_path="${BUILD_ROOT}/${LLVM_MINGW_ARCHIVE}"
    if [[ ! -f "${archive_path}" ]]; then
        curl -fL --retry 3 -o "${archive_path}" "${LLVM_MINGW_URL}"
    fi
    mkdir -p "${LLVM_MINGW_ROOT}"
    tar -xJf "${archive_path}" --strip-components=1 -C "${LLVM_MINGW_ROOT}"
fi

export LLVM_MINGW_ROOT
TOOLCHAIN_FILE="${SOURCE_DIR}/cmake/toolchains/llvm-mingw-x86_64.cmake"

if [[ ! -f "${TBB_SOURCE_DIR}/CMakeLists.txt" ]]; then
    onetbb_archive_path="${BUILD_ROOT}/${ONETBB_ARCHIVE}"
    if [[ ! -f "${onetbb_archive_path}" ]]; then
        curl -fL --retry 3 -o "${onetbb_archive_path}" "${ONETBB_URL}"
    fi
    unzip -q "${onetbb_archive_path}" -d "${BUILD_ROOT}"
fi

# oneTBB's Clang compiler module adds ELF-only -z linker flags even for
# MinGW. Remove that flag for this temporary dependency source tree.
onetbb_clang_cmake="${TBB_SOURCE_DIR}/cmake/compilers/Clang.cmake"
sed -i 's/if (NOT APPLE)$/if (NOT APPLE AND NOT MINGW)/' "${onetbb_clang_cmake}"

cmake -S "${TBB_SOURCE_DIR}" -B "${TBB_BUILD_DIR}" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAIN_FILE}" \
    -DLLVM_MINGW_ROOT="${LLVM_MINGW_ROOT}" \
    -DMINGW=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
    -DTBB_TEST=OFF \
    -DTBB_STRICT=OFF \
    -DBUILD_SHARED_LIBS=ON
cmake --build "${TBB_BUILD_DIR}" --target install -j "${JOBS}"

cmake -S "${SOURCE_DIR}" -B "${USD_BUILD_DIR}" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAIN_FILE}" \
    -DLLVM_MINGW_ROOT="${LLVM_MINGW_ROOT}" \
    -DTBB_DIR="${INSTALL_PREFIX}/lib/cmake/TBB" \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DPXR_BUILD_MONOLITHIC=ON \
    -DPXR_ENABLE_PYTHON_SUPPORT=OFF \
    -DPXR_BUILD_IMAGING=OFF \
    -DPXR_BUILD_USD_IMAGING=OFF \
    -DPXR_BUILD_USDVIEW=OFF \
    -DPXR_BUILD_TESTS=OFF \
    -DPXR_BUILD_EXAMPLES=OFF \
    -DPXR_BUILD_TUTORIALS=OFF \
    -DPXR_BUILD_USD_TOOLS=OFF \
    -DPXR_BUILD_USD_VALIDATION=OFF \
    -DPXR_BUILD_DOCUMENTATION=OFF \
    -DPXR_BUILD_EXEC=OFF \
    -DPXR_FIND_TBB_IN_CONFIG=ON \
    -DPXR_ENABLE_COMPILER_CACHE=OFF
cmake --build "${USD_BUILD_DIR}" --target install -j "${JOBS}"

echo "LLVM-MinGW OpenUSD installed in: ${INSTALL_PREFIX}"
