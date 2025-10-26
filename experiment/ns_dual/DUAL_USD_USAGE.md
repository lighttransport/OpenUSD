# Using Dual USD Builds (Ordinary + Custom Namespace)

This document explains how to use both the ordinary USD build (standard `pxr` namespace) and the custom namespace USD build (`pxr_lte` namespace with `lte` library prefix) simultaneously.

## Build Configurations

### Ordinary USD (`dist-pxr`)
- **Namespace**: `pxr` (standard)
- **Library Prefix**: `libusd_`
- **Location**: `/mnt/nvme02/work/usd-lte/dist-pxr`
- **Libraries**: `libusd_usd.so`, `libusd_sdf.so`, etc.

### Custom USD (`dist-usd-reldeb`)
- **Namespace**: `pxr_lte` (custom external namespace)
- **Internal Namespace**: `pxrInternal_v0_25_11__pxrReserved__`
- **Library Prefix**: `lte`
- **Location**: `/mnt/nvme02/work/dist-usd-reldeb`
- **Libraries**: `lteusd.so`, `ltesdf.so`, etc.

## Key Finding: Namespace Isolation

The custom build is correctly configured with `pxr_lte` as the external namespace:

```cpp
// From dist-usd-reldeb/include/pxr/pxr.h
#define PXR_NS pxr_lte
#define PXR_INTERNAL_NS pxrInternal_v0_25_11__pxrReserved__

namespace PXR_NS {  // namespace pxr_lte
    using namespace PXR_INTERNAL_NS;
}
```

This means:
- ✅ C++ code compiled against the custom build uses `pxr_lte::` namespace
- ✅ Libraries have different binary names (`lte*.so` vs `libusd_*.so`)
- ⚠️ Python bindings still use `pxr` module name (conflict!)

## Usage Methods

### Method 1: Subprocess Isolation (Recommended for Python)

This is the cleanest approach for Python users. Use the provided `usd_dual.py` wrapper:

```python
#!/usr/bin/env python3
from usd_dual import ordinary, custom

# Use ordinary USD
ordinary_code = """
from pxr import Usd, Sdf
stage = Usd.Stage.CreateInMemory()
prim = stage.DefinePrim("/World")
print(f"Ordinary USD: {prim.GetPath()}")
"""
stdout, stderr, code = ordinary.execute(ordinary_code)
print(stdout)

# Use custom USD
custom_code = """
from pxr import Usd, Sdf
stage = Usd.Stage.CreateInMemory()
prim = stage.DefinePrim("/CustomWorld")
print(f"Custom USD: {prim.GetPath()}")
"""
stdout, stderr, code = custom.execute(custom_code)
print(stdout)
```

### Method 2: Separate Scripts

Create separate Python scripts for each USD build:

**script_ordinary.py**:
```python
#!/usr/bin/env python3
import sys
import os

# Set up environment for ordinary USD
sys.path.insert(0, "/mnt/nvme02/work/usd-lte/dist-pxr/lib/python")
os.environ['LD_LIBRARY_PATH'] = "/mnt/nvme02/work/usd-lte/dist-pxr/lib"

from pxr import Usd
# ... use ordinary USD
```

**script_custom.py**:
```python
#!/usr/bin/env python3
import sys
import os

# Set up environment for custom USD
sys.path.insert(0, "/mnt/nvme02/work/dist-usd-reldeb/lib/python")
os.environ['LD_LIBRARY_PATH'] = "/mnt/nvme02/work/dist-usd-reldeb/lib"

from pxr import Usd
# ... use custom USD
```

### Method 3: C++ with Explicit Namespace (Limited)

In C++, you CAN reference both namespaces if you compile against both:

```cpp
// This is theoretical - in practice, linking both is problematic
namespace pxr {
    // Ordinary USD types
}

namespace pxr_lte {
    // Custom USD types
}

// Use explicit qualification
pxr::UsdStage ordinaryStage;
pxr_lte::UsdStage customStage;
```

**However**, this is not practical because:
- Symbol conflicts during linking
- Both define internal symbols identically
- Better to use separate binaries/processes

### Method 4: Dynamic Loading with ctypes/cffi

For advanced users, load libraries explicitly:

```python
import ctypes

# Load custom USD libraries
lteusd = ctypes.CDLL("/mnt/nvme02/work/dist-usd-reldeb/lib/lteusd.so")
ltesdf = ctypes.CDLL("/mnt/nvme02/work/dist-usd-reldeb/lib/ltesdf.so")

# Call C functions directly via ctypes
# This requires knowledge of USD's C API (limited)
```

## Python Binding Conflict

**Problem**: Both USD builds install Python modules as `pxr.Usd`, `pxr.Sdf`, etc.

