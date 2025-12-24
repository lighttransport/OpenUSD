@echo off
REM OpenUSD Build and Install Script
REM Builds the configured OpenUSD project

setlocal

REM Set paths
set SOURCE_DIR=%~dp0
set BUILD_DIR=%SOURCE_DIR%build-reldeb
set INSTALL_DIR=%SOURCE_DIR%..\dist-usd-reldeb

REM Check if build directory exists
if not exist "%BUILD_DIR%" (
    echo ========================================
    echo Build directory does not exist!
    echo Please run build-ns-configure.bat first
    echo ========================================
    exit /b 1
)

REM Change to build directory
cd /d "%BUILD_DIR%"

echo ========================================
echo Building OpenUSD
echo ========================================
echo Build directory: %BUILD_DIR%
echo Install directory: %INSTALL_DIR%
echo Build Type: RelWithDebInfo
echo Using %NUMBER_OF_PROCESSORS% parallel jobs
echo ========================================

REM Build and install
cmake --build . --config RelWithDebInfo --target install -j %NUMBER_OF_PROCESSORS%

if errorlevel 1 (
    echo ========================================
    echo Build failed!
    echo ========================================
    exit /b 1
)

echo ========================================
echo Build and install completed successfully!
echo Install location: %INSTALL_DIR%
echo ========================================

endlocal
