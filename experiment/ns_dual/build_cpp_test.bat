@echo off
REM Build C++ USD test with Visual Studio 2022 for pxr_lte v24.11
REM Creates executable linked with custom namespace USD

setlocal enabledelayedexpansion

REM Set paths
set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%
set REPO_ROOT=%SCRIPT_DIR%\..\..

REM USD v24.11 custom namespace install directory
set DIST_LTE=%REPO_ROOT%\..\dist-usd-lte-v24.11
set TBB_DIR=%REPO_ROOT%\..\dist-tbb-reldeb

REM uv Python for DLLs and includes
set UV_PYTHON_DIR=%USERPROFILE%\AppData\Roaming\uv\python\cpython-3.11.14-windows-x86_64-none
set UV_PYTHON_INCLUDE=%UV_PYTHON_DIR%\include
set UV_PYTHON_LIBS=%UV_PYTHON_DIR%\libs

REM Output directory
set OUT_DIR=%SCRIPT_DIR%\build
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

echo ========================================
echo Building C++ USD Test (VS2022) - v24.11
echo ========================================
echo Custom USD v24.11: %DIST_LTE%
echo TBB:               %TBB_DIR%
echo Output:            %OUT_DIR%
echo ========================================
echo.

REM Verify paths exist
if not exist "%DIST_LTE%\include\pxr\pxr.h" (
    echo ERROR: Custom USD v24.11 not found at %DIST_LTE%
    echo.
    echo Please build USD v24.11 first:
    echo   configure-usd-lte.bat
    echo   build-usd-lte.bat all
    exit /b 1
)

if not exist "%TBB_DIR%\include\tbb\tbb.h" (
    echo ERROR: TBB not found at %TBB_DIR%
    echo.
    echo Please build TBB first:
    echo   build-tbb.bat
    exit /b 1
)

REM Find Visual Studio 2022
set VSWHERE="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist %VSWHERE% (
    echo Error: vswhere.exe not found
    exit /b 1
)

for /f "tokens=*" %%i in ('%VSWHERE% -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath') do (
    set VS_PATH=%%i
)

if not defined VS_PATH (
    echo Error: Visual Studio 2022 not found
    exit /b 1
)

echo Found Visual Studio: %VS_PATH%

REM Setup VS environment
call "%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
if errorlevel 1 (
    echo Error: Failed to setup Visual Studio environment
    exit /b 1
)

REM Disable TBB auto-linking and prevent Windows min/max macro conflicts
set CXX_FLAGS=/EHsc /std:c++17 /MD /D__TBB_NO_IMPLICIT_LINKAGE /DNOMINMAX /D_USE_MATH_DEFINES

echo.
echo ========================================
echo Building with Custom USD v24.11 (pxr_lte)
echo ========================================

REM Compile
echo.
echo [1/2] Compiling test_usd_single.cpp...
cl /nologo %CXX_FLAGS% ^
    /I"%DIST_LTE%\include" ^
    /I"%TBB_DIR%\include" ^
    /I"%UV_PYTHON_INCLUDE%" ^
    /Fo"%OUT_DIR%\test_usd_lte.obj" ^
    /c "%SCRIPT_DIR%\test_usd_single.cpp"

if errorlevel 1 (
    echo Compile failed!
    exit /b 1
)
echo   Compile succeeded.

REM Link with lte_ prefixed libraries
echo.
echo [2/2] Linking...
link /nologo ^
    /OUT:"%OUT_DIR%\test_usd_lte.exe" ^
    /LIBPATH:"%DIST_LTE%\lib" ^
    /LIBPATH:"%TBB_DIR%\lib" ^
    /LIBPATH:"%UV_PYTHON_LIBS%" ^
    "%OUT_DIR%\test_usd_lte.obj" ^
    lte_tf.lib lte_sdf.lib lte_usd.lib lte_vt.lib lte_arch.lib lte_gf.lib lte_trace.lib lte_work.lib lte_plug.lib lte_ar.lib lte_boost.lib lte_python.lib ^
    python311.lib tbb.lib

if errorlevel 1 (
    echo Link failed!
    echo.
    echo Note: Make sure the custom build uses lte_ library prefix.
    echo Check the libraries in %DIST_LTE%\lib
    exit /b 1
)
echo   Link succeeded.

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo Output: %OUT_DIR%\test_usd_lte.exe
echo.

REM Run the test
echo Running test...
echo ----------------------------------------
set "PATH=%UV_PYTHON_DIR%;%DIST_LTE%\bin;%DIST_LTE%\lib;%TBB_DIR%\bin;%PATH%"
set "PXR_PLUGINPATH_NAME=%DIST_LTE%\lib\usd"
"%OUT_DIR%\test_usd_lte.exe"

if errorlevel 1 (
    echo.
    echo Test failed!
    exit /b 1
)

echo.
echo ========================================
echo All tests passed!
echo ========================================

endlocal
