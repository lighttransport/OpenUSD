@echo off
REM Run ns_dual tests on Windows for USD v24.11
REM Tests custom namespace USD (pxr_lte) and optionally dual import with pip pxr

setlocal enabledelayedexpansion

REM Set paths
set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%

REM uv-installed Python
set UV_PYTHON_DIR=%USERPROFILE%\AppData\Roaming\uv\python\cpython-3.11.14-windows-x86_64-none
set UV_PYTHON=%UV_PYTHON_DIR%\python.exe

REM Check Python
if not exist "%UV_PYTHON%" (
    echo Error: uv-installed Python not found at %UV_PYTHON%
    echo Please install Python 3.11 via uv first:
    echo   uv python install 3.11
    exit /b 1
)

echo ========================================
echo USD v24.11 Custom Namespace Tests
echo ========================================
echo Python: %UV_PYTHON%
echo ========================================
echo.

REM Test 1: pxr_lte only
echo [Test 1] Testing pxr_lte only (custom namespace USD v24.11)
echo ----------------------------------------
"%UV_PYTHON%" "%SCRIPT_DIR%\test_pxr_lte_only.py"
if errorlevel 1 (
    echo.
    echo Test 1 FAILED!
    echo.
    echo Make sure to build USD v24.11 with custom namespace:
    echo   configure-usd-lte.bat
    echo   build-usd-lte.bat all
    exit /b 1
)
echo.

REM Test 2: Dual import (pxr + pxr_lte)
echo ========================================
echo [Test 2] Testing dual import (pxr + pxr_lte)
echo ----------------------------------------
"%UV_PYTHON%" "%SCRIPT_DIR%\test_dual_usd_sameproc.py"
if errorlevel 1 (
    echo.
    echo Test 2 FAILED!
    echo.
    echo Note: Dual import requires pip usd-core to be installed:
    echo   uv pip install usd-core
    exit /b 1
)
echo.

REM Test 3: Setup helper module
echo ========================================
echo [Test 3] Testing pxr_lte_setup helper
echo ----------------------------------------
"%UV_PYTHON%" "%SCRIPT_DIR%\pxr_lte_setup.py"
echo.

echo ========================================
echo All Tests Complete!
echo ========================================

endlocal