**Why**: Python bindings are generated with the module name `pxr` regardless of the C++ namespace.

**Solutions**:
1. ✅ **Use subprocess isolation** (recommended) - See `usd_dual.py`
2. ✅ **Use separate processes/scripts** - Run different scripts for each build
3. ❌ **Import both in same process** - Will conflict, not recommended

## Testing

Run the provided test scripts:

```bash
# Test dual loading with conflict detection
python3 test_dual_usd.py

# Test isolated loading (recommended approach)
python3 test_isolated_usd.py
```

## Practical Use Cases

### Use Case 1: Testing Compatibility
Test the same USD file with both builds to ensure compatibility:

```python
from usd_dual import ordinary, custom

test_code = """
from pxr import Usd
stage = Usd.Stage.Open('test.usd')
print(f"Loaded {len(list(stage.Traverse()))} prims")
"""

print("Ordinary USD:")
ordinary.execute(test_code)

print("Custom USD:")
custom.execute(test_code)
```

### Use Case 2: Migration Testing
Test migrating from ordinary to custom USD:

```bash
# Process with ordinary USD
./process_with_ordinary.py input.usd output_ordinary.usd

# Process with custom USD
./process_with_custom.py input.usd output_custom.usd

# Compare results
./compare_outputs.py output_ordinary.usd output_custom.usd
```

### Use Case 3: Side-by-Side Comparison
Compare behavior or performance:

```python
import time
from usd_dual import ordinary, custom

benchmark = """
from pxr import Usd
import time
start = time.time()
for i in range(1000):
    stage = Usd.Stage.CreateInMemory()
    prim = stage.DefinePrim(f"/prim{i}")
elapsed = time.time() - start
print(f"Time: {elapsed:.3f}s")
"""

print("Ordinary USD:")
ordinary.execute(benchmark)

print("Custom USD:")
custom.execute(benchmark)
```

## Environment Variables

### For Ordinary USD:
```bash
export PYTHONPATH=/mnt/nvme02/work/usd-lte/dist-pxr/lib/python:${PYTHONPATH}
export LD_LIBRARY_PATH=/mnt/nvme02/work/usd-lte/dist-pxr/lib:${LD_LIBRARY_PATH}
export PATH=/mnt/nvme02/work/usd-lte/dist-pxr/bin:${PATH}
```

### For Custom USD:
```bash
export PYTHONPATH=/mnt/nvme02/work/dist-usd-reldeb/lib/python:${PYTHONPATH}
export LD_LIBRARY_PATH=/mnt/nvme02/work/dist-usd-reldeb/lib:${LD_LIBRARY_PATH}
export PATH=/mnt/nvme02/work/dist-usd-reldeb/bin:${PATH}
```

## Verification

Check which USD build you're using:

```python
from pxr import Usd
import pxr.Usd._usd as usd_module

print(f"USD Library: {usd_module.__file__}")
print(f"USD Version: {Usd.GetVersion()}")

# Check library prefix
import os
lib_dir = os.path.dirname(os.path.dirname(usd_module.__file__))
if "lte" in os.listdir(lib_dir):
    print("Using custom USD (lte prefix)")
else:
    print("Using ordinary USD (libusd_ prefix)")
```

## Troubleshooting

### Issue: "Multiple definitions of TfEnvSetting variable"
**Cause**: Both USD libraries loaded in same process
**Solution**: Use subprocess isolation (`usd_dual.py`)

### Issue: Wrong USD version loaded
**Cause**: PATH/PYTHONPATH/LD_LIBRARY_PATH priority issues
**Solution**: Clear environment and set only one USD build's paths

### Issue: Import conflicts
**Cause**: Both `pxr` modules in sys.path
**Solution**: Use separate processes or scripts

## Summary

| Method | Python Support | C++ Support | Complexity | Recommended |
|--------|---------------|-------------|------------|-------------|
| Subprocess Isolation | ✅ Excellent | ✅ Via separate binaries | Low | ⭐⭐⭐⭐⭐ |
| Separate Scripts | ✅ Good | ✅ Good | Low | ⭐⭐⭐⭐ |
| Dynamic Loading | ⚠️ Limited | ⚠️ Advanced | High | ⭐⭐ |
| Same Process | ❌ Conflicts | ❌ Link errors | N/A | ❌ |

**Recommendation**: Use subprocess isolation via `usd_dual.py` wrapper for the best experience.

## Files

- `test_dual_usd.py` - Demonstrates conflicts and capabilities
- `test_isolated_usd.py` - Shows proper subprocess isolation
- `usd_dual.py` - Wrapper module for easy dual USD access
- `test_cpp_dual_namespace.cpp` - C++ namespace reference
- `DUAL_USD_USAGE.md` - This document
