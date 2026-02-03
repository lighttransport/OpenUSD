@echo off
REM Build TBB (Threading Building Blocks) for Windows
REM
REM This script downloads and builds TBB from source using CMake.
REM TBB is required for building OpenUSD.
REM
REM Usage:
REM   build-tbb.bat [configure|build|install|all|clean]
REM
REM   configure - Only run CMake configuration
REM   build     - Only build (requires prior configure)
REM   install   - Only install (requires prior build)
REM   all       - Configure, build, and install (default)
REM   clean     - Remove build directory

setlocal enabledelayedexpansion

REM ============================================================================
REM Configuration - Modify these as needed
REM ============================================================================

REM TBB version and download URL
set TBB_VERSION=2021.9.0
set TBB_TAG=v%TBB_VERSION%
set TBB_REPO=https://github.com/oneapi-src/oneTBB.git

REM Paths
set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%
set WORK_DIR=%SCRIPT_DIR%\..
set TBB_SOURCE_DIR=%WORK_DIR%\oneTBB
set TBB_BUILD_DIR=%WORK_DIR%\build-tbb
set TBB_INSTALL_DIR=%WORK_DIR%\dist-tbb-reldeb

REM Build type and parallelism
set BUILD_TYPE=RelWithDebInfo
if not defined BUILD_JOBS set BUILD_JOBS=%NUMBER_OF_PROCESSORS%

REM Visual Studio generator
set VS_GENERATOR=Visual Studio 17 2022
set VS_ARCH=x64

REM ============================================================================
REM Parse command line
REM ============================================================================

set ACTION=%1
if "%ACTION%"=="" set ACTION=all

if /i "%ACTION%"=="clean" goto :clean
if /i "%ACTION%"=="configure" goto :configure
if /i "%ACTION%"=="build" goto :build
if /i "%ACTION%"=="install" goto :install
if /i "%ACTION%"=="all" goto :all
if /i "%ACTION%"=="download" goto :download

echo Unknown action: %ACTION%
echo Usage: build-tbb.bat [configure^|build^|install^|all^|clean^|download]
exit /b 1

REM ============================================================================
REM Download
REM ============================================================================
:download
echo [Download] Cloning TBB %TBB_VERSION%...
echo.

if exist "%TBB_SOURCE_DIR%" (
    echo TBB source already exists at %TBB_SOURCE_DIR%
    echo Delete it first if you want to re-download.
    goto :end
)

cd /d "%WORK_DIR%"
git clone --depth 1 --branch %TBB_TAG% %TBB_REPO%

if errorlevel 1 (
    echo.
    echo Failed to clone TBB!
    exit /b 1
)

echo.
echo TBB source downloaded to %TBB_SOURCE_DIR%
goto :end

REM ============================================================================
REM Clean
REM ============================================================================
:clean
echo Cleaning build directory: %TBB_BUILD_DIR%
if exist "%TBB_BUILD_DIR%" (
    rmdir /s /q "%TBB_BUILD_DIR%"
    echo Build directory removed.
) else (
    echo Build directory does not exist.
)
goto :end

REM ============================================================================
REM Configure
REM ============================================================================
:configure
call :print_header
call :validate_source

echo [Configure] Running CMake configuration...
echo.

if not exist "%TBB_BUILD_DIR%" mkdir "%TBB_BUILD_DIR%"
cd /d "%TBB_BUILD_DIR%"

cmake ^
    -G "%VS_GENERATOR%" ^
    -A %VS_ARCH% ^
    -DCMAKE_BUILD_TYPE=%BUILD_TYPE% ^
    -DCMAKE_INSTALL_PREFIX="%TBB_INSTALL_DIR%" ^
    -DTBB_TEST=OFF ^
    -DTBB_STRICT=OFF ^
    "%TBB_SOURCE_DIR%"

if errorlevel 1 (
    echo.
    echo CMake configuration failed!
    exit /b 1
)

echo.
echo Configuration completed successfully.
cd /d "%SCRIPT_DIR%"
goto :end

REM ============================================================================
REM Build
REM ============================================================================
:build
if not exist "%TBB_BUILD_DIR%\CMakeCache.txt" (
    echo Error: Build directory not configured. Run with 'configure' first.
    exit /b 1
)

echo [Build] Building TBB with %BUILD_JOBS% parallel jobs...
echo.

