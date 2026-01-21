@echo off
REM OpenUSD CMake Configuration Script
REM Build Type: RelWithDebInfo
REM Target: ../dist-usd-reldeb
REM Custom Namespace: pxr_lte
REM Features: Python bindings only (minimal build)

setlocal enabledelayedexpansion

REM Set paths (remove trailing backslash from SOURCE_DIR)
set SOURCE_DIR=%~dp0
set SOURCE_DIR=%SOURCE_DIR:~0,-1%
set BUILD_DIR=%SOURCE_DIR%\build-reldeb
set INSTALL_DIR=%SOURCE_DIR%\..\dist-usd-reldeb
set TBB_ROOT=%SOURCE_DIR%\..\dist-tbb-reldeb

REM Create build directory if it doesn't exist
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

REM Set TBB environment variable for FindTBB module
set TBB_INSTALL_DIR=%TBB_ROOT%

REM Detect Python executable (prefer rez/uv venv Python over system Python)
set PYTHON_EXECUTABLE=
REM Check for rez usd-python-venv first
if exist "%SOURCE_DIR%\.rez\usd-python-venv\Scripts\python.exe" (
    set PYTHON_EXECUTABLE=%SOURCE_DIR%\.rez\usd-python-venv\Scripts\python.exe
)
REM Check for uv .venv second
if "%PYTHON_EXECUTABLE%"=="" if exist "%SOURCE_DIR%\.venv\Scripts\python.exe" (
    set PYTHON_EXECUTABLE=%SOURCE_DIR%\.venv\Scripts\python.exe
)
REM Fall back to system Python
if "%PYTHON_EXECUTABLE%"=="" (
    for /f "delims=" %%i in ('where python 2^>nul') do (
        if "!PYTHON_EXECUTABLE!"=="" set PYTHON_EXECUTABLE=%%i
    )
)

REM Change to build directory
cd /d "%BUILD_DIR%"

echo ========================================
echo Configuring OpenUSD with CMake
echo ========================================
echo Source: %SOURCE_DIR%
echo Build: %BUILD_DIR%
echo Install: %INSTALL_DIR%
echo TBB: %TBB_ROOT%
echo Python: %PYTHON_EXECUTABLE%
echo Build Type: RelWithDebInfo
echo Custom Namespace: pxr_lte
echo ========================================

REM Configure with CMake
cmake ^
    -G "Visual Studio 17 2022" -A x64 ^
    -DCMAKE_INSTALL_PREFIX="%INSTALL_DIR%" ^
    -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
    -DPython3_EXECUTABLE="%PYTHON_EXECUTABLE%" ^
    -DTBB_ROOT_DIR="%TBB_ROOT%" ^
    -DPXR_SET_EXTERNAL_NAMESPACE=pxr_lte ^
    -DPXR_ENABLE_PYTHON_SUPPORT=ON ^
    -DPXR_USE_DEBUG_PYTHON=OFF ^
    -DBUILD_SHARED_LIBS=ON ^
    -DTBB_USE_DEBUG_BUILD=OFF ^
    -DPXR_BUILD_TESTS=OFF ^
    -DPXR_BUILD_EXAMPLES=OFF ^
    -DPXR_BUILD_TUTORIALS=OFF ^
    -DPXR_BUILD_DOCUMENTATION=OFF ^
    -DPXR_BUILD_USD_TOOLS=ON ^
    -DPXR_BUILD_IMAGING=OFF ^
    -DPXR_BUILD_USD_IMAGING=OFF ^
    -DPXR_BUILD_USDVIEW=OFF ^
    -DPXR_BUILD_ALEMBIC_PLUGIN=OFF ^
    -DPXR_BUILD_DRACO_PLUGIN=OFF ^
    -DPXR_ENABLE_MATERIALX_SUPPORT=OFF ^
    -DPXR_ENABLE_PTEX_SUPPORT=OFF ^
    -DPXR_ENABLE_OPENVDB_SUPPORT=OFF ^
    -DPXR_BUILD_OPENIMAGEIO_PLUGIN=OFF ^
    -DPXR_BUILD_OPENCOLORIO_PLUGIN=OFF ^
    -DPXR_BUILD_EMBREE_PLUGIN=OFF ^
    -DPXR_ENABLE_VULKAN_SUPPORT=OFF ^
    -DCMAKE_CXX_FLAGS="/Zm150 /D__TBB_NO_IMPLICIT_LINKAGE" ^
    "%SOURCE_DIR%"

if errorlevel 1 (
    echo ========================================
    echo CMake configuration failed!
    echo ========================================
    exit /b 1
)

echo ========================================
echo CMake configuration completed successfully!
echo Build directory: %BUILD_DIR%
echo To build, run: build-ns-build.bat
echo ========================================

endlocal
