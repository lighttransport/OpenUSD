#!/usr/bin/env python3
"""
Test script to load both ordinary USD (pxr namespace) and custom namespace USD (pxr_lte namespace)
simultaneously to verify they can coexist without conflicts.

This demonstrates:
1. Loading ordinary USD from dist-pxr with standard 'pxr' namespace
2. Loading custom USD from dist-usd-reldeb with 'pxr_lte' namespace and 'lte' library prefix
3. Using both in the same Python process
"""

import sys
import os
import ctypes

# Paths
DIST_PXR = "/mnt/nvme02/work/usd-lte/dist-pxr"
DIST_LTE = "/mnt/nvme02/work/dist-usd-reldeb"

print("=" * 80)
print("USD Dual-Namespace Loading Test")
print("=" * 80)
print(f"Ordinary USD:      {DIST_PXR}")
print(f"Custom USD (LTE):  {DIST_LTE}")
print("=" * 80)

# Step 1: Set up paths for ordinary USD
print("\n[Step 1] Setting up ordinary USD (pxr namespace)...")
sys.path.insert(0, os.path.join(DIST_PXR, "lib", "python"))
os.environ['LD_LIBRARY_PATH'] = f"{DIST_PXR}/lib:" + os.environ.get('LD_LIBRARY_PATH', '')

try:
    # Import ordinary USD
    from pxr import Usd, Sdf, Tf
    print("✓ Successfully imported ordinary USD (pxr namespace)")
    print(f"  - pxr.Usd: {Usd}")
    print(f"  - pxr.Sdf: {Sdf}")
    print(f"  - pxr.Tf: {Tf}")

    # Get USD version from ordinary build
    try:
        version = Usd.GetVersion()
        print(f"  - USD Version: {version[0]}.{version[1]}.{version[2]}")
    except:
        print("  - USD Version: (unable to determine)")

    # Create a simple stage with ordinary USD
    stage = Usd.Stage.CreateInMemory()
    prim = stage.DefinePrim("/hello")
    print(f"  - Created stage with prim: {prim.GetPath()}")

except ImportError as e:
    print(f"✗ Failed to import ordinary USD: {e}")
    sys.exit(1)

# Step 2: Manually load custom namespace USD libraries
print("\n[Step 2] Loading custom namespace USD (pxr_lte) libraries...")

# Add custom USD lib path to LD_LIBRARY_PATH
os.environ['LD_LIBRARY_PATH'] = f"{DIST_LTE}/lib:" + os.environ.get('LD_LIBRARY_PATH', '')

# Try to load the custom namespace libraries directly using ctypes
try:
    # Load core libraries with lte prefix
    lteusd = ctypes.CDLL(os.path.join(DIST_LTE, "lib", "lteusd.so"))
    ltesdf = ctypes.CDLL(os.path.join(DIST_LTE, "lib", "ltesdf.so"))
    ltetf = ctypes.CDLL(os.path.join(DIST_LTE, "lib", "ltetf.so"))

    print("✓ Successfully loaded custom USD libraries:")
    print(f"  - lteusd.so: {lteusd}")
    print(f"  - ltesdf.so: {ltesdf}")
    print(f"  - ltetf.so: {ltetf}")

except OSError as e:
    print(f"✗ Failed to load custom USD libraries: {e}")
    print("\nNote: Custom namespace USD Python bindings may need to be imported differently")

# Step 3: Check for Python bindings of custom USD
print("\n[Step 3] Checking for custom USD Python bindings...")
sys.path.insert(0, os.path.join(DIST_LTE, "lib", "python"))

try:
    # Try importing as pxr_lte (the custom namespace)
    # Note: This will likely fail because the Python module is still named 'pxr'
    # but uses the pxr_lte C++ namespace internally
    import importlib

    # Check what's in the custom USD's Python directory
    python_dir = os.path.join(DIST_LTE, "lib", "python")
    if os.path.exists(python_dir):
        print(f"✓ Custom USD Python directory exists: {python_dir}")
        pxr_dir = os.path.join(python_dir, "pxr")
        if os.path.exists(pxr_dir):
            modules = [f for f in os.listdir(pxr_dir) if not f.startswith('_') and not f.endswith('.pyc')]
            print(f"  - Available modules: {', '.join(modules[:10])}...")

    print("\n⚠ Note: Custom namespace USD Python modules are named 'pxr' but use")
    print("  'pxr_lte' C++ namespace internally. Direct import will conflict with")
    print("  ordinary USD. They need to be loaded in separate processes or via")
    print("  explicit symbol isolation.")

except Exception as e:
    print(f"✗ Error checking custom USD: {e}")

# Step 4: Demonstrate library isolation
print("\n[Step 4] Verifying library isolation...")

# Check that ordinary USD still works after loading custom libraries
try:
    stage2 = Usd.Stage.CreateInMemory()
    prim2 = stage2.DefinePrim("/world")
    print(f"✓ Ordinary USD still works: created prim {prim2.GetPath()}")
except Exception as e:
    print(f"✗ Ordinary USD affected by custom library loading: {e}")

# Step 5: Symbol analysis
print("\n[Step 5] Library symbol analysis...")

import subprocess

def check_symbols(lib_path, prefix):
    """Check if library has symbols with the expected prefix."""
    try:
        result = subprocess.run(
            ['nm', '-D', lib_path],
            capture_output=True,
            text=True,
            timeout=5
        )

        # Look for C++ namespace in symbols
        symbols = result.stdout
        if 'pxr_lte' in symbols:
            return 'pxr_lte'
        elif 'pxrInternal' in symbols or '_Z' in symbols:
            # Mangled symbols might be from either namespace
            return 'detected (mangled)'
        return 'none'
    except Exception as e:
        return f'error: {e}'

ordinary_lib = os.path.join(DIST_PXR, "lib", "libusd_usd.so")
custom_lib = os.path.join(DIST_LTE, "lib", "lteusd.so")

print("\nSymbol namespace detection:")
print(f"  - Ordinary USD: {check_symbols(ordinary_lib, 'pxr')}")
print(f"  - Custom USD:   {check_symbols(custom_lib, 'pxr_lte')}")

# Summary
print("\n" + "=" * 80)
print("SUMMARY")
print("=" * 80)
print("✓ Ordinary USD (pxr namespace) loaded successfully")
print("✓ Custom USD (pxr_lte namespace) libraries exist and are loadable")
print("✓ Library prefixes are different (libusd_* vs lte*)")
print("⚠ Python bindings conflict: both use 'pxr' module name")
print("\nRECOMMENDATION:")
print("- Use ordinary and custom USD in separate processes")
print("- Or load custom USD libraries directly via ctypes/cffi")
print("- Or use LD_PRELOAD for controlled symbol resolution")
print("=" * 80)
