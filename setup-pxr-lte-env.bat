@echo off
REM Setup environment for using pxr_lte (custom namespace USD v26.05)
REM
REM This script sets up PATH and PYTHONPATH for the custom namespace USD build.
REM Run this in a command prompt before using pxr_lte.
REM
REM Usage:
REM   setup-pxr-lte-env.bat
REM   python -c "from pxr_lte import Usd; print(Usd.GetVersion())"

setlocal enabledelayedexpansion

REM ============================================================================
REM Configuration - Modify these paths as needed
REM ============================================================================

set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%

set USD_LTE_DIR=%SCRIPT_DIR%\..\dist-usd-lte-v26.05
set TBB_DIR=%SCRIPT_DIR%\..\dist-tbb-reldeb

REM Python (uv-installed)
set UV_PYTHON_DIR=%USERPROFILE%\AppData\Roaming\uv\python\cpython-3.11.14-windows-x86_64-none

REM ============================================================================
REM Validate paths
REM ============================================================================

if not exist "%USD_LTE_DIR%\lib\python\pxr_lte" (
    echo Error: pxr_lte not found at %USD_LTE_DIR%
    echo Please run build-lte-sameproc.bat first.
    exit /b 1
)

if not exist "%TBB_DIR%\bin" (
    echo Error: TBB not found at %TBB_DIR%
    echo Please run build-tbb.bat first.
    exit /b 1
)

REM ============================================================================
REM Set environment variables
REM ============================================================================

echo Setting up environment for pxr_lte (USD v26.05)...
echo.

endlocal & (
    set "PATH=%UV_PYTHON_DIR%;%USD_LTE_DIR%\bin;%USD_LTE_DIR%\lib;%TBB_DIR%\bin;%PATH%"
    set "PYTHONPATH=%USD_LTE_DIR%\lib\python;%PYTHONPATH%"
)

echo Environment configured:
echo   USD_LTE: %USD_LTE_DIR%
echo   TBB:     %TBB_DIR%
echo   Python:  %UV_PYTHON_DIR%
echo.
echo You can now use pxr_lte in Python:
echo   python -c "from pxr_lte import Usd; print('v26.05:', Usd.GetVersion())"
echo.
echo For same-process dual USD:
echo   python -c "from pxr import Usd as P; from pxr_lte import Usd as L; print('pxr:', P.GetVersion(), 'pxr_lte:', L.GetVersion())"
