@echo off
REM Configure OpenUSD v24.11 with custom namespace for same-process dual USD usage
REM
REM This script runs CMake configuration only. Run build-usd-lte.bat after this.
REM
REM This build creates a separate USD installation that can coexist with
REM standard USD in the same Python process by using:
REM   - Different library prefix: lte_ (instead of usd_)
REM   - Different C++ namespace: pxr_lte (instead of pxr)
REM   - Different Python package: pxr_lte (instead of pxr)
REM
REM Usage:
REM   configure-lte-sameproc.bat [clean]
REM
REM   clean - Remove build directory before configuring
REM
REM Prerequisites:
REM   - Visual Studio 2022
REM   - Python 3.11+ with development headers (run setup-uv-python-dev.bat)
REM   - TBB (run build-tbb.bat first if not installed)
REM   - CMake 3.20+

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
set INSTALL_DIR=%SOURCE_DIR%\..\dist-usd-lte-v24.11
set TBB_ROOT=%SOURCE_DIR%\..\dist-tbb-reldeb

REM Python configuration
REM Option 1: UV-installed Python (may lack dev headers)
REM set UV_PYTHON_DIR=%USERPROFILE%\AppData\Roaming\uv\python\cpython-3.11.14-windows-x86_64-none

REM Option 2: Python.org or winget installed Python (recommended - includes dev headers)
REM set UV_PYTHON_DIR=C:\Python311
REM set UV_PYTHON_DIR=C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python311

REM Auto-detect Python - tries common locations
if not defined UV_PYTHON_DIR (
    REM Try UV managed Python first (not venv, which lacks dev headers)
    set UV_PYTHON_BASE=%USERPROFILE%\AppData\Roaming\uv\python
    for /d %%d in ("!UV_PYTHON_BASE!\cpython-3.11*-windows-x86_64-none") do (
        if exist "%%d\include\Python.h" (
            set UV_PYTHON_DIR=%%d
        )
    )
)

if not defined UV_PYTHON_DIR (
    REM Try winget/python.org location
    if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" (
        set UV_PYTHON_DIR=%LOCALAPPDATA%\Programs\Python\Python311
    )
)

if not defined UV_PYTHON_DIR (
    REM Try system Python
    if exist "C:\Python311\python.exe" (
        set UV_PYTHON_DIR=C:\Python311
    )
)

if not defined UV_PYTHON_DIR (
    echo Error: Could not find Python 3.11 installation.
    echo.
    echo Please either:
    echo   1. Run setup-uv-python-dev.bat to install Python via UV
    echo   2. Install Python from python.org
    echo   3. Set UV_PYTHON_DIR environment variable manually
    echo.
    exit /b 1
)

set UV_PYTHON=%UV_PYTHON_DIR%\python.exe
set UV_PYTHON_INCLUDE=%UV_PYTHON_DIR%\include

REM Auto-detect Python library (python3XX.lib)
set UV_PYTHON_LIBS=
for %%f in ("%UV_PYTHON_DIR%\libs\python3*.lib") do (
    REM Skip python3.lib (generic), prefer python3XX.lib
    echo %%~nf | findstr /r "python3[0-9][0-9]" >nul && set UV_PYTHON_LIBS=%%f
)
if not defined UV_PYTHON_LIBS set UV_PYTHON_LIBS=%UV_PYTHON_DIR%\libs\python311.lib

REM Build type and parallelism
set BUILD_TYPE=Release

REM Visual Studio generator
set VS_GENERATOR=Visual Studio 17 2022
set VS_ARCH=x64

REM Build options (set to ON/OFF as needed)
set BUILD_IMAGING=OFF
set BUILD_USD_IMAGING=OFF
set BUILD_USDVIEW=OFF
set BUILD_TESTS=OFF
set BUILD_EXAMPLES=OFF
set BUILD_TUTORIALS=OFF
set BUILD_DOCUMENTATION=OFF
set BUILD_USD_TOOLS=ON
set ENABLE_MATERIALX=OFF

REM ============================================================================
REM Parse command line
REM ============================================================================

set ACTION=%1

if /i "%ACTION%"=="clean" (
    echo Cleaning build directory: %BUILD_DIR%
    if exist "%BUILD_DIR%" (
        rmdir /s /q "%BUILD_DIR%"
        echo Build directory removed.
    ) else (
        echo Build directory does not exist.
    )
    echo.
    echo Proceeding with configuration...
    echo.
)

REM ============================================================================
REM Print header and validate
REM ============================================================================

echo ========================================
echo Configuring OpenUSD v24.11 (Custom Namespace)
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
echo Build Settings:
echo   Type:    %BUILD_TYPE%
echo   Imaging: %BUILD_IMAGING%
echo ========================================
echo.

REM Validate Python
if not exist "%UV_PYTHON%" (
    echo Error: Python not found at %UV_PYTHON%
    echo Please install Python or update UV_PYTHON_DIR in this script.
    exit /b 1
)

REM Validate Python include directory
if not exist "%UV_PYTHON_INCLUDE%\Python.h" (
    echo Error: Python.h not found at %UV_PYTHON_INCLUDE%
    echo.
    echo Your Python installation may not include development headers.
    echo Run setup-uv-python-dev.bat for help setting up Python.
    echo.
    echo Expected files:
    echo   %UV_PYTHON_INCLUDE%\Python.h
    echo   %UV_PYTHON_LIBS%
    echo.
    exit /b 1
)

REM Validate Python libs
if not exist "%UV_PYTHON_LIBS%" (
    echo Error: Python library not found at %UV_PYTHON_LIBS%
    echo.
    echo Your Python installation may not include development files.
    echo Run setup-uv-python-dev.bat for help setting up Python.
    exit /b 1
)

REM Validate TBB
if not exist "%TBB_ROOT%\include\tbb\tbb.h" (
    echo Error: TBB not found at %TBB_ROOT%
    echo Please run build-tbb.bat first or update TBB_ROOT in this script.
    exit /b 1
)

echo [Configure] Running CMake configuration...
echo.

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
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
    -DPXR_BUILD_USD_IMAGING=%BUILD_USD_IMAGING% ^
    -DPXR_BUILD_USDVIEW=%BUILD_USDVIEW% ^
    -DPXR_BUILD_TESTS=%BUILD_TESTS% ^
    -DPXR_BUILD_EXAMPLES=%BUILD_EXAMPLES% ^
    -DPXR_BUILD_TUTORIALS=%BUILD_TUTORIALS% ^
    -DPXR_BUILD_DOCUMENTATION=%BUILD_DOCUMENTATION% ^
    -DPXR_BUILD_USD_TOOLS=%BUILD_USD_TOOLS% ^
    -DPXR_ENABLE_MATERIALX_SUPPORT=%ENABLE_MATERIALX% ^
    -DCMAKE_CXX_FLAGS="/Zm150 /D__TBB_NO_IMPLICIT_LINKAGE /DNOMINMAX" ^
    "%SOURCE_DIR%"

if errorlevel 1 (
    echo.
    echo CMake configuration failed!
    cd /d "%SCRIPT_DIR%"
    exit /b 1
)

echo.
echo ========================================
echo Configuration completed successfully!
echo ========================================
echo.
echo Build directory: %BUILD_DIR%
echo.
echo Next steps:
echo   1. Run build-usd-lte.bat to build
echo   2. Run build-usd-lte.bat install to install
echo.
echo Or run both:
echo   build-usd-lte.bat all
echo ========================================

cd /d "%SCRIPT_DIR%"
endlocal
