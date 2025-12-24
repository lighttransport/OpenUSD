@echo off
REM Setup environment for OpenUSD with custom namespace pxr_lte
REM OpenUSD v25.08 built with RelWithDebInfo

REM edit path fit to you.
set PATH=N:\work\dist-usd-reldeb\lib;N:\work\dist-tbb-reldeb\bin;C:\Users\syoyo\AppData\Roaming\uv\python\cpython-3.11.13-windows-x86_64-none;%PATH%
set PYTHONPATH=N:\work\dist-usd-reldeb\lib\python
set PXR_PLUGINPATH_NAME=N:\work\dist-usd-reldeb\lib\usd

echo ========================================
echo OpenUSD Environment Setup
echo ========================================
echo USD Install: N:\work\dist-usd-reldeb
echo TBB Install: N:\work\dist-tbb-reldeb
echo Custom Namespace: pxr_lte
echo Build Type: RelWithDebInfo
echo ========================================
echo.
echo USD tools are now available:
echo   - usdcat
echo   - usdchecker
echo   - usdedit
echo   - usdGenSchema
echo   - usddiff
echo   And more...
echo.
echo To check USD version:
echo   python -c "from pxr import Usd; print(Usd.GetVersion())"
echo.
echo ========================================
