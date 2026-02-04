@echo off
REM Build OpenUSD v24.11 with custom namespace (after configuration)
REM
REM This script builds and/or installs USD after CMake configuration.
REM Run configure-lte-sameproc.bat first!
REM
REM Usage:
REM   build-usd-lte.bat [build|install|all]
REM
REM   build   - Only build (default)
REM   install - Only install (requires prior build)
REM   all     - Build and install
REM
REM Prerequisites:
REM   - Run configure-lte-sameproc.bat first

setlocal enabledelayedexpansion

REM ============================================================================
REM Configuration - Must match configure-lte-sameproc.bat
REM ============================================================================

set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%
set SOURCE_DIR=%SCRIPT_DIR%
set BUILD_DIR=%SOURCE_DIR%\build-lte-sameproc
set INSTALL_DIR=%SOURCE_DIR%\..\dist-usd-lte-v24.11
set TBB_ROOT=%SOURCE_DIR%\..\dist-tbb-reldeb

REM Build type and parallelism
set BUILD_TYPE=Release
if not defined BUILD_JOBS set BUILD_JOBS=%NUMBER_OF_PROCESSORS%

REM Custom namespace settings (for success message)
set LTE_NAMESPACE=pxr_lte
set LTE_LIB_PREFIX=lte_
set LTE_PYTHON_PACKAGE=pxr_lte

REM ============================================================================
REM Parse command line
REM ============================================================================

set ACTION=%1
if "%ACTION%"=="" set ACTION=build

if /i "%ACTION%"=="build" goto :build
if /i "%ACTION%"=="install" goto :install
if /i "%ACTION%"=="all" goto :all

echo Unknown action: %ACTION%
echo Usage: build-usd-lte.bat [build^|install^|all]
exit /b 1

REM ============================================================================
REM Build
REM ============================================================================
:build
if not exist "%BUILD_DIR%\CMakeCache.txt" (
    echo Error: Build directory not configured.
    echo.
    echo Run configure-lte-sameproc.bat first.
    exit /b 1
)

echo ========================================
echo Building OpenUSD v24.11 (Custom Namespace)
echo ========================================
echo.
echo Build directory: %BUILD_DIR%
echo Build type:      %BUILD_TYPE%
echo Parallel jobs:   %BUILD_JOBS%
echo ========================================
echo.

cd /d "%BUILD_DIR%"
cmake --build . --config %BUILD_TYPE% --parallel %BUILD_JOBS%

if errorlevel 1 (
    echo.
    echo Build failed!
    cd /d "%SCRIPT_DIR%"
    exit /b 1
)

echo.
echo ========================================
echo Build completed successfully!
echo ========================================
echo.
echo Next step: Run 'build-usd-lte.bat install' to install.
echo ========================================
cd /d "%SCRIPT_DIR%"
goto :end

REM ============================================================================
REM Install
REM ============================================================================
:install
if not exist "%BUILD_DIR%\CMakeCache.txt" (
    echo Error: Build directory not configured.
    echo.
    echo Run configure-lte-sameproc.bat first.
    exit /b 1
)

echo ========================================
echo Installing OpenUSD v24.11 (Custom Namespace)
echo ========================================
echo.
echo Install directory: %INSTALL_DIR%
echo ========================================
echo.

cd /d "%BUILD_DIR%"
cmake --build . --config %BUILD_TYPE% --target install

if errorlevel 1 (
    echo.
    echo Install failed!
    cd /d "%SCRIPT_DIR%"
    exit /b 1
)

call :print_success
cd /d "%SCRIPT_DIR%"
goto :end

REM ============================================================================
REM All (build + install)
REM ============================================================================
:all
if not exist "%BUILD_DIR%\CMakeCache.txt" (
    echo Error: Build directory not configured.
    echo.
    echo Run configure-lte-sameproc.bat first.
    exit /b 1
)

echo ========================================
echo Building and Installing OpenUSD v24.11
echo ========================================
echo.
echo Build directory:   %BUILD_DIR%
echo Install directory: %INSTALL_DIR%
echo Build type:        %BUILD_TYPE%
echo Parallel jobs:     %BUILD_JOBS%
echo ========================================
echo.

echo [Step 1/2] Building...
echo.

cd /d "%BUILD_DIR%"
cmake --build . --config %BUILD_TYPE% --parallel %BUILD_JOBS%

if errorlevel 1 (
    echo.
    echo Build failed!
    cd /d "%SCRIPT_DIR%"
    exit /b 1
)

echo.
echo [Step 2/2] Installing...
echo.

cmake --build . --config %BUILD_TYPE% --target install

if errorlevel 1 (
    echo.
    echo Install failed!
    cd /d "%SCRIPT_DIR%"
    exit /b 1
)

call :print_success
cd /d "%SCRIPT_DIR%"
goto :end

REM ============================================================================
REM Helper functions
REM ============================================================================

:print_success
REM Get Python path from CMakeCache
for /f "tokens=2 delims==" %%i in ('findstr "Python3_EXECUTABLE" "%BUILD_DIR%\CMakeCache.txt" 2^>nul') do (
    for %%j in ("%%i") do set UV_PYTHON_DIR=%%~dpj
    set UV_PYTHON_DIR=!UV_PYTHON_DIR:~0,-1!
)

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
echo   set PATH=%INSTALL_DIR%\bin;%INSTALL_DIR%\lib;%TBB_ROOT%\bin;%%PATH%%
echo   set PYTHONPATH=%INSTALL_DIR%\lib\python;%%PYTHONPATH%%
echo ========================================
goto :eof

:end
endlocal
