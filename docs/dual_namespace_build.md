# Dual Namespace USD Build Guide

This document describes how to build OpenUSD with a custom namespace to enable loading two different USD builds in the same process (same-process dual USD).

## Overview

By default, OpenUSD uses the `pxr` namespace for C++ and Python. When you need to load two different versions or configurations of USD in the same process, namespace conflicts prevent this. The solution is to build one USD installation with a custom namespace.

### Use Cases

- Loading a production USD alongside a development/experimental USD
- Using USD from a DCC application while also using a custom USD build
- Testing USD changes without affecting the system USD installation
- Running two different USD versions side-by-side for comparison

## Configuration Options

OpenUSD provides several CMake options for namespace customization:

| Option | Description | Default |
|--------|-------------|---------|
| `PXR_SET_EXTERNAL_NAMESPACE` | C++ namespace name | `pxr` |
| `PXR_LIB_PREFIX` | Library file prefix | `usd_` |
| `PXR_PYTHON_PACKAGE_NAME` | Python package name | `pxr` |

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

## Build Instructions

### Prerequisites

- Visual Studio 2022 (Windows) or GCC/Clang (Linux/macOS)
- CMake 3.20+
- Python 3.10+ with development headers
- TBB (Threading Building Blocks)

### Windows Build

Use the provided batch script:

```batch
build-lte-sameproc.bat
```

Or configure manually:

```batch
cmake -G "Visual Studio 17 2022" -A x64 ^
    -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
    -DCMAKE_INSTALL_PREFIX="C:/path/to/install" ^
    -DPXR_ENABLE_PYTHON_SUPPORT=ON ^
    -DPXR_ENABLE_NAMESPACES=ON ^
    -DPXR_SET_EXTERNAL_NAMESPACE=pxr_lte ^
    -DPXR_LIB_PREFIX=lte_ ^
    -DPXR_PYTHON_PACKAGE_NAME=pxr_lte ^
    -DPXR_BUILD_IMAGING=OFF ^
    -DPXR_BUILD_TESTS=OFF ^
    -DTBB_ROOT_DIR="C:/path/to/tbb" ^
    path/to/OpenUSD/source

cmake --build . --config RelWithDebInfo --parallel
cmake --build . --config RelWithDebInfo --target install
```

### Linux/macOS Build

```bash
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=/path/to/install \
    -DPXR_ENABLE_PYTHON_SUPPORT=ON \
    -DPXR_ENABLE_NAMESPACES=ON \
    -DPXR_SET_EXTERNAL_NAMESPACE=pxr_lte \
    -DPXR_LIB_PREFIX=lte_ \
    -DPXR_PYTHON_PACKAGE_NAME=pxr_lte \
    -DPXR_BUILD_IMAGING=OFF \
    -DPXR_BUILD_TESTS=OFF \
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

### Python Usage

```python
import sys
import os

# Add DLL search paths (Windows)
os.add_dll_directory("C:/path/to/custom-usd/lib")
os.add_dll_directory("C:/path/to/tbb/bin")

# Add Python path
sys.path.insert(0, "C:/path/to/custom-usd/lib/python")

# Import both USD builds
from pxr import Usd as StandardUsd      # Standard/preinstalled USD
from pxr_lte import Usd as CustomUsd    # Custom namespace build

# Use them independently
std_stage = StandardUsd.Stage.Open("scene.usda")
custom_stage = CustomUsd.Stage.CreateNew("output.usda")
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

### Modified Files

The following CMake files were modified to support custom Python package names:

- `cmake/defaults/Options.cmake` - Added `PXR_PYTHON_PACKAGE_NAME` option
- `cmake/macros/Private.cmake` - Updated Python file installation paths and added source patching
- `cmake/macros/Public.cmake` - Updated Python package installation paths
- `cmake/macros/moduleDeps.cpp.in` - Made module registration use configurable package name
- `cmake/macros/genModuleDepsCpp.cmake` - Pass package name to template

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

### Import Errors

If you see `ModuleNotFoundError: No module named 'pxr_lte'`:
- Verify the Python path includes the custom build's `lib/python` directory
- Check that all files were installed correctly

### DLL Not Found (Windows)

If you see DLL loading errors:
- Use `os.add_dll_directory()` to add library paths
- Ensure TBB DLLs are accessible
- Check that all `lte_*.dll` files are present

### Symbol Conflicts

If you see crashes or strange behavior:
- Ensure both builds use different library prefixes
- Verify namespace configuration is correct
- Check for any shared global state

## See Also

- `build-lte-sameproc.bat` - Windows build script
- `experiment/ns_dual/` - Test files for dual namespace usage
- OpenUSD documentation on namespaces
