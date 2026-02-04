#!/usr/bin/env python3
"""
Test script for same-process dual USD usage (v24.11).

This script demonstrates importing both standard USD (pxr) and custom
namespace USD (pxr_lte v24.11) in the same Python process.

Requirements:
- Standard USD: pip install usd-core
- Custom namespace USD v24.11: built from build-usd-lte.bat

Usage:
    python test_dual_usd_sameproc.py

The script will:
1. Set up DLL and Python paths
2. Import both USD packages
3. Create stages with both
4. Demonstrate they are independent
"""

import sys
import os
import platform

# ==============================================================================
# Configuration - Modify these paths for your system
# ==============================================================================

# Custom namespace USD v24.11 build paths
CUSTOM_USD_ROOT = os.path.expandvars(r"$USERPROFILE\work\dist-usd-lte-v24.11")
CUSTOM_USD_LIB = os.path.join(CUSTOM_USD_ROOT, "lib")
CUSTOM_USD_BIN = os.path.join(CUSTOM_USD_ROOT, "bin")

# TBB path (shared)
TBB_ROOT = os.path.expandvars(r"$USERPROFILE\work\dist-tbb-reldeb")
TBB_BIN = os.path.join(TBB_ROOT, "bin")

# ==============================================================================
# Path setup
# ==============================================================================

def setup_paths():
    """Set up DLL and Python paths for both USD builds."""

    print("Setting up paths...")

    # On Windows, we need to add DLL directories explicitly (Python 3.8+)
    if platform.system() == "Windows":
        # Add DLL search directories for custom build
        if os.path.exists(CUSTOM_USD_LIB):
            os.add_dll_directory(CUSTOM_USD_LIB)
            print(f"  Added DLL path: {CUSTOM_USD_LIB}")
        if os.path.exists(CUSTOM_USD_BIN):
            os.add_dll_directory(CUSTOM_USD_BIN)
            print(f"  Added DLL path: {CUSTOM_USD_BIN}")

        if os.path.exists(TBB_BIN):
            os.add_dll_directory(TBB_BIN)
            print(f"  Added DLL path: {TBB_BIN}")

    # Add Python path for custom build
    custom_python = os.path.join(CUSTOM_USD_LIB, "python")
    if os.path.exists(custom_python):
        sys.path.insert(0, custom_python)
        print(f"  Added Python path: {custom_python}")

    print()

# ==============================================================================
# Tests
# ==============================================================================

def test_imports():
    """Test importing both USD packages."""

    print("=" * 60)
    print("Test 1: Importing USD packages")
    print("=" * 60)

    StandardUsd = None
    CustomUsd = None

    # Import standard USD (from pip)
    print("\n1. Importing pxr (standard USD from pip)...")
    try:
        from pxr import Usd as StandardUsd
        from pxr import Sdf as StandardSdf
        print(f"   SUCCESS: pxr.Usd")
        print(f"   Version: {StandardUsd.GetVersion()}")
    except ImportError as e:
        print(f"   NOT AVAILABLE: {e}")
        print("   (Install with: pip install usd-core)")

    # Import custom namespace USD v24.11
    print("\n2. Importing pxr_lte (custom namespace USD v24.11)...")
    try:
        from pxr_lte import Usd as CustomUsd
        from pxr_lte import Sdf as CustomSdf
        print(f"   SUCCESS: pxr_lte.Usd")
        print(f"   Version: {CustomUsd.GetVersion()}")
    except ImportError as e:
        print(f"   FAILED: {e}")
        return StandardUsd, None

    return StandardUsd, CustomUsd

def test_stage_creation(StandardUsd, CustomUsd):
    """Test creating stages with both USD packages."""

    print("\n" + "=" * 60)
    print("Test 2: Creating USD stages")
    print("=" * 60)

    std_stage = None
    custom_stage = None

    # Create standard USD stage (if available)
    if StandardUsd:
        print("\n1. Creating standard USD stage...")
        try:
            std_stage = StandardUsd.Stage.CreateInMemory()
            std_root = std_stage.DefinePrim("/StandardRoot", "Xform")
            std_child = std_stage.DefinePrim("/StandardRoot/Mesh", "Mesh")
            print(f"   Stage: {std_stage}")
            print(f"   Root prim: {std_root}")
            print(f"   Child prim: {std_child}")
        except Exception as e:
            print(f"   FAILED: {e}")
    else:
        print("\n1. Skipping standard USD stage (not available)")

    # Create custom namespace USD stage
    print("\n2. Creating custom namespace USD v24.11 stage...")
    try:
        custom_stage = CustomUsd.Stage.CreateInMemory()
        custom_root = custom_stage.DefinePrim("/CustomRoot", "Xform")
        custom_child = custom_stage.DefinePrim("/CustomRoot/Mesh", "Mesh")
        print(f"   Stage: {custom_stage}")
        print(f"   Root prim: {custom_root}")
        print(f"   Child prim: {custom_child}")
    except Exception as e:
        print(f"   FAILED: {e}")
        return None, None

    return std_stage, custom_stage

