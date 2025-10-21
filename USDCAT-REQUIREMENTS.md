# Root Cause Analysis: usdcat.exe Silent Exit

## Problem
`usdcat.exe -h` (or `--version`) silently exits with no output when environment is not configured.

## Root Cause
**Exit Code: -1073741515 (0xC0000135) = STATUS_DLL_NOT_FOUND**

The Windows loader cannot find required DLLs, causing the process to terminate immediately before any code executes.

## DLL Dependencies (Analysis via dumpbin)

### Direct Dependencies of usdcat.exe:
```
usd_usdUtils.dll    → N:\work\dist-usd-reldeb\lib
usd_usd.dll         → N:\work\dist-usd-reldeb\lib
usd_sdf.dll         → N:\work\dist-usd-reldeb\lib
usd_tf.dll          → N:\work\dist-usd-reldeb\lib
usd_python.dll      → N:\work\dist-usd-reldeb\lib
python311.dll       → C:\Users\syoyo\AppData\Roaming\uv\python\cpython-3.11.13-windows-x86_64-none
```

### Indirect Dependencies (via usd_tf.dll):
```
tbb12.dll           → N:\work\dist-tbb-reldeb\bin
python311.dll       → (same as above)
```

## Required Environment Variables

### MINIMUM Required (for usdcat to work):
```batch
set PATH=N:\work\dist-usd-reldeb\lib;N:\work\dist-tbb-reldeb\bin;C:\Users\syoyo\AppData\Roaming\uv\python\cpython-3.11.13-windows-x86_64-none;%PATH%
```

### NOT Required (but useful for Python USD programming):
- `PYTHONPATH` - Only needed when importing pxr modules from Python
- `PXR_PLUGINPATH_NAME` - Only needed for custom USD plugins

## Test Results Summary

| PATH Components | Result | Exit Code |
|----------------|--------|-----------|
| None | FAIL | -1073741515 |
| USD lib only | FAIL | -1073741515 |
| USD + TBB | FAIL | -1073741515 |
| USD + Python | FAIL | -1073741515 |
| TBB + Python | FAIL | -1073741515 |
| **USD + TBB + Python** | **SUCCESS** | **0** |

## DLL Dependency Chain

```
usdcat.exe
├── usd_usdUtils.dll ────┐
├── usd_usd.dll          │ All in N:\work\dist-usd-reldeb\lib
├── usd_sdf.dll          │ (requires this dir in PATH)
├── usd_tf.dll ──────────┘
│   ├── tbb12.dll ───────── In N:\work\dist-tbb-reldeb\bin (requires this in PATH)
│   └── python311.dll ──┐
└── python311.dll ───────┴── In C:\Users\syoyo\AppData\Roaming\uv\python\... (requires this in PATH)
```

## Why Silent Exit?

When a Windows executable depends on a DLL that cannot be found:
1. The Windows loader (kernel32.dll) attempts to load the EXE
2. It resolves imports and tries to load required DLLs from PATH
3. If ANY required DLL is missing, the process terminates with STATUS_DLL_NOT_FOUND
4. **No code in usdcat.exe ever executes** - not even main()
5. No error message is printed because the program never started

This is why:
- `usdcat --version` shows nothing
- `usdcat -h` shows nothing
- The process just exits silently

## Solution

**Minimum working setup:**
```batch
set PATH=N:\work\dist-usd-reldeb\lib;N:\work\dist-tbb-reldeb\bin;C:\Users\syoyo\AppData\Roaming\uv\python\cpython-3.11.13-windows-x86_64-none;%PATH%
```

**Recommended setup (for full USD usage):**
```batch
REM Required for all USD tools
set PATH=N:\work\dist-usd-reldeb\lib;N:\work\dist-tbb-reldeb\bin;C:\Users\syoyo\AppData\Roaming\uv\python\cpython-3.11.13-windows-x86_64-none;%PATH%

REM Required for Python USD imports
set PYTHONPATH=N:\work\dist-usd-reldeb\lib\python

REM Required for USD plugins (optional)
set PXR_PLUGINPATH_NAME=N:\work\dist-usd-reldeb\lib\usd
```

## Quick Test
```batch
# Use the provided script
setup-usd-env.bat

# Or minimal test
set PATH=N:\work\dist-usd-reldeb\lib;N:\work\dist-tbb-reldeb\bin;C:\Users\syoyo\AppData\Roaming\uv\python\cpython-3.11.13-windows-x86_64-none;%PATH%
usdcat -h
```
