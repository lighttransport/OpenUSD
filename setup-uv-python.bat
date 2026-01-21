@echo off
REM Set up a repo-local Python environment using uv and install USD deps.

setlocal enabledelayedexpansion

REM Set paths (remove trailing backslash from SCRIPT_DIR)
set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%
set ROOT_DIR=%SCRIPT_DIR%
set VENV_DIR=%ROOT_DIR%\.venv

REM Python version (can be overridden by setting PYTHON_VERSION env var before running)
if not defined PYTHON_VERSION set PYTHON_VERSION=3.11

REM Python dependencies
set PY_DEPS=jinja2 PySide6 PyOpenGL

REM Check if uv is installed
where uv >nul 2>&1
if errorlevel 1 (
    echo Error: uv is not installed or not on PATH.
    echo Install uv first: https://docs.astral.sh/uv/
    exit /b 1
)

echo ========================================
echo Setting up Python with uv
echo ========================================
echo Python version: %PYTHON_VERSION%
echo Venv: %VENV_DIR%
echo Packages: %PY_DEPS%
echo ========================================

REM Install Python version via uv
uv python install %PYTHON_VERSION%
if errorlevel 1 (
    echo Failed to install Python %PYTHON_VERSION%
    exit /b 1
)

REM Create venv if it doesn't exist
if not exist "%VENV_DIR%" (
    echo Creating virtual environment...
    uv venv --python %PYTHON_VERSION% "%VENV_DIR%"
    if errorlevel 1 (
        echo Failed to create virtual environment
        exit /b 1
    )
) else (
    echo Using existing venv at %VENV_DIR%
)

REM Install dependencies
echo Installing Python packages...
uv pip install --python "%VENV_DIR%\Scripts\python.exe" %PY_DEPS%
if errorlevel 1 (
    echo Failed to install Python packages
    exit /b 1
)

echo.
echo ========================================
echo Python environment ready
echo ========================================
echo To activate: %VENV_DIR%\Scripts\activate.bat
echo ========================================

endlocal
