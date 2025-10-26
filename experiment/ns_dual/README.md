# Dual Namespace USD Experiment

This directory contains code, scripts, and documentation for experimenting with loading both ordinary USD (standard `pxr` namespace) and custom namespace USD (`pxr_lte` namespace with `lte` library prefix) simultaneously.

## Directory Contents

### Test Scripts

#### `test_dual_usd.py`
Demonstrates attempting to load both USD builds in the same Python process. Shows:
- ✅ Ordinary USD imports successfully
- ✅ Custom USD libraries can be loaded via ctypes
- ⚠️ Python binding conflicts when trying to import both
- Analysis of symbols and namespaces

**Usage:**
```bash
python3 test_dual_usd.py
```

#### `test_isolated_usd.py`
Demonstrates the **recommended approach**: using subprocess isolation to run both USD builds separately. Shows:
- ✅ Both USD builds work perfectly in isolation
- ✅ No conflicts or warnings
- ✅ Identical output from both builds
- Creates the `usd_dual.py` wrapper module

**Usage:**
```bash
python3 test_isolated_usd.py
```

#### `example_use_both.py`
Practical example demonstrating how to use both USD builds to process the same USD operations and verify functional equivalence.

**Usage:**
```bash
python3 example_use_both.py
```

**Output:** Creates a USD stage with geometry primitives using both builds and compares results.

### Library Module

#### `usd_dual.py`
Wrapper module providing convenient access to both USD builds via subprocess isolation.

**Usage:**
```python
from usd_dual import ordinary, custom

# Execute code with ordinary USD
stdout, stderr, code = ordinary.execute("""
from pxr import Usd
stage = Usd.Stage.CreateInMemory()
print(f"Version: {Usd.GetVersion()}")
""")
print(stdout)

# Execute code with custom USD
stdout, stderr, code = custom.execute("""
from pxr import Usd
stage = Usd.Stage.CreateInMemory()
print(f"Version: {Usd.GetVersion()}")
""")
print(stdout)
```

### Documentation

#### `DUAL_USD_USAGE.md`
Comprehensive guide covering:
- Build configurations
- Namespace isolation details
- Usage methods and patterns
- Environment variables
- Troubleshooting
- Practical use cases
- Complete API reference

#### `EXPERIMENT_RESULTS.md`
Detailed findings from the experiment including:
- Test results and performance comparisons
- Symbol analysis
- Recommended usage patterns
- Pros/cons of different approaches
- Conclusions and next steps

### Reference Code

#### `test_cpp_dual_namespace.cpp`
C++ reference code showing the theoretical approach for using both USD builds in C++. Notes that direct linking is problematic and recommends using separate binaries.

## Quick Start

### 1. Run the Tests

```bash
# Test basic dual loading (shows conflicts)
python3 test_dual_usd.py

# Test subprocess isolation (recommended approach)
python3 test_isolated_usd.py

# Run practical example
python3 example_use_both.py
```

### 2. Use in Your Code

```python
# Import the wrapper
from usd_dual import ordinary, custom

# Define your USD code
my_code = """
from pxr import Usd, UsdGeom
stage = Usd.Stage.CreateInMemory()
sphere = UsdGeom.Sphere.Define(stage, "/MySphere")
print(f"Created: {sphere.GetPath()}")
"""

# Run with both builds
print("Ordinary USD:")
ordinary.execute(my_code)

print("Custom USD:")
custom.execute(my_code)
```

## Build Locations

### Ordinary USD
- **Path**: `/mnt/nvme02/work/usd-lte/dist-pxr`
- **Namespace**: `pxr` (standard)
- **Libraries**: `libusd_*.so`
- **Size**: ~1.5 GB

### Custom Namespace USD
- **Path**: `/mnt/nvme02/work/dist-usd-reldeb`
- **Namespace**: `pxr_lte` (external), `pxrInternal_v0_25_11__pxrReserved__` (internal)
- **Library Prefix**: `lte`
- **Libraries**: `lte*.so`
- **Size**: 2.6 GB

## Key Findings Summary

| Aspect | Status | Details |
|--------|--------|---------|
| Custom namespace | ✅ Works | `pxr_lte` correctly configured |
| Library isolation | ✅ Works | Different prefixes prevent conflicts |
| C++ API | ✅ Works | Use in separate binaries |
| Python bindings | ⚠️ Conflict | Both use `pxr.*` module names |
| Subprocess solution | ✅ Works | **Recommended approach** |
| Functional equivalence | ✅ Verified | Identical USD output |
| Performance | ✅ Equal | No measurable difference |

## Recommended Usage Pattern

**✅ Best Practice: Subprocess Isolation**

```python
from usd_dual import ordinary, custom

# Test with ordinary USD
ordinary.execute(your_usd_code)

# Test with custom USD
custom.execute(your_usd_code)
```

**Why?**
- Clean separation
- No conflicts
- Full USD functionality
- Easy to use

## Common Use Cases

### 1. Compatibility Testing
Verify that USD files work identically with both builds:
```python
test = "from pxr import Usd; stage = Usd.Stage.Open('test.usd')"
ordinary.execute(test)
custom.execute(test)
```

### 2. Regression Testing
Ensure custom namespace build doesn't introduce bugs:
```python
for test_file in test_files:
    code = f"from pxr import Usd; Usd.Stage.Open('{test_file}')"
    assert ordinary.execute(code)[2] == 0
    assert custom.execute(code)[2] == 0
```

### 3. Performance Comparison
Benchmark both builds:
```python
benchmark = """
import time
from pxr import Usd
start = time.time()
for i in range(1000):
    stage = Usd.Stage.CreateInMemory()
print(f"Time: {time.time() - start:.3f}s")
"""
ordinary.execute(benchmark)
custom.execute(benchmark)
```

## Troubleshooting

### "Multiple definitions of TfEnvSetting variable"
**Cause:** Both USD libraries loaded in same process
**Solution:** Use subprocess isolation (`usd_dual.py`)

### Import conflicts
**Cause:** Both `pxr` modules in sys.path
**Solution:** Use separate processes

### Wrong USD version loaded
**Cause:** Environment variable conflicts
**Solution:** Use `usd_dual.py` which handles paths automatically

## Environment Setup

If you need to manually set up environments:

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

**Note:** The `usd_dual.py` wrapper handles this automatically!

## Further Reading

- `DUAL_USD_USAGE.md` - Complete usage guide
- `EXPERIMENT_RESULTS.md` - Detailed findings and analysis
- Parent directory's `BUILD_SUMMARY.md` - Custom USD build details

## Contributing

To add more test cases:

1. Create a new test script following the pattern in `test_*.py`
2. Use `usd_dual.ordinary.execute()` and `usd_dual.custom.execute()`
3. Compare outputs to verify equivalence
4. Document findings

## License

Same as parent USD project (see LICENSE.txt in repository root).

## Related Build Scripts

Located in parent directory:
- `build-tbb.sh` - Build TBB dependency
- `build-lte-configure.sh` - Configure custom USD build
- `build-lte-build.sh` - Build custom USD
