@echo off
REM OpenUSD Runtime Environment Setup Script
REM Sets up PATH and PYTHONPATH for using built USD tools and libraries

setlocal enabledelayedexpansion

REM Set paths (remove trailing backslash from SCRIPT_DIR)
set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%

REM USD install directory
set USD_INSTALL_DIR=%SCRIPT_DIR%\..\dist-usd-reldeb

REM TBB install directory
set TBB_INSTALL_DIR=%SCRIPT_DIR%\..\dist-tbb-reldeb

REM uv-installed Python directory (for python311.dll)
set UV_PYTHON_DIR=%USERPROFILE%\AppData\Roaming\uv\python\cpython-3.11.14-windows-x86_64-none

REM Check if USD is installed
if not exist "%USD_INSTALL_DIR%\bin\usdcat.exe" (
    echo Error: USD not found at %USD_INSTALL_DIR%
    echo Please run the build first.
    exit /b 1
)

REM Check if TBB is installed
if not exist "%TBB_INSTALL_DIR%\bin\tbb.dll" (
    echo Error: TBB not found at %TBB_INSTALL_DIR%
    echo Please run build-tbb-prebuilt.bat first.
    exit /b 1
)

REM Check if Python DLL exists
if not exist "%UV_PYTHON_DIR%\python311.dll" (
    echo Error: Python 3.11 not found at %UV_PYTHON_DIR%
    echo Please run setup-uv-python.bat or setup-rez-python.bat first.
    exit /b 1
)

echo ========================================
echo OpenUSD Runtime Environment
echo ========================================
echo USD: %USD_INSTALL_DIR%
echo TBB: %TBB_INSTALL_DIR%
echo Python: %UV_PYTHON_DIR%
echo Custom Namespace: pxr_lte
echo Build Type: RelWithDebInfo
echo ========================================

REM Set environment variables (use endlocal trick to persist)
endlocal & (
    set "PATH=%UV_PYTHON_DIR%;%USD_INSTALL_DIR%\bin;%USD_INSTALL_DIR%\lib;%TBB_INSTALL_DIR%\bin;%PATH%"
    set "PYTHONPATH=%USD_INSTALL_DIR%\lib\python;%PYTHONPATH%"
    set "PXR_PLUGINPATH_NAME=%USD_INSTALL_DIR%\lib\usd;%USD_INSTALL_DIR%\plugin\usd"
)

echo Environment configured. You can now use USD tools:
echo   usdcat --help
echo   usdtree --help
echo   usdchecker --help
echo.
echo Python bindings available via:
echo   python -c "from pxr import Usd; print('USD loaded')"
echo ========================================
