@echo off
REM Run ns_dual tests on Windows for USD v26.05 MONOLITHIC build
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
echo USD v26.05 Custom Namespace Tests (MONOLITHIC)
echo ========================================
echo Python: %UV_PYTHON%
echo ========================================
echo.

REM Test 1: pxr_lte only (monolithic)
echo [Test 1] Testing pxr_lte only (custom namespace USD v26.05 MONOLITHIC)
echo ----------------------------------------
"%UV_PYTHON%" "%SCRIPT_DIR%\test_pxr_lte_only_monolithic.py"
if errorlevel 1 (
    echo.
    echo Test 1 FAILED!
    echo.
    echo Make sure to build USD v26.05 with custom namespace monolithic:
    echo   configure-usd-lte-monolithic.bat
    echo   build-usd-lte-monolithic.bat all
    exit /b 1
)
echo.

REM Test 2: Dual import (pxr + pxr_lte monolithic)
echo ========================================
echo [Test 2] Testing dual import (pxr + pxr_lte MONOLITHIC)
echo ----------------------------------------
"%UV_PYTHON%" "%SCRIPT_DIR%\test_dual_usd_sameproc_monolithic.py"
if errorlevel 1 (
    echo.
    echo Test 2 FAILED!
    echo.
    echo Note: Dual import requires pip usd-core to be installed:
    echo   uv pip install usd-core
    exit /b 1
)
echo.

REM Test 3: Setup helper module (monolithic)
echo ========================================
echo [Test 3] Testing pxr_lte_setup_monolithic helper
echo ----------------------------------------
"%UV_PYTHON%" "%SCRIPT_DIR%\pxr_lte_setup_monolithic.py"
echo.

echo ========================================
echo All Tests Complete!
echo ========================================

endlocal