cd /d "%TBB_BUILD_DIR%"
cmake --build . --config %BUILD_TYPE% --parallel %BUILD_JOBS%

if errorlevel 1 (
    echo.
    echo Build failed!
    exit /b 1
)

echo.
echo Build completed successfully.
cd /d "%SCRIPT_DIR%"
goto :end

REM ============================================================================
REM Install
REM ============================================================================
:install
if not exist "%TBB_BUILD_DIR%\CMakeCache.txt" (
    echo Error: Build directory not configured. Run with 'configure' first.
    exit /b 1
)

echo [Install] Installing TBB to %TBB_INSTALL_DIR%...
echo.

cd /d "%TBB_BUILD_DIR%"
cmake --build . --config %BUILD_TYPE% --target install

if errorlevel 1 (
    echo.
    echo Install failed!
    exit /b 1
)

echo.
echo Install completed successfully.
cd /d "%SCRIPT_DIR%"
goto :end

REM ============================================================================
REM All (download + configure + build + install)
REM ============================================================================
:all
call :print_header

REM Download if not exists
if not exist "%TBB_SOURCE_DIR%" (
    echo [Step 1/4] Downloading TBB source...
    echo.
    cd /d "%WORK_DIR%"
    git clone --depth 1 --branch %TBB_TAG% %TBB_REPO%
    if errorlevel 1 (
        echo.
        echo Failed to clone TBB!
        exit /b 1
    )
    echo.
) else (
    echo [Step 1/4] TBB source already exists, skipping download.
    echo.
)

call :validate_source

echo [Step 2/4] Configuring CMake...
echo.

if not exist "%TBB_BUILD_DIR%" mkdir "%TBB_BUILD_DIR%"
cd /d "%TBB_BUILD_DIR%"

cmake ^
    -G "%VS_GENERATOR%" ^
    -A %VS_ARCH% ^
    -DCMAKE_BUILD_TYPE=%BUILD_TYPE% ^
    -DCMAKE_INSTALL_PREFIX="%TBB_INSTALL_DIR%" ^
    -DTBB_TEST=OFF ^
    -DTBB_STRICT=OFF ^
    "%TBB_SOURCE_DIR%"

if errorlevel 1 (
    echo.
    echo CMake configuration failed!
    exit /b 1
)

echo.
echo [Step 3/4] Building...
echo.

cmake --build . --config %BUILD_TYPE% --parallel %BUILD_JOBS%

if errorlevel 1 (
    echo.
    echo Build failed!
    exit /b 1
)

echo.
echo [Step 4/4] Installing...
echo.

cmake --build . --config %BUILD_TYPE% --target install

if errorlevel 1 (
    echo.
    echo Install failed!
    exit /b 1
)

call :print_success
cd /d "%SCRIPT_DIR%"
goto :end

REM ============================================================================
REM Helper functions
REM ============================================================================

:print_header
echo ========================================
echo Building TBB (Threading Building Blocks)
echo ========================================
echo.
echo Version: %TBB_VERSION%
echo.
echo Paths:
echo   Source:  %TBB_SOURCE_DIR%
echo   Build:   %TBB_BUILD_DIR%
echo   Install: %TBB_INSTALL_DIR%
echo.
echo Build Settings:
echo   Type:          %BUILD_TYPE%
echo   Parallel Jobs: %BUILD_JOBS%
echo ========================================
echo.
goto :eof

:validate_source
if not exist "%TBB_SOURCE_DIR%\CMakeLists.txt" (
    echo Error: TBB source not found at %TBB_SOURCE_DIR%
    echo Run 'build-tbb.bat download' first or clone manually:
    echo   git clone --depth 1 --branch %TBB_TAG% %TBB_REPO% %TBB_SOURCE_DIR%
    exit /b 1
)
goto :eof

:print_success
echo.
echo ========================================
echo TBB build completed successfully!
echo ========================================
echo.
echo Installed to: %TBB_INSTALL_DIR%
echo.
echo To use TBB with USD, set TBB_ROOT_DIR:
echo   -DTBB_ROOT_DIR=%TBB_INSTALL_DIR%
echo.
echo Or add to PATH:
echo   set PATH=%TBB_INSTALL_DIR%\bin;%%PATH%%
echo ========================================
goto :eof

:end
endlocal
