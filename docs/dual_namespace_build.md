# Dual Namespace USD Build Guide

This document describes how to build OpenUSD with a custom namespace to enable loading two different USD builds in the same process (same-process dual USD).

## Overview

By default, OpenUSD uses the `pxr` namespace for C++ and Python. When you need to load two different versions or configurations of USD in the same process, namespace conflicts prevent this. The solution is to build one USD installation with a custom namespace.

### Use Cases

- Loading a production USD alongside a development/experimental USD
- Using USD from a DCC application while also using a custom USD build
- Testing USD changes without affecting the system USD installation
- Running two different USD versions side-by-side for comparison
- Using pip-installed USD (`pxr`) alongside a custom-built USD (`pxr_lte`)

## Configuration Options

OpenUSD provides several CMake options for namespace customization:

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `PXR_SET_EXTERNAL_NAMESPACE` | C++ namespace name | `pxr` | `pxr_lte` |
| `PXR_LIB_PREFIX` | Library file prefix | `usd_` | `lte_` |
| `PXR_PYTHON_PACKAGE_NAME` | Python package name | `pxr` | `pxr_lte` |

### Example Configuration

For a custom "lte" (lightweight) build:

```
C++ namespace:    pxr_lte
Library prefix:   lte_
Python package:   pxr_lte
```

This allows:
```python
from pxr import Usd as StandardUsd      # Standard USD
from pxr_lte import Usd as CustomUsd    # Custom build
```

## Build Procedure

### Prerequisites

- Visual Studio 2022 (Windows) or GCC/Clang (Linux/macOS)
- CMake 3.20+
- Python 3.10+ with development headers
- TBB (Threading Building Blocks)

### Windows Build

#### Using the Batch Script

Use the provided batch script:

```batch
build-lte-sameproc.bat
```

#### Manual CMake Configuration

```batch
mkdir build-lte
cd build-lte

cmake .. ^
    -G "Visual Studio 17 2022" ^
    -A x64 ^
    -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
    -DCMAKE_INSTALL_PREFIX=C:/path/to/dist-usd-lte ^
    -DPXR_ENABLE_PYTHON_SUPPORT=ON ^
    -DPXR_ENABLE_NAMESPACES=ON ^
    -DPXR_SET_EXTERNAL_NAMESPACE=pxr_lte ^
    -DPXR_LIB_PREFIX=lte_ ^
    -DPXR_PYTHON_PACKAGE_NAME=pxr_lte ^
    -DPXR_BUILD_IMAGING=OFF ^
    -DPXR_BUILD_USD_IMAGING=OFF ^
    -DPXR_BUILD_USDVIEW=OFF ^
    -DPXR_BUILD_TESTS=OFF ^
    -DPXR_BUILD_EXAMPLES=OFF ^
    -DPXR_BUILD_TUTORIALS=OFF ^
    -DPXR_ENABLE_MATERIALX_SUPPORT=OFF ^
    -DTBB_ROOT_DIR=C:/path/to/tbb ^
    path/to/OpenUSD/source

cmake --build . --config RelWithDebInfo --parallel
cmake --build . --config RelWithDebInfo --target install
```

### Linux/macOS Build

```bash
mkdir build-lte
cd build-lte

cmake \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=/path/to/dist-usd-lte \
    -DPXR_ENABLE_PYTHON_SUPPORT=ON \
    -DPXR_ENABLE_NAMESPACES=ON \
    -DPXR_SET_EXTERNAL_NAMESPACE=pxr_lte \
    -DPXR_LIB_PREFIX=lte_ \
    -DPXR_PYTHON_PACKAGE_NAME=pxr_lte \
    -DPXR_BUILD_IMAGING=OFF \
    -DPXR_BUILD_USD_IMAGING=OFF \
    -DPXR_BUILD_USDVIEW=OFF \
    -DPXR_BUILD_TESTS=OFF \
    -DPXR_BUILD_EXAMPLES=OFF \
    -DPXR_BUILD_TUTORIALS=OFF \
    -DPXR_ENABLE_MATERIALX_SUPPORT=OFF \
    path/to/OpenUSD/source

cmake --build . --parallel $(nproc)
cmake --build . --target install
```

## Installation Layout

After installation, you'll have:

```
<install_dir>/
├── bin/
│   ├── usdcat.exe
│   ├── usdtree.exe
│   └── ...
├── lib/
│   ├── lte_arch.dll       # Note: lte_ prefix
│   ├── lte_tf.dll
│   ├── lte_usd.dll
│   ├── ...
│   ├── python/
│   │   └── pxr_lte/       # Note: pxr_lte package
│   │       ├── __init__.py
│   │       ├── Usd/
│   │       ├── Sdf/
│   │       └── ...
│   └── usd/
│       └── plugInfo.json
├── include/
│   └── pxr/
│       └── ...
└── plugin/
    └── usd/
        └── plugInfo.json
```

