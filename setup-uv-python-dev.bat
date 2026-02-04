@echo off
REM Setup Python development environment using UV
REM
REM This script ensures Python is installed with development headers
REM (include files and libs) required for building native extensions.
REM
REM Usage:
REM   setup-uv-python-dev.bat [python-version]
REM
REM   python-version - Optional Python version (default: 3.11)
REM
REM Example:
REM   setup-uv-python-dev.bat 3.11
REM   setup-uv-python-dev.bat 3.12

setlocal enabledelayedexpansion

REM ============================================================================
REM Configuration
REM ============================================================================

set PYTHON_VERSION=%1
if "%PYTHON_VERSION%"=="" set PYTHON_VERSION=3.11

REM UV Python install directory
set UV_PYTHON_BASE=%USERPROFILE%\AppData\Roaming\uv\python

echo ========================================
echo UV Python Development Setup
echo ========================================
echo.
echo Python Version: %PYTHON_VERSION%
echo.

REM ============================================================================
REM Check if UV is installed
REM ============================================================================

where uv >nul 2>&1
if errorlevel 1 (
    echo Error: UV is not installed or not in PATH.
    echo.
    echo Install UV using one of these methods:
    echo   powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    echo   pip install uv
    echo   winget install --id=astral-sh.uv -e
    echo.
    exit /b 1
)

echo [1/4] UV found:
uv --version
echo.

REM ============================================================================
REM Install Python with UV
REM ============================================================================

echo [2/4] Installing Python %PYTHON_VERSION% via UV...
echo.

uv python install %PYTHON_VERSION%

if errorlevel 1 (
    echo.
    echo Failed to install Python %PYTHON_VERSION%!
    exit /b 1
)

echo.

REM ============================================================================
REM Find installed Python path
REM ============================================================================

echo [3/4] Locating Python installation...
echo.

REM Look for matching Python version in UV managed directory
set UV_PYTHON_DIR=
for /d %%d in ("%UV_PYTHON_BASE%\cpython-%PYTHON_VERSION%*-windows-x86_64-none") do (
    set UV_PYTHON_DIR=%%d
)

if not defined UV_PYTHON_DIR goto :try_uv_find
set UV_PYTHON_EXE=!UV_PYTHON_DIR!\python.exe
echo Found UV managed Python: !UV_PYTHON_DIR!
goto :found_python

:try_uv_find
REM Fall back to uv python find (may return venv Python)
for /f "tokens=*" %%i in ('uv python find %PYTHON_VERSION% 2^>nul') do (
    set UV_PYTHON_EXE=%%i
)

if not defined UV_PYTHON_EXE (
    echo Error: Could not find Python %PYTHON_VERSION% installation.
    echo.
    echo Installed Pythons:
    uv python list
    exit /b 1
)

REM Get the directory containing python.exe
for %%i in ("!UV_PYTHON_EXE!") do set UV_PYTHON_DIR=%%~dpi
set UV_PYTHON_DIR=!UV_PYTHON_DIR:~0,-1!

:found_python
echo Python executable: !UV_PYTHON_EXE!
echo Python directory:  !UV_PYTHON_DIR!
echo.

REM ============================================================================
REM Verify development files exist
REM ============================================================================

echo [4/4] Verifying development files...
echo.

set UV_PYTHON_INCLUDE=!UV_PYTHON_DIR!\include
set UV_PYTHON_LIBS_DIR=!UV_PYTHON_DIR!\libs

REM Check for include directory and Python.h
if not exist "!UV_PYTHON_INCLUDE!" (
    echo Warning: Include directory not found at !UV_PYTHON_INCLUDE!
    echo.
    echo UV's managed Python may not include development headers.
    echo.
    goto :show_alternatives
)

if not exist "!UV_PYTHON_INCLUDE!\Python.h" (
    echo Warning: Python.h not found in !UV_PYTHON_INCLUDE!
    echo.
    goto :show_alternatives
)

REM Check for libs directory
if not exist "!UV_PYTHON_LIBS_DIR!" (
    echo Warning: Libs directory not found at !UV_PYTHON_LIBS_DIR!
    echo.
    goto :show_alternatives
)

REM Find python3XX.lib
set FOUND_LIB=
for %%f in ("!UV_PYTHON_LIBS_DIR!\python3*.lib") do (
    set FOUND_LIB=%%f
)

if not defined FOUND_LIB (
    echo Warning: Python library .lib not found in !UV_PYTHON_LIBS_DIR!
    echo.
    goto :show_alternatives
)

REM ============================================================================
REM Success - Print configuration
REM ============================================================================

echo.
echo ========================================
echo Python Development Environment Ready!
echo ========================================
echo.
echo Python executable:  !UV_PYTHON_EXE!
echo Include directory:  !UV_PYTHON_INCLUDE!
echo Library file:       !FOUND_LIB!
echo.
echo Add these to your CMake configuration:
echo   -DPython3_EXECUTABLE="!UV_PYTHON_EXE!"
echo   -DPython3_INCLUDE_DIR="!UV_PYTHON_INCLUDE!"
echo   -DPython3_LIBRARY="!FOUND_LIB!"
echo.
echo For configure-lte-sameproc.bat, set these environment variables:
echo.
echo   set UV_PYTHON_DIR=!UV_PYTHON_DIR!
echo   set UV_PYTHON=!UV_PYTHON_EXE!
echo   set UV_PYTHON_INCLUDE=!UV_PYTHON_INCLUDE!
echo   set UV_PYTHON_LIBS=!FOUND_LIB!
echo.
echo Or edit configure-lte-sameproc.bat directly with these paths.
echo ========================================
goto :end

:show_alternatives
echo ========================================
echo Alternative: Install Python from python.org
echo ========================================
echo.
echo UV's standalone Python builds may not include development headers.
echo.
echo Option 1: Install from python.org
echo   1. Download from https://www.python.org/downloads/
echo   2. During installation, check "Customize installation"
echo   3. Ensure "pip" and "py launcher" are checked
echo   4. In Advanced Options, check "Download debugging symbols"
echo      and "Download debug binaries"
echo.
echo Option 2: Use winget (includes dev files)
echo   winget install Python.Python.3.11
echo.
echo Option 3: Use an existing Python with dev files
echo   If you have Python installed elsewhere with include/libs:
echo   - Check C:\Python311 or C:\Program Files\Python311
echo   - Verify include\Python.h and libs\python311.lib exist
echo.
echo After installing Python with dev files, update configure-lte-sameproc.bat
echo with the correct paths.
echo ========================================

:end
endlocal
