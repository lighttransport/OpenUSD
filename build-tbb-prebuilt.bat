@echo off
REM Intel TBB 2020.3 Prebuilt Binaries Download and Install Script
REM This uses the prebuilt binaries that build_usd.py uses for Windows
REM Install target: ../dist-tbb-reldeb

setlocal enabledelayedexpansion

REM Set paths
set SCRIPT_DIR=%~dp0
set DOWNLOAD_DIR=%SCRIPT_DIR%build-custom\downloads
set INSTALL_DIR=%SCRIPT_DIR%..\dist-tbb-reldeb

REM TBB prebuilt download URL and file
set TBB_VERSION=2020.3
set TBB_URL=https://github.com/oneapi-src/oneTBB/releases/download/v%TBB_VERSION%/tbb-%TBB_VERSION%-win.zip
set TBB_ZIP=tbb-%TBB_VERSION%-win.zip
set TBB_EXTRACTED_DIR=%DOWNLOAD_DIR%\tbb

echo ========================================
echo Intel TBB %TBB_VERSION% Prebuilt Binaries
echo ========================================
echo Version: %TBB_VERSION%
echo Install: %INSTALL_DIR%
echo ========================================

REM Create directories
if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM Download TBB if not already present
if not exist "%DOWNLOAD_DIR%\%TBB_ZIP%" (
    echo Downloading TBB %TBB_VERSION% prebuilt binaries...
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('%TBB_URL%', '%DOWNLOAD_DIR%\%TBB_ZIP%')}"

    if errorlevel 1 (
        echo Failed to download TBB!
        exit /b 1
    )
    echo Download complete.
) else (
    echo TBB archive already exists, skipping download.
)

REM Extract TBB if not already extracted
if not exist "%TBB_EXTRACTED_DIR%" (
    echo Extracting TBB...
    powershell -Command "& {Expand-Archive -Path '%DOWNLOAD_DIR%\%TBB_ZIP%' -DestinationPath '%DOWNLOAD_DIR%' -Force}"

    if errorlevel 1 (
        echo Failed to extract TBB!
        exit /b 1
    )
    echo Extraction complete.
) else (
    echo TBB already extracted, skipping extraction.
)

echo ========================================
echo Installing TBB to %INSTALL_DIR%
echo ========================================

REM Copy binaries
xcopy /E /I /Y "%TBB_EXTRACTED_DIR%\bin\intel64\vc14\*.*" "%INSTALL_DIR%\bin\"
if errorlevel 1 (
    echo Failed to copy binaries!
    exit /b 1
)

REM Copy libraries
xcopy /E /I /Y "%TBB_EXTRACTED_DIR%\lib\intel64\vc14\*.*" "%INSTALL_DIR%\lib\"
if errorlevel 1 (
    echo Failed to copy libraries!
    exit /b 1
)

REM Copy headers
xcopy /E /I /Y "%TBB_EXTRACTED_DIR%\include\*" "%INSTALL_DIR%\include\"
if errorlevel 1 (
    echo Failed to copy headers!
    exit /b 1
)

echo ========================================
echo TBB %TBB_VERSION% installed successfully!
echo Install location: %INSTALL_DIR%
echo ========================================
echo.
echo Contents installed:
echo   - Binaries: %INSTALL_DIR%\bin
echo   - Libraries: %INSTALL_DIR%\lib
echo   - Headers: %INSTALL_DIR%\include
echo.
echo Next step: Run build-ns-configure.bat
echo ========================================

endlocal
