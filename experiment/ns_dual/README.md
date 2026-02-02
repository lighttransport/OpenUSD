# Dual Namespace USD Experiment

This directory contains code, scripts, and documentation for experimenting with loading both ordinary USD (standard `pxr` namespace) and custom namespace USD (`pxr_lte` namespace with `lte_` library prefix) simultaneously.

## Same-Process Dual USD (Windows)

**New!** This experiment now supports same-process dual USD import on Windows. Both `pxr` and `pxr_lte` can be imported in the same Python process without conflicts.

### Quick Start

1. **Build custom namespace USD:**
   ```batch
   # From OpenUSD root
   build-lte-sameproc.bat
   ```

2. **Test the setup:**
   ```batch
   python experiment\ns_dual\pxr_lte_setup.py
   ```

3. **Use both USDs:**
   ```python
   import pxr_lte_setup  # Auto-configures paths

   from pxr import Usd as StandardUsd       # Standard USD (needs separate setup)
   from pxr_lte import Usd as CustomUsd     # Custom namespace USD

   # They are completely independent
   std_stage = StandardUsd.Stage.Open("scene.usda")
   custom_stage = CustomUsd.Stage.CreateInMemory()
   ```

## Directory Contents

### Same-Process Files (Windows)

| File | Description |
|------|-------------|
| `pxr_lte_setup.py` | Helper module to configure paths for pxr_lte |
| `test_dual_usd_sameproc.py` | Comprehensive test for same-process dual USD |

### Subprocess Isolation Files (Cross-platform)

| File | Description |
|------|-------------|
| `usd_dual.py` | Wrapper for subprocess-isolated dual USD |
| `usd_dual_win.py` | Windows-specific subprocess wrapper |
| `test_isolated_usd.py` | Subprocess isolation test |
| `example_use_both.py` | Practical usage example |

### C++ Test Files

| File | Description |
|------|-------------|
| `test_usd_single.cpp` | C++ test file for USD builds |
| `build_cpp_test.bat` | VS2022 build script for C++ tests |
| `build/` | Build output (gitignored) |

### Documentation

| File | Description |
|------|-------------|
| `DUAL_USD_USAGE.md` | Comprehensive usage guide |
| `EXPERIMENT_RESULTS.md` | Detailed findings and analysis |

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
| Standard | `dist-pxrusd` | `usd_*.dll` |
| Custom | `dist-usd-lte` | `lte_*.dll` |

## Two Approaches

### 1. Same-Process (Recommended for Windows)

Both USDs loaded in one Python process. Full interactivity, no serialization overhead.

```python
# Setup
import pxr_lte_setup

# Import both
from pxr import Usd as StandardUsd
from pxr_lte import Usd as CustomUsd

# Use directly
std_stage = StandardUsd.Stage.CreateInMemory()
custom_stage = CustomUsd.Stage.CreateInMemory()
```

**Pros:**
- Natural Python usage
- No serialization overhead
- Full REPL support

**Cons:**
- Double memory usage
- Objects not interoperable between builds
- Requires library prefix changes

### 2. Subprocess Isolation (Cross-platform)

Each USD runs in a separate process. Useful when builds have library conflicts.

```python
from usd_dual import ordinary, custom

# Execute code with each build
ordinary.execute("from pxr import Usd; print(Usd.GetVersion())")
custom.execute("from pxr import Usd; print(Usd.GetVersion())")
```

**Pros:**
- Works with any builds
- No library conflicts possible
- Cleaner isolation

**Cons:**
- Subprocess overhead
- Must serialize all communication
- No interactive debugging

## Running Tests

### Same-Process Test

```batch
python test_dual_usd_sameproc.py
```

### Subprocess Test

```batch
python test_isolated_usd.py
```

### C++ Test

```batch
build_cpp_test.bat
cd build
test_usd_single_pxr.exe
test_usd_single_lte.exe
```

## Key Findings

| Aspect | Same-Process | Subprocess |
|--------|--------------|------------|
| Import both | ✅ Works | ✅ Works |
| No library conflicts | ✅ With lib prefix | ✅ Always |
| Memory overhead | 2x USD memory | 2 processes |
| Object passing | ❌ Type mismatch | ❌ Serialization |
| Debugging | ✅ Full | Limited |
| Platform | Windows tested | All |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CUSTOM_USD_ROOT` | Custom USD installation | `~/work/dist-usd-lte` |
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

- [Dual Namespace Build Guide](../../docs/dual_namespace_build.md)
- [Using with Prebuilt USD](../../docs/using_with_prebuilt_usd.md)
- `build-lte-sameproc.bat` - Build script
- `configure-lte-sameproc.bat` - Configure-only script

## Contributing

To add tests:
1. Follow patterns in `test_*.py`
2. Use appropriate approach (same-process or subprocess)
3. Document findings

## License

Same as parent USD project (see LICENSE.txt in repository root).
