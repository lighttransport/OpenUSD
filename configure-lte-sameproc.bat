@echo off
REM Configure OpenUSD with custom namespace for same-process dual USD usage
REM
REM This script only configures CMake - run build-lte-sameproc.bat to build.
REM
REM Configuration:
REM   - Library prefix:  lte_ (instead of usd_)
REM   - C++ namespace:   pxr_lte (instead of pxr)
REM   - Python package:  pxr_lte (instead of pxr)
REM
REM After building, you can import both in Python:
REM   from pxr import Usd as StandardUsd
REM   from pxr_lte import Usd as CustomUsd

setlocal enabledelayedexpansion

REM ============================================================================
REM Configuration - Modify these as needed
REM ============================================================================

REM Custom namespace settings
set LTE_NAMESPACE=pxr_lte
set LTE_LIB_PREFIX=lte_
set LTE_PYTHON_PACKAGE=pxr_lte

REM Paths (modify as needed for your system)
set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%
set SOURCE_DIR=%SCRIPT_DIR%
set BUILD_DIR=%SOURCE_DIR%\build-lte-sameproc
set INSTALL_DIR=%SOURCE_DIR%\..\dist-usd-lte
set TBB_ROOT=%SOURCE_DIR%\..\dist-tbb-reldeb

REM Python configuration (uv-installed Python)
set UV_PYTHON_DIR=%USERPROFILE%\AppData\Roaming\uv\python\cpython-3.11.14-windows-x86_64-none
set UV_PYTHON=%UV_PYTHON_DIR%\python.exe
set UV_PYTHON_INCLUDE=%UV_PYTHON_DIR%\include
set UV_PYTHON_LIBS=%UV_PYTHON_DIR%\libs\python311.lib

REM Build type
set BUILD_TYPE=RelWithDebInfo

REM Visual Studio generator
set VS_GENERATOR=Visual Studio 17 2022
set VS_ARCH=x64

REM Build options
set BUILD_IMAGING=OFF
set BUILD_USDVIEW=OFF
set BUILD_TESTS=OFF
set BUILD_EXAMPLES=OFF
set BUILD_TUTORIALS=OFF
set BUILD_DOCUMENTATION=OFF
set BUILD_USD_TOOLS=ON

REM ============================================================================
REM Validation
REM ============================================================================

echo ========================================
echo Configuring OpenUSD (Custom Namespace)
echo ========================================
echo.
echo Custom Namespace Configuration:
echo   C++ namespace:   %LTE_NAMESPACE%
echo   Library prefix:  %LTE_LIB_PREFIX%
echo   Python package:  %LTE_PYTHON_PACKAGE%
echo.
echo Paths:
echo   Source:  %SOURCE_DIR%
echo   Build:   %BUILD_DIR%
echo   Install: %INSTALL_DIR%
echo   TBB:     %TBB_ROOT%
echo   Python:  %UV_PYTHON%
echo.

REM Check Python
if not exist "%UV_PYTHON%" (
    echo Error: Python not found at %UV_PYTHON%
    echo Please install Python or update UV_PYTHON_DIR in this script.
    exit /b 1
)

REM Check TBB
if not exist "%TBB_ROOT%\include\tbb\tbb.h" (
    echo Error: TBB not found at %TBB_ROOT%
    echo Please install TBB or update TBB_ROOT in this script.
    exit /b 1
)

REM ============================================================================
REM Configure
REM ============================================================================

REM Create build directory
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

echo Configuring CMake...
echo.

cd /d "%BUILD_DIR%"

cmake ^
    -G "%VS_GENERATOR%" ^
    -A %VS_ARCH% ^
    -DCMAKE_BUILD_TYPE=%BUILD_TYPE% ^
    -DCMAKE_INSTALL_PREFIX="%INSTALL_DIR%" ^
    -DPXR_ENABLE_PYTHON_SUPPORT=ON ^
    -DPython3_EXECUTABLE="%UV_PYTHON%" ^
    -DPython3_INCLUDE_DIR="%UV_PYTHON_INCLUDE%" ^
    -DPython3_LIBRARY="%UV_PYTHON_LIBS%" ^
    -DPXR_PYTHON_SHEBANG="%UV_PYTHON%" ^
    -DPXR_USE_PYTHON_3=ON ^
    -DTBB_ROOT_DIR="%TBB_ROOT%" ^
    -DPXR_ENABLE_NAMESPACES=ON ^
    -DPXR_SET_EXTERNAL_NAMESPACE=%LTE_NAMESPACE% ^
    -DPXR_LIB_PREFIX=%LTE_LIB_PREFIX% ^
    -DPXR_PYTHON_PACKAGE_NAME=%LTE_PYTHON_PACKAGE% ^
    -DPXR_BUILD_IMAGING=%BUILD_IMAGING% ^
    -DPXR_BUILD_USDVIEW=%BUILD_USDVIEW% ^
    -DPXR_BUILD_TESTS=%BUILD_TESTS% ^
    -DPXR_BUILD_EXAMPLES=%BUILD_EXAMPLES% ^
    -DPXR_BUILD_TUTORIALS=%BUILD_TUTORIALS% ^
    -DPXR_BUILD_DOCUMENTATION=%BUILD_DOCUMENTATION% ^
    -DPXR_BUILD_USD_TOOLS=%BUILD_USD_TOOLS% ^
    -DCMAKE_CXX_FLAGS="/Zm150 /D__TBB_NO_IMPLICIT_LINKAGE /DNOMINMAX" ^
    "%SOURCE_DIR%"

if errorlevel 1 (
    echo.
    echo CMake configuration failed!
    exit /b 1
)

echo.
echo ========================================
echo Configuration completed successfully!
echo ========================================
echo.
echo Build directory: %BUILD_DIR%
echo.
echo To build, run:
echo   cd %BUILD_DIR%
echo   cmake --build . --config %BUILD_TYPE% --parallel
echo.
echo To install, run:
echo   cmake --build . --config %BUILD_TYPE% --target install
echo.
echo Or use build-lte-sameproc.bat to do both.
echo ========================================

cd /d "%SCRIPT_DIR%"
endlocal
