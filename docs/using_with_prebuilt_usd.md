# Using Custom Namespace USD with Prebuilt/Preinstalled USD

This document explains how to use a custom namespace USD build alongside a prebuilt or preinstalled standard USD package.

## Overview

The custom namespace build (`pxr_lte`) is designed to work alongside any standard USD installation without requiring modifications to the standard build. This means you can use:

- **pip-installed USD** (`usd-core` package)
- **conda-installed USD**
- **DCC application's bundled USD** (Maya, Houdini, etc.)
- **Your own standard USD build**

All alongside the custom namespace build in the same Python process.

## Why No Modifications to Standard USD?

The key insight is that **all customization is in the alternative build**. The custom namespace build uses:

1. **Different library names**: `lte_*.dll` instead of `usd_*.dll`
2. **Different C++ namespace**: `pxr_lte` instead of `pxr`
3. **Different Python package**: `pxr_lte` instead of `pxr`

The standard `pxr` namespace doesn't know or care about the custom build. They coexist because they have different identifiers at every level.

## Using with pip-installed USD

### Installation

```bash
# Install standard USD from pip
pip install usd-core

# Build custom namespace USD (see build-lte-sameproc.bat)
# This creates pxr_lte package
```

### Python Usage

```python
import sys
import os

# Add DLL paths for custom build (Windows)
custom_usd_lib = "C:/path/to/dist-usd-lte/lib"
tbb_bin = "C:/path/to/tbb/bin"
os.add_dll_directory(custom_usd_lib)
os.add_dll_directory(tbb_bin)

# Add Python path for custom build
sys.path.insert(0, custom_usd_lib + "/python")

# Import both - pip USD is already in sys.path
from pxr import Usd as PipUsd           # pip-installed
from pxr_lte import Usd as CustomUsd    # custom build

# Use them independently
pip_stage = PipUsd.Stage.Open("scene.usda")
custom_stage = CustomUsd.Stage.CreateNew("output.usda")
```

## Using with DCC Application USD

Many DCC applications bundle their own USD. You can use the custom namespace build alongside them.

### Maya Example

```python
# Maya has pxr in its Python path
from pxr import Usd as MayaUsd

# Add custom build paths
import sys, os
os.add_dll_directory("C:/path/to/dist-usd-lte/lib")
sys.path.insert(0, "C:/path/to/dist-usd-lte/lib/python")

from pxr_lte import Usd as CustomUsd

# Now you can use both
maya_stage = MayaUsd.Stage.Open(selected_file)
custom_stage = CustomUsd.Stage.CreateInMemory()
```

### Houdini Example

```python
# Houdini also has pxr in its Python path
from pxr import Usd as HoudiniUsd

# Add custom build paths
import sys, os
os.add_dll_directory("C:/path/to/dist-usd-lte/lib")
sys.path.insert(0, "C:/path/to/dist-usd-lte/lib/python")

from pxr_lte import Usd as CustomUsd
```

## Version Compatibility Considerations

### TBB Compatibility

Both USD builds typically share the same TBB library. Ensure:
- TBB versions are compatible
- Only one TBB is loaded (add TBB path once)

### Python Version

The custom build must match the Python version of the environment:
- pip USD uses your current Python
- DCC applications use their bundled Python
- Build custom USD with the same Python version

### USD Version Differences

While both builds can have different USD versions, be aware:
- File format compatibility may vary
- Schema differences may exist
- Plugin compatibility differs between versions

## Path Setup Patterns

### Windows Environment Setup

```batch
@echo off
REM Setup for custom USD alongside preinstalled USD

REM Custom USD paths
set CUSTOM_USD=C:\path\to\dist-usd-lte
set TBB_ROOT=C:\path\to\tbb

REM Add to PATH for DLL discovery
set PATH=%CUSTOM_USD%\lib;%CUSTOM_USD%\bin;%TBB_ROOT%\bin;%PATH%

REM Add to PYTHONPATH
set PYTHONPATH=%CUSTOM_USD%\lib\python;%PYTHONPATH%
```

### Python Helper Module

Create a helper module for easy setup:

```python
# dual_usd_setup.py
import sys
import os
import platform

CUSTOM_USD_ROOT = os.environ.get("CUSTOM_USD_ROOT",
    os.path.expanduser("~/dist-usd-lte"))
TBB_ROOT = os.environ.get("TBB_ROOT",
    os.path.expanduser("~/dist-tbb-reldeb"))

def setup():
    """Setup paths for custom USD alongside standard USD."""

    custom_lib = os.path.join(CUSTOM_USD_ROOT, "lib")
    custom_bin = os.path.join(CUSTOM_USD_ROOT, "bin")
    tbb_bin = os.path.join(TBB_ROOT, "bin")

    # Add DLL directories (Windows Python 3.8+)
    if platform.system() == "Windows":
        for path in [custom_lib, custom_bin, tbb_bin]:
            if os.path.exists(path):
                os.add_dll_directory(path)

    # Add Python path
    python_path = os.path.join(custom_lib, "python")
    if python_path not in sys.path:
        sys.path.insert(0, python_path)

# Auto-setup on import
setup()
```

Usage:
```python
import dual_usd_setup  # Sets up paths

from pxr import Usd           # Standard/preinstalled
from pxr_lte import Usd as LteUsd  # Custom build
```

## Troubleshooting

### "Module not found: pxr_lte"

- Verify PYTHONPATH includes `<custom_usd>/lib/python`
- Check that `__init__.py` exists in `<custom_usd>/lib/python/pxr_lte/`

### DLL Load Errors (Windows)

- Use `os.add_dll_directory()` for Python 3.8+
- Verify all `lte_*.dll` files are present
- Check TBB DLLs are accessible

### Type Mismatch Errors

Objects from different USD builds are incompatible:
```python
# This will NOT work:
custom_stage.GetPrimAtPath(standard_prim.GetPath())  # Wrong type!

# Convert via path string:
path_str = str(standard_prim.GetPath())
custom_prim = custom_stage.GetPrimAtPath(path_str)  # OK
```

### Plugin Discovery Issues

Each build has its own plugin registry:
```python
# Set plugin path for custom build
os.environ["PXR_PLUGINPATH_NAME"] = "C:/path/to/custom-usd/lib/usd"
```

## Best Practices

1. **Import order matters**: Import the module that adds paths first
2. **Use type aliases**: `from pxr_lte import Usd as LteUsd` for clarity
3. **Don't mix objects**: Convert via strings/primitives when needed
4. **Document your setup**: Make path requirements clear for other developers
5. **Version pin both**: Track which USD versions you're using

## Limitations

1. **No object interoperability**: Can't pass pxr objects to pxr_lte functions
2. **Double memory usage**: Two USD runtimes loaded
3. **Separate plugin ecosystems**: Plugins must match their USD build
4. **Build complexity**: Must build and maintain custom USD

## See Also

- [Dual Namespace Build Guide](dual_namespace_build.md)
- [build-lte-sameproc.bat](../build-lte-sameproc.bat) - Build script
- [experiment/ns_dual/](../experiment/ns_dual/) - Test files
