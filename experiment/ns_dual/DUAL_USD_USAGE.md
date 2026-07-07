# Using Dual USD Builds (Standard pxr + Custom pxr_lte v26.05)

This document explains how to use both the standard USD build (pxr from pip) and the custom namespace USD build (pxr_lte v26.05) simultaneously in the same Python process.

## Build Configurations

### Standard USD (pip usd-core)
- **Namespace**: `pxr` (standard)
- **Library Prefix**: `usd_`
- **Installation**: `pip install usd-core`
- **Libraries**: `_usd.pyd`, `_sdf.pyd`, etc.

### Custom USD v26.05 (`dist-usd-lte-v26.05`)
- **Namespace**: `pxr_lte` (custom external namespace)
- **Internal Namespace**: `pxrInternal_v0_24_11__pxrReserved__`
- **Library Prefix**: `lte_`
- **Location**: `~/work/dist-usd-lte-v26.05`
- **Libraries**: `lte_usd.dll`, `lte_sdf.dll`, etc.

## Key Configuration

The custom build is configured with `pxr_lte` as the external namespace:

```cpp
// From dist-usd-lte-v26.05/include/pxr/pxr.h
#define PXR_NS pxr_lte
#define PXR_INTERNAL_NS pxrInternal_v0_24_11__pxrReserved__

namespace PXR_NS {  // namespace pxr_lte
    using namespace PXR_INTERNAL_NS;
}
```

This means:
- ✅ C++ code compiled against the custom build uses `pxr_lte::` namespace
- ✅ Libraries have different binary names (`lte_*.dll` vs `usd_*.dll`)
- ✅ Python package is `pxr_lte` (no conflict with `pxr`)

## Python Usage

### Same-Process Import (Recommended)

Both USD builds can be loaded in the same Python process:

```python
#!/usr/bin/env python3
import sys
import os

# Setup DLL paths for custom build (Windows)
CUSTOM_USD_ROOT = os.path.expandvars(r"$USERPROFILE\work\dist-usd-lte-v26.05")
TBB_ROOT = os.path.expandvars(r"$USERPROFILE\work\dist-tbb-reldeb")

os.add_dll_directory(os.path.join(CUSTOM_USD_ROOT, "lib"))
os.add_dll_directory(os.path.join(CUSTOM_USD_ROOT, "bin"))
os.add_dll_directory(os.path.join(TBB_ROOT, "bin"))

# Add Python path for custom build
sys.path.insert(0, os.path.join(CUSTOM_USD_ROOT, "lib", "python"))

# Import standard USD (from pip)
from pxr import Usd as StandardUsd
print(f"Standard USD version: {StandardUsd.GetVersion()}")  # (0, 25, 11)

# Import custom USD v26.05
from pxr_lte import Usd as CustomUsd
print(f"Custom USD version: {CustomUsd.GetVersion()}")  # (0, 24, 11)

# Use both
std_stage = StandardUsd.Stage.CreateInMemory()
custom_stage = CustomUsd.Stage.CreateInMemory()
```

### Using the Setup Helper

For convenience, use the `pxr_lte_setup` module:

```python
#!/usr/bin/env python3

# Auto-configures paths on import
import pxr_lte_setup

# Now both are available
from pxr import Usd as StandardUsd       # pip usd-core
from pxr_lte import Usd as CustomUsd     # custom v26.05

# Verify versions
print(f"pxr: {StandardUsd.GetVersion()}")
print(f"pxr_lte: {CustomUsd.GetVersion()}")
```

## C++ Usage

For C++ code, link against the custom USD libraries with `lte_` prefix:

```cpp
// Include from custom build
#include "pxr/pxr.h"
#include "pxr/usd/usd/stage.h"

// Use pxr_lte namespace
PXR_NAMESPACE_USING_DIRECTIVE  // brings in pxr_lte::

int main() {
    // Creates stage using pxr_lte namespace
    auto stage = UsdStage::CreateInMemory();
    // ...
}
```

### Build Command (Windows)

```batch
cl /EHsc /std:c++17 /MD ^
    /I "dist-usd-lte-v26.05/include" ^
    /I "dist-tbb-reldeb/include" ^
    test.cpp ^
    /link /LIBPATH:"dist-usd-lte-v26.05/lib" ^
    lte_tf.lib lte_sdf.lib lte_usd.lib tbb12.lib
```

## Important Notes

### Object Incompatibility

Objects from different builds cannot be mixed:

```python
# This FAILS - types are incompatible
custom_stage.GetPrimAtPath(standard_prim.GetPath())

# Convert via string instead:
path_str = str(standard_prim.GetPath())
custom_prim = custom_stage.GetPrimAtPath(path_str)
```

### Memory Usage

Loading both USD builds doubles memory usage for USD-related data.

### TBB Compatibility

Both builds share TBB. Ensure TBB versions are compatible.

## Test Scripts

| Script | Description |
|--------|-------------|
| `test_pxr_lte_only.py` | Test custom USD v26.05 only |
| `test_dual_usd_sameproc.py` | Test both pxr and pxr_lte together |
| `build_cpp_test.bat` | Build and run C++ test |

## Troubleshooting

### "Module not found: pxr_lte"

1. Check DLL paths are added with `os.add_dll_directory()`
2. Check Python path includes `dist-usd-lte-v26.05/lib/python`
3. Verify the build completed successfully

### DLL load errors

1. Ensure TBB DLLs are accessible
2. Add both `lib` and `bin` directories
3. Check all `lte_*.dll` files are present

### Type mismatch between builds

Objects from `pxr` and `pxr_lte` are incompatible. Convert via strings or re-create objects.

## Version Information

- Standard USD: pip usd-core 25.11 (or similar)
- Custom USD: v26.05 with pxr_lte namespace
- TBB: 2021.9.0 (or compatible)
- Python: 3.11+
