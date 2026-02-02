#!/usr/bin/env python3
"""
Test script for same-process dual USD usage.

This script demonstrates importing both standard USD (pxr) and custom
namespace USD (pxr_lte) in the same Python process.

Requirements:
- Standard USD build (pxr) OR pip-installed usd-core
- Custom namespace USD build (pxr_lte) from build-lte-sameproc.bat

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

# Standard USD build paths (can be from pip, conda, or custom build)
STANDARD_USD_LIB = os.path.expandvars(r"$USERPROFILE\work\dist-pxrusd\lib")
STANDARD_USD_BIN = os.path.expandvars(r"$USERPROFILE\work\dist-pxrusd\bin")

# Custom namespace USD build paths (from build-lte-sameproc.bat)
CUSTOM_USD_LIB = os.path.expandvars(r"$USERPROFILE\work\dist-usd-lte\lib")
CUSTOM_USD_BIN = os.path.expandvars(r"$USERPROFILE\work\dist-usd-lte\bin")

# TBB path (shared between both builds)
TBB_BIN = os.path.expandvars(r"$USERPROFILE\work\dist-tbb-reldeb\bin")

# Set to True to use pip-installed USD instead of custom build for standard pxr
USE_PIP_USD = False

# ==============================================================================
# Path setup
# ==============================================================================

def setup_paths():
    """Set up DLL and Python paths for both USD builds."""

    print("Setting up paths...")

    # On Windows, we need to add DLL directories explicitly (Python 3.8+)
    if platform.system() == "Windows":
        # Add DLL search directories
        if not USE_PIP_USD:
            if os.path.exists(STANDARD_USD_LIB):
                os.add_dll_directory(STANDARD_USD_LIB)
                print(f"  Added DLL path: {STANDARD_USD_LIB}")
            if os.path.exists(STANDARD_USD_BIN):
                os.add_dll_directory(STANDARD_USD_BIN)
                print(f"  Added DLL path: {STANDARD_USD_BIN}")

        if os.path.exists(CUSTOM_USD_LIB):
            os.add_dll_directory(CUSTOM_USD_LIB)
            print(f"  Added DLL path: {CUSTOM_USD_LIB}")
        if os.path.exists(CUSTOM_USD_BIN):
            os.add_dll_directory(CUSTOM_USD_BIN)
            print(f"  Added DLL path: {CUSTOM_USD_BIN}")

        if os.path.exists(TBB_BIN):
            os.add_dll_directory(TBB_BIN)
            print(f"  Added DLL path: {TBB_BIN}")

    # Add Python paths (custom build first, then standard)
    custom_python = os.path.join(CUSTOM_USD_LIB, "python")
    if os.path.exists(custom_python):
        sys.path.insert(0, custom_python)
        print(f"  Added Python path: {custom_python}")

    if not USE_PIP_USD:
        standard_python = os.path.join(STANDARD_USD_LIB, "python")
        if os.path.exists(standard_python):
            sys.path.insert(0, standard_python)
            print(f"  Added Python path: {standard_python}")

    print()

# ==============================================================================
# Tests
# ==============================================================================

def test_imports():
    """Test importing both USD packages."""

    print("=" * 60)
    print("Test 1: Importing USD packages")
    print("=" * 60)

    # Import standard USD
    print("\n1. Importing pxr (standard USD)...")
    try:
        from pxr import Usd as StandardUsd
        from pxr import Sdf as StandardSdf
        print(f"   SUCCESS: {StandardUsd}")
        print(f"   Sdf: {StandardSdf}")
    except ImportError as e:
        print(f"   FAILED: {e}")
        return None, None

    # Import custom namespace USD
    print("\n2. Importing pxr_lte (custom namespace USD)...")
    try:
        from pxr_lte import Usd as CustomUsd
        from pxr_lte import Sdf as CustomSdf
        print(f"   SUCCESS: {CustomUsd}")
        print(f"   Sdf: {CustomSdf}")
    except ImportError as e:
        print(f"   FAILED: {e}")
        return StandardUsd, None

    return StandardUsd, CustomUsd

def test_stage_creation(StandardUsd, CustomUsd):
    """Test creating stages with both USD packages."""

    print("\n" + "=" * 60)
    print("Test 2: Creating USD stages")
    print("=" * 60)

    # Create standard USD stage
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
        return

    # Create custom namespace USD stage
    print("\n2. Creating custom namespace USD stage...")
    try:
        custom_stage = CustomUsd.Stage.CreateInMemory()
        custom_root = custom_stage.DefinePrim("/CustomRoot", "Xform")
        custom_child = custom_stage.DefinePrim("/CustomRoot/Mesh", "Mesh")
        print(f"   Stage: {custom_stage}")
        print(f"   Root prim: {custom_root}")
        print(f"   Child prim: {custom_child}")
    except Exception as e:
        print(f"   FAILED: {e}")
        return

    return std_stage, custom_stage

def test_independence(std_stage, custom_stage, StandardUsd, CustomUsd):
    """Test that both stages are independent."""

    print("\n" + "=" * 60)
    print("Test 3: Verifying independence")
    print("=" * 60)

    # Verify prims in each stage
    print("\n1. Standard stage prims:")
    for prim in std_stage.Traverse():
        print(f"   {prim.GetPath()}")

    print("\n2. Custom stage prims:")
    for prim in custom_stage.Traverse():
        print(f"   {prim.GetPath()}")

    # Verify types are different
    print("\n3. Type verification:")
    print(f"   StandardUsd.Stage type: {type(std_stage)}")
    print(f"   CustomUsd.Stage type: {type(custom_stage)}")
    print(f"   Types are different: {type(std_stage) != type(custom_stage)}")

def test_export(std_stage, custom_stage):
    """Test exporting to USDA format."""

    print("\n" + "=" * 60)
    print("Test 4: Exporting to USDA")
    print("=" * 60)

    # Export standard stage
    print("\n1. Standard USD USDA output:")
    print("-" * 40)
    print(std_stage.GetRootLayer().ExportToString())

    # Export custom stage
    print("2. Custom USD USDA output:")
    print("-" * 40)
    print(custom_stage.GetRootLayer().ExportToString())

def main():
    """Main test function."""

    print("=" * 60)
    print("Same-Process Dual USD Test")
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

    if StandardUsd is None:
        print("\nFAILED: Could not import standard USD (pxr)")
        return 1

    if CustomUsd is None:
        print("\nFAILED: Could not import custom USD (pxr_lte)")
        return 1

    result = test_stage_creation(StandardUsd, CustomUsd)
    if result is None:
        return 1

    std_stage, custom_stage = result
    test_independence(std_stage, custom_stage, StandardUsd, CustomUsd)
    test_export(std_stage, custom_stage)

    print("\n" + "=" * 60)
    print("ALL TESTS PASSED!")
    print("Same-process dual USD is working correctly.")
    print("=" * 60)

    return 0

if __name__ == "__main__":
    sys.exit(main())
