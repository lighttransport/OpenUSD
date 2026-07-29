# Cross-compilation toolchain for the Ubuntu-hosted LLVM-MinGW distribution.
#
# Usage:
#   cmake -S . -B build -G Ninja \
#     -DCMAKE_TOOLCHAIN_FILE=cmake/toolchains/llvm-mingw-x86_64.cmake \
#     -DLLVM_MINGW_ROOT=/path/to/llvm-mingw
#
# The toolchain is intentionally self-contained: the compiler supplies the
# Windows SDK and mingw-w64 headers/libraries, while CMake finds project
# dependencies from CMAKE_PREFIX_PATH.

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR AMD64)
# CMake does not set MINGW for a clang driver whose compiler ID is Clang,
# although LLVM-MinGW uses the MinGW ABI and runtime.
set(MINGW TRUE CACHE BOOL
    "Use the MinGW ABI and runtime with the LLVM-MinGW toolchain" FORCE)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_TRY_COMPILE_PLATFORM_VARIABLES LLVM_MINGW_ROOT)

set(LLVM_MINGW_ROOT "" CACHE PATH
    "Root directory of an Ubuntu-hosted LLVM-MinGW installation")
if(NOT LLVM_MINGW_ROOT)
    if(DEFINED ENV{LLVM_MINGW_ROOT})
        set(LLVM_MINGW_ROOT "$ENV{LLVM_MINGW_ROOT}")
    endif()
endif()
if(NOT LLVM_MINGW_ROOT)
    # CMake's try_compile projects may not inherit ordinary toolchain
    # variables, but they do inherit the compiler selected by the parent.
    # Recover the root in that case.
    if(CMAKE_CXX_COMPILER)
        get_filename_component(_llvm_mingw_bin "${CMAKE_CXX_COMPILER}" DIRECTORY)
        get_filename_component(LLVM_MINGW_ROOT "${_llvm_mingw_bin}" DIRECTORY)
    else()
        message(FATAL_ERROR
            "LLVM_MINGW_ROOT must point to the root of the LLVM-MinGW toolchain")
    endif()
endif()

set(_llvm_mingw_target x86_64-w64-mingw32)
set(CMAKE_C_COMPILER
    "${LLVM_MINGW_ROOT}/bin/${_llvm_mingw_target}-clang" CACHE FILEPATH "" FORCE)
set(CMAKE_CXX_COMPILER
    "${LLVM_MINGW_ROOT}/bin/${_llvm_mingw_target}-clang++" CACHE FILEPATH "" FORCE)
set(CMAKE_RC_COMPILER
    "${LLVM_MINGW_ROOT}/bin/${_llvm_mingw_target}-windres" CACHE FILEPATH "" FORCE)

set(CMAKE_AR
    "${LLVM_MINGW_ROOT}/bin/${_llvm_mingw_target}-llvm-ar" CACHE FILEPATH "" FORCE)
set(CMAKE_RANLIB
    "${LLVM_MINGW_ROOT}/bin/${_llvm_mingw_target}-llvm-ranlib" CACHE FILEPATH "" FORCE)

set(CMAKE_FIND_ROOT_PATH "${LLVM_MINGW_ROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# The LLVM-MinGW distribution keeps the mingw-w64 headers in the generic
# sysroot.  Also provide aliases for headers that OpenUSD spells with the
# Windows casing; this matters when the cross-build runs on a case-sensitive
# Ubuntu filesystem.
set(_llvm_mingw_include "${LLVM_MINGW_ROOT}/generic-w64-mingw32/include")
set(_llvm_mingw_alias_include "${CMAKE_CURRENT_LIST_DIR}/llvm-mingw-include")
set(CMAKE_C_FLAGS_INIT
    "-idirafter ${_llvm_mingw_alias_include} -idirafter ${_llvm_mingw_include}")
set(CMAKE_CXX_FLAGS_INIT
    "-idirafter ${_llvm_mingw_alias_include} -idirafter ${_llvm_mingw_include}")

# OpenUSD's Windows platform code names these system libraries using the
# spelling used by the Windows linker.  The Ubuntu archive is case-sensitive.
foreach(_llvm_mingw_lib IN ITEMS Ws2_32 Dbghelp Shlwapi)
    string(TOLOWER "${_llvm_mingw_lib}" _llvm_mingw_lib_lower)
    file(CREATE_LINK
        "${LLVM_MINGW_ROOT}/x86_64-w64-mingw32/lib/lib${_llvm_mingw_lib_lower}.a"
        "${LLVM_MINGW_ROOT}/x86_64-w64-mingw32/lib/lib${_llvm_mingw_lib}.a"
        SYMBOLIC COPY_ON_ERROR)
endforeach()