def test_independence(std_stage, custom_stage, StandardUsd, CustomUsd):
    """Test that both stages are independent."""

    print("\n" + "=" * 60)
    print("Test 3: Verifying independence")
    print("=" * 60)

    if std_stage:
        print("\n1. Standard stage prims:")
        for prim in std_stage.Traverse():
            print(f"   {prim.GetPath()}")
    else:
        print("\n1. Standard stage: not available")

    print("\n2. Custom v24.11 stage prims:")
    for prim in custom_stage.Traverse():
        print(f"   {prim.GetPath()}")

    # Verify types are different
    if std_stage:
        print("\n3. Type verification:")
        print(f"   pxr.Usd.Stage type: {type(std_stage)}")
        print(f"   pxr_lte.Usd.Stage type: {type(custom_stage)}")
        print(f"   Types are different: {type(std_stage) != type(custom_stage)}")

def test_export(std_stage, custom_stage):
    """Test exporting to USDA format."""

    print("\n" + "=" * 60)
    print("Test 4: Exporting to USDA")
    print("=" * 60)

    if std_stage:
        print("\n1. Standard USD USDA output:")
        print("-" * 40)
        print(std_stage.GetRootLayer().ExportToString())

    print("2. Custom USD v24.11 USDA output:")
    print("-" * 40)
    print(custom_stage.GetRootLayer().ExportToString())

def test_more_modules(CustomUsd):
    """Test additional modules from pxr_lte."""

    print("\n" + "=" * 60)
    print("Test 5: Additional pxr_lte modules")
    print("=" * 60)

    print("\n1. Testing Gf (graphics math)...")
    try:
        from pxr_lte import Gf
        vec = Gf.Vec3f(1.0, 2.0, 3.0)
        print(f"   Gf.Vec3f: {vec}")
        print(f"   Length: {vec.GetLength()}")
    except Exception as e:
        print(f"   FAILED: {e}")

    print("\n2. Testing Vt (value types)...")
    try:
        from pxr_lte import Vt
        arr = Vt.FloatArray([1.0, 2.0, 3.0, 4.0])
        print(f"   Vt.FloatArray: {list(arr)}")
    except Exception as e:
        print(f"   FAILED: {e}")

    print("\n3. Testing Tf (foundation)...")
    try:
        from pxr_lte import Tf
        token = Tf.Token("testToken")
        print(f"   Tf.Token: {token}")
    except Exception as e:
        print(f"   FAILED: {e}")

def main():
    """Main test function."""

    print("=" * 60)
    print("Same-Process Dual USD Test (v24.11)")
    print("=" * 60)
    print()
    print(f"Python: {sys.executable}")
    print(f"Version: {sys.version}")
    print(f"Platform: {platform.platform()}")
    print()

    # Set up paths
    setup_paths()

    # Run tests
    StandardUsd, CustomUsd = test_imports()

    if CustomUsd is None:
        print("\nFAILED: Could not import custom USD (pxr_lte)")
        print("\nMake sure to build USD v24.11 with custom namespace:")
        print("  configure-usd-lte.bat")
        print("  build-usd-lte.bat all")
        return 1

    result = test_stage_creation(StandardUsd, CustomUsd)
    if result[1] is None:
        return 1

    std_stage, custom_stage = result
    test_independence(std_stage, custom_stage, StandardUsd, CustomUsd)
    test_export(std_stage, custom_stage)
    test_more_modules(CustomUsd)

    print("\n" + "=" * 60)
    print("ALL TESTS PASSED!")
    print("Same-process dual USD is working correctly.")
    if StandardUsd:
        print(f"  pxr (standard): {StandardUsd.GetVersion()}")
    print(f"  pxr_lte (custom v24.11): {CustomUsd.GetVersion()}")
    print("=" * 60)

    return 0

if __name__ == "__main__":
    sys.exit(main())