## Usage

### Python Import (Windows)

```python
import sys
import os

# Add DLL directories (Windows Python 3.8+)
# IMPORTANT: Add both lib and bin directories
os.add_dll_directory(r'C:\path\to\dist-usd-lte\lib')
os.add_dll_directory(r'C:\path\to\dist-usd-lte\bin')
os.add_dll_directory(r'C:\path\to\tbb\bin')

# Add Python path
sys.path.insert(0, r'C:\path\to\dist-usd-lte\lib\python')

# Import custom namespace USD
from pxr_lte import Usd, Sdf, Tf

# Check version
print('USD version:', Usd.GetVersion())
```

### Same-Process Dual USD

You can import both standard USD and custom namespace USD in the same Python process:

```python
import sys
import os

# Setup DLL paths for custom build (Windows)
os.add_dll_directory(r'C:\path\to\dist-usd-lte\lib')
os.add_dll_directory(r'C:\path\to\dist-usd-lte\bin')
os.add_dll_directory(r'C:\path\to\tbb\bin')

# Add Python path for custom build
sys.path.insert(0, r'C:\path\to\dist-usd-lte\lib\python')

# Import both USD builds
from pxr import Usd as PxrUsd      # Standard/pip-installed USD
from pxr_lte import Usd as LteUsd  # Custom namespace USD

# Verify versions
print('pxr version:', PxrUsd.GetVersion())
print('pxr_lte version:', LteUsd.GetVersion())

# Use them independently
std_stage = PxrUsd.Stage.Open("scene.usda")
custom_stage = LteUsd.Stage.CreateNew("output.usda")
```

### C++ Usage

```cpp
// Standard USD
#include <pxr/usd/usd/stage.h>
namespace pxr_std = pxr;

// Custom namespace USD (requires separate include path)
#define PXR_USE_NAMESPACES 1
#include <pxr_lte/usd/usd/stage.h>
namespace pxr_custom = pxr_lte;

void example() {
    // Use standard USD
    auto stdStage = pxr_std::UsdStage::Open("scene.usda");

    // Use custom USD
    auto customStage = pxr_custom::UsdStage::CreateNew("output.usda");
}
```

## Technical Details

### How It Works

1. **C++ Namespace**: `PXR_SET_EXTERNAL_NAMESPACE` changes the outer namespace wrapping all USD code. Internal symbols use a versioned namespace to prevent ABI conflicts.

2. **Library Prefix**: `PXR_LIB_PREFIX` changes the library file names (e.g., `lte_usd.dll` instead of `usd_usd.dll`), preventing file conflicts and allowing both to be loaded.

3. **Python Package**: `PXR_PYTHON_PACKAGE_NAME` changes:
   - Installation directory (`lib/python/pxr_lte/` instead of `lib/python/pxr/`)
   - Import statements in `__init__.py` files
   - Module registration in C++ `moduleDeps.cpp` files

### What Gets Patched During Build

1. **Python source files** (`__init__.py`, etc.):
   - `from pxr import` → `from pxr_lte import`

2. **C++ moduleDeps.cpp files**:
   - `TfToken("pxr.Tf")` → `TfToken("pxr_lte.Tf")`
   - This ensures `TfScriptModuleLoader` registers modules with the correct package name

### Why moduleDeps.cpp Patching is Needed

The `moduleDeps.cpp` files contain Python module registration that uses the package name:

```cpp
TfScriptModuleLoader::GetInstance().
    RegisterLibrary(TfToken("tf"), TfToken("pxr.Tf"), reqs);
```

Without patching, importing `pxr_lte.Usd` would fail because the loader would look for `pxr.Tf` instead of `pxr_lte.Tf`.

### Modified Files (dev branch)

The following CMake files were modified to support custom Python package names:

- `cmake/defaults/Options.cmake` - Added `PXR_PYTHON_PACKAGE_NAME` option
- `cmake/macros/Private.cmake` - Updated Python file installation paths and added source patching
- `cmake/macros/Public.cmake` - Updated Python package installation paths
- `cmake/macros/moduleDeps.cpp.in` - Template for module registration with configurable package name
- `cmake/macros/genModuleDepsCpp.cmake` - Script to generate moduleDeps.cpp at configure time

### Branch Differences

| Feature | dev branch | v24.11 branch |
|---------|------------|---------------|
| moduleDeps.cpp handling | Template-based generation (`moduleDeps.cpp.in`) | Build-time patching (`patchModuleDeps.py`) |
| Configuration time | Configure time | Build time |
| Additional files | `genModuleDepsCpp.cmake`, `moduleDeps.cpp.in` | `patchModuleDeps.py` |

