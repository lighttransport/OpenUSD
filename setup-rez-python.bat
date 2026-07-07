@echo off
REM Set up a repo-local Python environment using rez and install USD deps.
REM Uses uv-installed Python 3.11
REM
REM This script creates a rez-managed Python environment with USD dependencies
REM for building OpenUSD v26.05 with custom namespace support.
REM
REM Prerequisites:
REM   - uv (https://docs.astral.sh/uv/)
REM   - Python 3.11 installed via uv
REM
REM Usage:
REM   setup-rez-python.bat
REM
REM After running, activate rez with:
REM   .rez\activate.bat

setlocal enabledelayedexpansion

REM Set paths (remove trailing backslash from SCRIPT_DIR)
set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%
set ROOT_DIR=%SCRIPT_DIR%
set REZ_DIR=%ROOT_DIR%\.rez
set REZ_PACKAGES_DIR=%ROOT_DIR%\.rez-packages
set REZ_LOCAL_PACKAGES_DIR=%ROOT_DIR%\.rez-packages\local

REM Check if uv is installed
where uv >nul 2>&1
if errorlevel 1 (
    echo Error: uv is not installed or not on PATH.
    echo Install uv first: https://docs.astral.sh/uv/
    exit /b 1
)

REM Use uv-installed Python 3.11
set UV_PYTHON_DIR=%USERPROFILE%\AppData\Roaming\uv\python\cpython-3.11.14-windows-x86_64-none
set UV_PYTHON=%UV_PYTHON_DIR%\python.exe

REM Python dependencies for USD v26.05
set PY_DEPS=jinja2 PySide6 PyOpenGL

echo ========================================
echo Setting up Python with rez (v26.05)
echo ========================================
echo Python: %UV_PYTHON%
echo Rez install: %REZ_DIR%
echo Rez packages: %REZ_PACKAGES_DIR%
echo USD deps: %PY_DEPS%
echo ========================================

REM Check if uv-installed Python exists
if not exist "%UV_PYTHON%" (
    echo Error: uv-installed Python 3.11 not found at %UV_PYTHON%
    echo.
    echo Please install Python 3.11 via uv first:
    echo   uv python install 3.11
    echo.
    exit /b 1
)

REM Create directories
if not exist "%REZ_DIR%" mkdir "%REZ_DIR%"
if not exist "%REZ_PACKAGES_DIR%" mkdir "%REZ_PACKAGES_DIR%"
if not exist "%REZ_LOCAL_PACKAGES_DIR%" mkdir "%REZ_LOCAL_PACKAGES_DIR%"

REM Create a venv for rez installation
set REZ_VENV=%REZ_DIR%\venv
if not exist "%REZ_VENV%" (
    echo Creating rez virtual environment...
    "%UV_PYTHON%" -m venv "%REZ_VENV%"
    if errorlevel 1 (
        echo Failed to create rez virtual environment
        exit /b 1
    )
)

REM Install rez into the venv
echo Installing rez...
"%REZ_VENV%\Scripts\python.exe" -m pip install --upgrade pip >nul 2>&1
"%REZ_VENV%\Scripts\python.exe" -m pip install rez
if errorlevel 1 (
    echo Failed to install rez
    exit /b 1
)

REM Set rez paths for this session
set PATH=%REZ_VENV%\Scripts;%PATH%
set REZ_CONFIG_FILE=%REZ_DIR%\rezconfig.py

REM Create rez configuration file
echo Creating rez configuration...
(
echo # Rez configuration for OpenUSD v26.05
echo import os
echo.
echo # Package search paths
echo packages_path = [
echo     os.path.expandvars^(r"%REZ_LOCAL_PACKAGES_DIR%"^),
echo     os.path.expandvars^(r"%REZ_PACKAGES_DIR%"^),
echo ]
echo.
echo # Local packages path ^(where rez-build installs to^)
echo local_packages_path = os.path.expandvars^(r"%REZ_LOCAL_PACKAGES_DIR%"^)
echo.
echo # Release packages path
echo release_packages_path = os.path.expandvars^(r"%REZ_PACKAGES_DIR%"^)
echo.
echo # Use the uv-installed Python as default
echo default_python_version = "3.11"
echo.
echo # Use cmd shell on Windows ^(avoid PowerShell execution policy issues^)
echo default_shell = "cmd"
) > "%REZ_CONFIG_FILE%"

REM Create Python 3.11 rez package
echo Creating Python 3.11 rez package...
set PYTHON_PKG_DIR=%REZ_LOCAL_PACKAGES_DIR%\python\3.11.14
if not exist "%PYTHON_PKG_DIR%" mkdir "%PYTHON_PKG_DIR%"

(
echo name = "python"
echo version = "3.11.14"
echo.
echo description = "Python 3.11.14 installed via uv"
echo.
echo tools = [
echo     "python",
echo     "python3",
echo     "pip",
echo ]
echo.
echo def commands^(^):
echo     import os
echo     env.PATH.prepend^(r"%UV_PYTHON_DIR%"^)
echo     env.PATH.prepend^(r"%UV_PYTHON_DIR%\Scripts"^)
echo     env.PYTHONHOME = r"%UV_PYTHON_DIR%"
) > "%PYTHON_PKG_DIR%\package.py"

REM Create pip-installed packages as rez packages
echo Creating USD dependency rez packages...

REM Create jinja2 package
set JINJA2_PKG_DIR=%REZ_LOCAL_PACKAGES_DIR%\jinja2\3.1
if not exist "%JINJA2_PKG_DIR%" mkdir "%JINJA2_PKG_DIR%"
(
echo name = "jinja2"
echo version = "3.1"
echo.
echo description = "Jinja2 templating engine"
echo.
echo requires = ["python-3.11+"]
echo.
echo def commands^(^):
echo     import os
echo     # Use pip to ensure jinja2 is available
echo     pass
) > "%JINJA2_PKG_DIR%\package.py"

REM Create PySide6 package
set PYSIDE6_PKG_DIR=%REZ_LOCAL_PACKAGES_DIR%\pyside6\6.10
if not exist "%PYSIDE6_PKG_DIR%" mkdir "%PYSIDE6_PKG_DIR%"
(
echo name = "pyside6"
echo version = "6.10"
echo.
echo description = "Qt for Python"
echo.
echo requires = ["python-3.11+"]
echo.
echo def commands^(^):
echo     pass
) > "%PYSIDE6_PKG_DIR%\package.py"

REM Create PyOpenGL package
set PYOPENGL_PKG_DIR=%REZ_LOCAL_PACKAGES_DIR%\pyopengl\3.1
if not exist "%PYOPENGL_PKG_DIR%" mkdir "%PYOPENGL_PKG_DIR%"
(
echo name = "pyopengl"
echo version = "3.1"
echo.
echo description = "OpenGL bindings for Python"
echo.
echo requires = ["python-3.11+"]
echo.
echo def commands^(^):
echo     pass
) > "%PYOPENGL_PKG_DIR%\package.py"

REM Create usd_deps meta-package that includes all dependencies
echo Creating usd_deps meta-package...
set USD_DEPS_PKG_DIR=%REZ_LOCAL_PACKAGES_DIR%\usd_deps\1.0
if not exist "%USD_DEPS_PKG_DIR%" mkdir "%USD_DEPS_PKG_DIR%"
(
echo name = "usd_deps"
echo version = "1.0"
echo.
echo description = "Meta-package for OpenUSD v26.05 Python dependencies"
echo.
echo requires = [
echo     "python-3.11+",
echo     "jinja2-3.1+",
echo     "pyside6-6+",
echo     "pyopengl-3+",
echo ]
echo.
echo def commands^(^):
echo     import os
echo     # Ensure pip packages are installed in the python environment
echo     env.USD_DEPS_LOADED = "1"
) > "%USD_DEPS_PKG_DIR%\package.py"

REM Create a venv for USD Python packages (separate from rez venv)
set USD_PYTHON_VENV=%REZ_DIR%\usd-python-venv
if not exist "%USD_PYTHON_VENV%" (
    echo Creating USD Python virtual environment...
    uv venv --python 3.11 "%USD_PYTHON_VENV%"
    if errorlevel 1 (
        echo Failed to create USD Python venv
        exit /b 1
    )
)

REM Install the pip packages into the USD Python venv using uv
echo Installing pip packages into USD Python venv...
uv pip install --python "%USD_PYTHON_VENV%\Scripts\python.exe" %PY_DEPS%
if errorlevel 1 (
    echo Failed to install pip packages
    exit /b 1
)

REM Update Python package to point to the venv
echo Updating Python rez package to use USD venv...
(
echo name = "python"
echo version = "3.11.14"
echo.
echo description = "Python 3.11.14 with USD dependencies ^(via uv venv^)"
echo.
echo tools = [
echo     "python",
echo     "python3",
echo     "pip",
echo ]
echo.
echo def commands^(^):
echo     import os
echo     # Add uv Python directory for python311.dll
echo     uv_python_dir = os.path.join^(os.environ.get^('USERPROFILE', ''^), 'AppData', 'Roaming', 'uv', 'python', 'cpython-3.11.14-windows-x86_64-none'^)
echo     env.PATH.prepend^(uv_python_dir^)
echo     env.PATH.prepend^(r"%USD_PYTHON_VENV%\Scripts"^)
echo     env.VIRTUAL_ENV = r"%USD_PYTHON_VENV%"
) > "%PYTHON_PKG_DIR%\package.py"

REM Create activation script
echo Creating activation script...
set ACTIVATE_SCRIPT=%REZ_DIR%\activate.bat
(
echo @echo off
echo REM Activate rez environment for OpenUSD v26.05
echo REM Include uv-installed Python path for DLLs
echo set UV_PYTHON_DIR=%%USERPROFILE%%\AppData\Roaming\uv\python\cpython-3.11.14-windows-x86_64-none
echo set PATH=%%UV_PYTHON_DIR%%;%REZ_VENV%\Scripts;%%PATH%%
echo set REZ_CONFIG_FILE=%REZ_CONFIG_FILE%
echo echo Rez environment activated for OpenUSD v26.05.
echo echo.
echo echo Available commands:
echo echo   rez-env python        - Enter Python environment
echo echo   rez-env usd_deps      - Enter USD deps environment
echo echo   rez-search            - List available packages
echo echo   rez-context           - Show current environment
) > "%ACTIVATE_SCRIPT%"

REM Create pxr_lte rez package placeholder
echo Creating pxr_lte rez package placeholder...
set PXR_LTE_PKG_DIR=%REZ_LOCAL_PACKAGES_DIR%\pxr_lte\26.05
if not exist "%PXR_LTE_PKG_DIR%" mkdir "%PXR_LTE_PKG_DIR%"
(
echo name = "pxr_lte"
echo version = "26.05"
echo.
echo description = "OpenUSD v26.05 with custom namespace ^(pxr_lte^)"
echo.
echo requires = [
echo     "python-3.11+",
echo ]
echo.
echo def commands^(^):
echo     import os
echo     # Set paths to pxr_lte installation
echo     usd_lte_dir = os.path.join^(os.path.dirname^(os.path.dirname^(os.path.dirname^(os.path.dirname^(this.root^)^)^)^), 'dist-usd-lte-v26.05'^)
echo     tbb_dir = os.path.join^(os.path.dirname^(os.path.dirname^(os.path.dirname^(os.path.dirname^(this.root^)^)^)^), 'dist-tbb-reldeb'^)
echo.
echo     env.PATH.prepend^(os.path.join^(usd_lte_dir, 'bin'^)^)
echo     env.PATH.prepend^(os.path.join^(usd_lte_dir, 'lib'^)^)
echo     env.PATH.prepend^(os.path.join^(tbb_dir, 'bin'^)^)
echo     env.PYTHONPATH.prepend^(os.path.join^(usd_lte_dir, 'lib', 'python'^)^)
echo     env.PXR_PLUGINPATH_NAME = os.path.join^(usd_lte_dir, 'lib', 'usd'^)
) > "%PXR_LTE_PKG_DIR%\package.py"

echo.
echo ========================================
echo Rez environment ready for OpenUSD v26.05
echo ========================================
echo.
echo To activate rez:
echo   %ACTIVATE_SCRIPT%
echo.
echo Then use:
echo   rez-env python            ^(Python 3.11 environment^)
echo   rez-env usd_deps          ^(All USD Python deps^)
echo   rez-env pxr_lte           ^(pxr_lte v26.05 environment^)
echo   rez-env python jinja2     ^(Multiple packages^)
echo.
echo Rez packages created:
echo   - python-3.11.14
echo   - jinja2-3.1
echo   - pyside6-6.10
echo   - pyopengl-3.1
echo   - usd_deps-1.0 ^(meta-package^)
echo   - pxr_lte-26.05 ^(requires building USD first^)
echo.
echo Build USD v26.05 with:
echo   build-lte-sameproc.bat
echo.
echo ========================================

endlocal
