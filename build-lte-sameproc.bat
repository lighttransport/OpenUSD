@echo off
REM Build OpenUSD v24.11 with custom namespace for same-process dual USD usage
REM
REM This build creates a separate USD installation that can coexist with
REM standard USD in the same Python process by using:
REM   - Different library prefix: lte_ (instead of usd_)
REM   - Different C++ namespace: pxr_lte (instead of pxr)
REM   - Different Python package: pxr_lte (instead of pxr)
REM
REM After building, you can import both in Python:
REM   from pxr import Usd as StandardUsd
REM   from pxr_lte import Usd as CustomUsd
REM
REM Usage:
REM   build-lte-sameproc.bat [configure|build|install|all|clean]
REM
REM   configure - Only run CMake configuration
REM   build     - Only build (requires prior configure)
REM   install   - Only install (requires prior build)
REM   all       - Configure, build, and install (default)
REM   clean     - Remove build directory
REM
REM Prerequisites:
REM   - Visual Studio 2022
REM   - Python 3.11+ (via uv or other installer)
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

REM Python configuration (uv-installed Python)
set UV_PYTHON_DIR=%USERPROFILE%\AppData\Roaming\uv\python\cpython-3.11.14-windows-x86_64-none
set UV_PYTHON=%UV_PYTHON_DIR%\python.exe
set UV_PYTHON_INCLUDE=%UV_PYTHON_DIR%\include
set UV_PYTHON_LIBS=%UV_PYTHON_DIR%\libs\python311.lib

REM Build type and parallelism
set BUILD_TYPE=Release
if not defined BUILD_JOBS set BUILD_JOBS=%NUMBER_OF_PROCESSORS%

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
if "%ACTION%"=="" set ACTION=all

if /i "%ACTION%"=="clean" goto :clean
if /i "%ACTION%"=="configure" goto :configure
if /i "%ACTION%"=="build" goto :build
if /i "%ACTION%"=="install" goto :install
if /i "%ACTION%"=="all" goto :all

echo Unknown action: %ACTION%
echo Usage: build-lte-sameproc.bat [configure^|build^|install^|all^|clean]
exit /b 1

REM ============================================================================
REM Clean
REM ============================================================================
:clean
echo Cleaning build directory: %BUILD_DIR%
if exist "%BUILD_DIR%" (
    rmdir /s /q "%BUILD_DIR%"
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
call :validate

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
if not exist "%BUILD_DIR%\CMakeCache.txt" (
    echo Error: Build directory not configured. Run with 'configure' first.
    exit /b 1
)

echo [Build] Building with %BUILD_JOBS% parallel jobs...
echo.

cd /d "%BUILD_DIR%"
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
if not exist "%BUILD_DIR%\CMakeCache.txt" (
    echo Error: Build directory not configured. Run with 'configure' first.
    exit /b 1
)

echo [Install] Installing to %INSTALL_DIR%...
echo.

cd /d "%BUILD_DIR%"
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
REM All (configure + build + install)
REM ============================================================================
:all
call :print_header
call :validate

echo [Step 1/3] Configuring CMake...
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
    exit /b 1
)

echo.
echo [Step 2/3] Building...
echo.

cmake --build . --config %BUILD_TYPE% --parallel %BUILD_JOBS%

if errorlevel 1 (
    echo.
    echo Build failed!
    exit /b 1
)

echo.
echo [Step 3/3] Installing...
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
echo Building OpenUSD v24.11 (Custom Namespace)
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
echo   Type:          %BUILD_TYPE%
echo   Parallel Jobs: %BUILD_JOBS%
echo   Imaging:       %BUILD_IMAGING%
echo ========================================
echo.
goto :eof

:validate
if not exist "%UV_PYTHON%" (
    echo Error: Python not found at %UV_PYTHON%
    echo Please install Python or update UV_PYTHON_DIR in this script.
    exit /b 1
)

if not exist "%TBB_ROOT%\include\tbb\tbb.h" (
    echo Error: TBB not found at %TBB_ROOT%
    echo Please run build-tbb.bat first or update TBB_ROOT in this script.
    exit /b 1
)
goto :eof

:print_success
echo.
echo ========================================
echo Build completed successfully!
echo ========================================
echo.
echo USD v24.11 installed to: %INSTALL_DIR%
echo.
echo Custom namespace configuration:
echo   C++ namespace:   %LTE_NAMESPACE%
echo   Library prefix:  %LTE_LIB_PREFIX%
echo   Python package:  %LTE_PYTHON_PACKAGE%
echo.
echo Usage in Python (same process):
echo   import os, sys
echo   os.add_dll_directory(r'%INSTALL_DIR%\lib')
echo   os.add_dll_directory(r'%INSTALL_DIR%\bin')
echo   os.add_dll_directory(r'%TBB_ROOT%\bin')
echo   sys.path.insert(0, r'%INSTALL_DIR%\lib\python')
echo.
echo   from pxr import Usd as StandardUsd      # Standard USD (pip)
echo   from %LTE_PYTHON_PACKAGE% import Usd as CustomUsd    # This build (v24.11)
echo.
echo Environment setup (optional):
echo   set PATH=%UV_PYTHON_DIR%;%INSTALL_DIR%\bin;%INSTALL_DIR%\lib;%TBB_ROOT%\bin;%%PATH%%
echo   set PYTHONPATH=%INSTALL_DIR%\lib\python;%%PYTHONPATH%%
echo ========================================
goto :eof

:end
endlocal