### Plugin Discovery

USD uses `plugInfo.json` files for plugin discovery. The custom build maintains its own plugin registry. Set `PXR_PLUGINPATH_NAME` environment variable if needed:

```bash
# Linux/macOS
export PXR_PLUGINPATH_NAME=/path/to/custom-usd/lib/usd

# Windows
set PXR_PLUGINPATH_NAME=C:\path\to\custom-usd\lib\usd
```

## Limitations

1. **Memory Usage**: Loading two USD builds doubles memory usage for USD-related data.

2. **Object Incompatibility**: Objects from different builds are incompatible. You cannot pass a `pxr.Usd.Stage` to a function expecting `pxr_lte.Usd.Stage`.

3. **Plugin Conflicts**: Plugins must be built for their respective USD version. A plugin for standard USD won't work with custom namespace USD.

4. **TBB Initialization**: Both builds share TBB. Ensure TBB versions are compatible.

## Troubleshooting

### Import Error: "No module named 'pxr_lte'"

If you see `ModuleNotFoundError: No module named 'pxr_lte'`:
- Verify the Python path includes the custom build's `lib/python` directory
- Check that all files were installed correctly
- Verify the `PXR_PYTHON_PACKAGE_NAME` CMake option was set during build

### Import Error: "No module named 'pxr'" when importing pxr_lte

If you see an error like `ModuleNotFoundError: No module named 'pxr'` when importing `pxr_lte`, it means the Python source files weren't properly patched. Check that:
1. The `PXR_PYTHON_PACKAGE_NAME` CMake option is set
2. The build completed successfully with "Patching __init__.py for custom package name" messages

### Import Error: Module dependency issues (pxr.Tf not found)

If you see errors about missing modules like `pxr.Tf`, it means the moduleDeps.cpp files weren't properly patched. Check that:
1. For dev branch: `moduleDeps.cpp.in` template exists in `cmake/macros/`
2. For v24.11: `patchModuleDeps.py` script exists in `cmake/macros/`
3. The build shows "Patching moduleDeps.cpp for custom package name" messages
4. The generated/patched files contain `pxr_lte.` instead of `pxr.`

### DLL Not Found (Windows)

If you see DLL loading errors:
- Use `os.add_dll_directory()` to add **both** `lib` and `bin` directories
- Ensure TBB DLLs are accessible
- Check that all `lte_*.dll` files are present

```python
import os
os.add_dll_directory(r'C:\path\to\dist-usd-lte\lib')
os.add_dll_directory(r'C:\path\to\dist-usd-lte\bin')
os.add_dll_directory(r'C:\path\to\tbb\bin')
```

### Symbol Conflicts

If you see crashes or strange behavior:
- Ensure both builds use different library prefixes
- Verify namespace configuration is correct
- Check for any shared global state

## Verified Test Results

The following configurations have been tested and verified to work on Windows with Python 3.11:

### Test Environment

- OS: Windows 11
- Python: 3.11.14 (via uv)
- TBB: Pre-built release
- Standard USD: pip `usd-core` 25.11

### Test Results

| Build | USD Version | Standalone Import | Dual Import with pip `pxr` |
|-------|-------------|-------------------|---------------------------|
| dev branch (`pxr_lte`) | 0.25.11 | ✅ PASSED | ✅ PASSED |
| v24.11 branch (`pxr_lte`) | 0.24.11 | ✅ PASSED | ✅ PASSED |

### Same-Process Dual Import Verification

```python
# Both imports work in the same Python process
from pxr import Usd as PxrUsd        # pip usd-core (0.25.11)
from pxr_lte import Usd as LteUsd    # custom build (0.24.11 or 0.25.11)

# Types are correctly different, confirming namespace separation
pxr_stage = PxrUsd.Stage.CreateInMemory()    # type: pxr.Usd.Stage
lte_stage = LteUsd.Stage.CreateInMemory()    # type: pxr_lte.Usd.Stage

# Stages are independent
assert type(pxr_stage) != type(lte_stage)  # True
```

### Tested Modules

The following modules have been verified to import and function correctly in dual-import scenarios:

- `Usd` - Stage creation and prim manipulation
- `Sdf` - Layer creation
- `Tf` - Foundation utilities
- `Gf` - Graphics math (Vec3f, etc.)
- `Vt` - Value types (arrays)

## See Also

- `build-lte-sameproc.bat` - Windows build script
- `experiment/ns_dual/` - Test files for dual namespace usage
- `docs/v24.11_custom_namespace_build.md` - v24.11-specific documentation (on v24.11-custom-namespace branch)
- OpenUSD documentation on namespaces
