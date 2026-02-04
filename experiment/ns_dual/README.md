# Dual Namespace USD Experiment (v24.11)

This directory contains code, scripts, and documentation for experimenting with loading both ordinary USD (standard `pxr` namespace) and custom namespace USD (`pxr_lte` namespace with `lte_` library prefix) simultaneously.

## Same-Process Dual USD (Windows)

This experiment supports same-process dual USD import on Windows. Both `pxr` and `pxr_lte` can be imported in the same Python process without conflicts.

### Quick Start

1. **Build custom namespace USD v24.11:**
   ```batch
   # From OpenUSD root
   configure-usd-lte.bat
   build-usd-lte.bat all
   ```

2. **Test the setup:**
   ```batch
   python experiment\ns_dual\pxr_lte_setup.py
   ```

3. **Use both USDs:**
   ```python
   import pxr_lte_setup  # Auto-configures paths

   from pxr import Usd as StandardUsd       # Standard USD (pip usd-core)
   from pxr_lte import Usd as CustomUsd     # Custom namespace USD (v24.11)

   # They are completely independent
   std_stage = StandardUsd.Stage.CreateInMemory()
   custom_stage = CustomUsd.Stage.CreateInMemory()
   ```

## Directory Contents

### Same-Process Files (Windows)

| File | Description |
|------|-------------|
| `pxr_lte_setup.py` | Helper module to configure paths for pxr_lte |
| `test_dual_usd_sameproc.py` | Comprehensive test for same-process dual USD |

### C++ Test Files

| File | Description |
|------|-------------|
| `test_usd_single.cpp` | C++ test file for USD builds |
| `test_cpp_dual_namespace.cpp` | C++ dual namespace info/demo |
| `build_cpp_test.bat` | VS2022 build script for C++ tests |

### Documentation

| File | Description |
|------|-------------|
| `DUAL_USD_USAGE.md` | Comprehensive usage guide |

## Build Configuration

The custom namespace build uses:

```cmake
-DPXR_SET_EXTERNAL_NAMESPACE=pxr_lte  # C++ namespace
-DPXR_LIB_PREFIX=lte_                  # Library prefix (lte_*.dll)
-DPXR_PYTHON_PACKAGE_NAME=pxr_lte     # Python package name
```

### Build Locations (Windows)

| Build | Path | Libraries |
|-------|------|-----------|
| Standard (pip) | pip install usd-core | `usd_*.pyd` |
| Custom v24.11 | `dist-usd-lte-v24.11` | `lte_*.dll` |

## Same-Process Dual USD

Both USDs loaded in one Python process. Full interactivity, no serialization overhead.

```python
# Setup
import pxr_lte_setup

# Import both
from pxr import Usd as StandardUsd       # pip usd-core
from pxr_lte import Usd as CustomUsd     # custom v24.11 build

# Use directly
std_stage = StandardUsd.Stage.CreateInMemory()
custom_stage = CustomUsd.Stage.CreateInMemory()

# Verify versions
print("pxr version:", StandardUsd.GetVersion())      # (0, 25, 11) from pip
print("pxr_lte version:", CustomUsd.GetVersion())    # (0, 24, 11) custom build
```

**Pros:**
- Natural Python usage
- No serialization overhead
- Full REPL support
- Different USD versions in same process

**Cons:**
- Double memory usage
- Objects not interoperable between builds

## Running Tests

### Same-Process Test

```batch
python experiment\ns_dual\test_dual_usd_sameproc.py
```

### C++ Test

```batch
cd experiment\ns_dual
build_cpp_test.bat
```

## Key Findings

| Aspect | Same-Process |
|--------|--------------|
| Import both | ✅ Works |
| No library conflicts | ✅ With lib prefix |
| Memory overhead | 2x USD memory |
| Object passing | ❌ Type mismatch |
| Debugging | ✅ Full |
| Platform | Windows tested |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CUSTOM_USD_ROOT` | Custom USD installation | `~/work/dist-usd-lte-v24.11` |
| `TBB_ROOT` | TBB installation | `~/work/dist-tbb-reldeb` |

## Troubleshooting

### "Module not found: pxr_lte"
- Check PYTHONPATH includes custom USD's `lib/python`
- Verify `pxr_lte/__init__.py` exists

### DLL load errors (Windows)
- Use `os.add_dll_directory()` for Python 3.8+
- Ensure TBB DLLs are accessible

### Type mismatch errors
Objects from different builds are incompatible:
```python
# This fails:
custom_stage.GetPrimAtPath(standard_prim.GetPath())

# Convert via string:
path_str = str(standard_prim.GetPath())
custom_prim = custom_stage.GetPrimAtPath(path_str)
```

## Further Reading

- [Dual Namespace Build Guide](../../docs/v24.11_custom_namespace_build.md)
- `configure-usd-lte.bat` - Configure script
- `build-usd-lte.bat` - Build script

## License

Same as parent USD project (see LICENSE.txt in repository root).
