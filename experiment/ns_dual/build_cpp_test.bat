@echo off
REM Build C++ dual namespace test with Visual Studio 2022
REM Creates executables linked with ordinary USD and custom USD separately

setlocal enabledelayedexpansion

REM Set paths
set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%
set REPO_ROOT=%SCRIPT_DIR%\..\..

REM USD install directories
set DIST_PXR=%REPO_ROOT%\..\dist-pxrusd
set DIST_LTE=%REPO_ROOT%\..\dist-usd-reldeb
set TBB_DIR=%REPO_ROOT%\..\dist-tbb-reldeb

REM uv Python for DLLs and includes
set UV_PYTHON_DIR=%USERPROFILE%\AppData\Roaming\uv\python\cpython-3.11.14-windows-x86_64-none
set UV_PYTHON_INCLUDE=%UV_PYTHON_DIR%\include

REM Output directory
set OUT_DIR=%SCRIPT_DIR%\build
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

echo ========================================
echo Building C++ USD Tests (VS2022)
echo ========================================
echo Ordinary USD: %DIST_PXR%
echo Custom USD:   %DIST_LTE%
echo TBB:          %TBB_DIR%
echo Output:       %OUT_DIR%
echo ========================================
echo.

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

echo.
echo [Build 1] Info test (no USD linking)
echo ----------------------------------------
cl /nologo /EHsc /std:c++17 ^
    /Fo"%OUT_DIR%\test_cpp_info.obj" ^
    /Fe"%OUT_DIR%\test_cpp_info.exe" ^
    "%SCRIPT_DIR%\test_cpp_dual_namespace.cpp"

if errorlevel 1 (
    echo Build 1 failed
) else (
    echo Build 1 succeeded: %OUT_DIR%\test_cpp_info.exe
)

echo.
echo ========================================
echo [Build 2] Ordinary USD (pxr namespace)
echo ========================================

if not exist "%DIST_PXR%\include\pxr\pxr.h" (
    echo Skipping: Ordinary USD not found at %DIST_PXR%
    goto :build_custom
)

REM Disable TBB auto-linking and prevent Windows min/max macro conflicts
set CXX_FLAGS=/EHsc /std:c++17 /MD /D__TBB_NO_IMPLICIT_LINKAGE /DNOMINMAX /D_USE_MATH_DEFINES

REM Compile
cl /nologo %CXX_FLAGS% ^
    /I"%DIST_PXR%\include" ^
    /I"%DIST_PXR%\include\boost-1_78" ^
    /I"%UV_PYTHON_INCLUDE%" ^
    /Fo"%OUT_DIR%\test_usd_pxr.obj" ^
    /c "%SCRIPT_DIR%\test_usd_single.cpp"

if errorlevel 1 (
    echo Compile failed for ordinary USD
    goto :build_custom
)

REM Link (requires Python lib for usd_tf, usd_boost/usd_python for Boost.Python)
set UV_PYTHON_LIBS=%UV_PYTHON_DIR%\libs
link /nologo ^
    /OUT:"%OUT_DIR%\test_usd_pxr.exe" ^
    /LIBPATH:"%DIST_PXR%\lib" ^
    /LIBPATH:"%UV_PYTHON_LIBS%" ^
    "%OUT_DIR%\test_usd_pxr.obj" ^
    usd_tf.lib usd_sdf.lib usd_usd.lib usd_vt.lib usd_arch.lib usd_gf.lib usd_trace.lib usd_work.lib usd_plug.lib usd_ar.lib usd_boost.lib usd_python.lib ^
    python311.lib tbb.lib

if errorlevel 1 (
    echo Link failed for ordinary USD
) else (
    echo Build 2 succeeded: %OUT_DIR%\test_usd_pxr.exe
    echo.
    echo Running test with ordinary USD...
    set "PATH=%UV_PYTHON_DIR%;%DIST_PXR%\bin;%DIST_PXR%\lib;%PATH%"
    set "PXR_PLUGINPATH_NAME=%DIST_PXR%\lib\usd"
    "%OUT_DIR%\test_usd_pxr.exe"
)

:build_custom
echo.
echo ========================================
echo [Build 3] Custom USD (pxr_lte namespace)
echo ========================================

if not exist "%DIST_LTE%\include\pxr\pxr.h" (
    echo Skipping: Custom USD not found at %DIST_LTE%
    goto :summary
)

REM Compile
cl /nologo %CXX_FLAGS% ^
    /I"%DIST_LTE%\include" ^
    /I"%TBB_DIR%\include" ^
    /I"%UV_PYTHON_INCLUDE%" ^
    /Fo"%OUT_DIR%\test_usd_lte.obj" ^
    /c "%SCRIPT_DIR%\test_usd_single.cpp"

if errorlevel 1 (
    echo Compile failed for custom USD
    goto :summary
)

REM Link - custom build uses same usd_ prefix (pxr_lte is internal namespace only)
link /nologo ^
    /OUT:"%OUT_DIR%\test_usd_lte.exe" ^
    /LIBPATH:"%DIST_LTE%\lib" ^
    /LIBPATH:"%TBB_DIR%\lib" ^
    /LIBPATH:"%UV_PYTHON_LIBS%" ^
    "%OUT_DIR%\test_usd_lte.obj" ^
    usd_tf.lib usd_sdf.lib usd_usd.lib usd_vt.lib usd_arch.lib usd_gf.lib usd_trace.lib usd_work.lib usd_plug.lib usd_ar.lib usd_boost.lib usd_python.lib ^
    python311.lib tbb.lib

if errorlevel 1 (
    echo Link failed for custom USD
) else (
    echo Build 3 succeeded: %OUT_DIR%\test_usd_lte.exe
    echo.
    echo Running test with custom USD...
    set "PATH=%UV_PYTHON_DIR%;%DIST_LTE%\bin;%DIST_LTE%\lib;%TBB_DIR%\bin;%PATH%"
    set "PXR_PLUGINPATH_NAME=%DIST_LTE%\lib\usd"
    "%OUT_DIR%\test_usd_lte.exe"
)

:summary
echo.
echo ========================================
echo Build Summary
echo ========================================
echo.
if exist "%OUT_DIR%\test_cpp_info.exe" echo [OK] test_cpp_info.exe - Info test
if exist "%OUT_DIR%\test_usd_pxr.exe" echo [OK] test_usd_pxr.exe  - Ordinary USD (pxr)
if exist "%OUT_DIR%\test_usd_lte.exe" echo [OK] test_usd_lte.exe  - Custom USD (pxr_lte)
echo.
echo ========================================

endlocal
