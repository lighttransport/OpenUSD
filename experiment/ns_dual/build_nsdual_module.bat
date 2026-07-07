@echo off
REM Build nsdual Python extension module
REM Links with custom namespace USD monolithic library (lte_usd_ms.lib)
REM
REM This creates nsdual.pyd that can be imported in Python alongside
REM standard pxr module to test coexistence.

setlocal enabledelayedexpansion

REM Set paths
set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%

REM USD custom namespace MONOLITHIC install directory
set "DIST_LTE=%USERPROFILE%\work\dist-usd-lte-monolithic-v26.05"
set "TBB_DIR=%USERPROFILE%\work\dist-tbb-reldeb"

REM uv Python
set UV_PYTHON_DIR=%USERPROFILE%\AppData\Roaming\uv\python\cpython-3.11.14-windows-x86_64-none
set UV_PYTHON_INCLUDE=%UV_PYTHON_DIR%\include
set UV_PYTHON_LIBS=%UV_PYTHON_DIR%\libs

REM Output directory
set OUT_DIR=%SCRIPT_DIR%\build
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

echo ========================================
echo Building nsdual Python Extension Module
echo ========================================
echo Custom USD: %DIST_LTE%
echo TBB:        %TBB_DIR%
echo Python:     %UV_PYTHON_DIR%
echo Output:     %OUT_DIR%
echo ========================================
echo.

REM Verify paths exist
if not exist "%DIST_LTE%\include\pxr\pxr.h" (
    echo ERROR: Custom USD monolithic not found at %DIST_LTE%
    echo.
    echo Please build USD first:
    echo   configure-lte-monolithic.bat
    echo   build-lte-monolithic.bat all
    exit /b 1
)

if not exist "%DIST_LTE%\lib\lte_usd_ms.lib" (
    echo ERROR: Monolithic library not found at %DIST_LTE%\lib\lte_usd_ms.lib
    exit /b 1
)

if not exist "%TBB_DIR%\include\tbb\tbb.h" (
    echo ERROR: TBB not found at %TBB_DIR%
    exit /b 1
)

if not exist "%UV_PYTHON_INCLUDE%\Python.h" (
    echo ERROR: Python headers not found at %UV_PYTHON_INCLUDE%
    exit /b 1
)

REM Find Visual Studio 2022
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
    echo Error: vswhere.exe not found
    exit /b 1
)

for /f "tokens=*" %%i in ('"%VSWHERE%" -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath') do (
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

REM Compiler flags
set CXX_FLAGS=/EHsc /std:c++17 /MD /O2 /D__TBB_NO_IMPLICIT_LINKAGE /DNOMINMAX /D_USE_MATH_DEFINES

echo.
echo ========================================
echo Compiling nsdual_module.cpp...
echo ========================================

cl /nologo %CXX_FLAGS% ^
    /I"%UV_PYTHON_INCLUDE%" ^
    /I"%DIST_LTE%\include" ^
    /I"%TBB_DIR%\include" ^
    /Fo"%OUT_DIR%\nsdual_module.obj" ^
    /c "%SCRIPT_DIR%\nsdual_module.cpp"

if errorlevel 1 (
    echo Compile failed!
    exit /b 1
)
echo   Compile succeeded.

echo.
echo ========================================
echo Linking nsdual.pyd...
echo ========================================

link /nologo /DLL ^
    /OUT:"%OUT_DIR%\nsdual.pyd" ^
    /LIBPATH:"%UV_PYTHON_LIBS%" ^
    /LIBPATH:"%DIST_LTE%\lib" ^
    /LIBPATH:"%TBB_DIR%\lib" ^
    "%OUT_DIR%\nsdual_module.obj" ^
    python311.lib ^
    lte_usd_ms.lib ^
    tbb.lib

if errorlevel 1 (
    echo Link failed!
    exit /b 1
)
echo   Link succeeded.

echo.
echo ========================================
echo Build Complete
echo ========================================
echo Output: %OUT_DIR%\nsdual.pyd
echo.
echo To test coexistence:
echo   set PATH=%DIST_LTE%\lib;%DIST_LTE%\bin;%TBB_DIR%\bin;%%PATH%%
echo   python test_nsdual_coexist.py
echo ========================================

endlocal
