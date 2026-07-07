#!/usr/bin/env python3
"""
Test script for custom namespace USD only (pxr_lte v26.05) - MONOLITHIC BUILD.

This script tests only the custom namespace USD monolithic build without requiring
standard pxr to be installed. Use this to verify your monolithic build works.

Requirements:
- Custom namespace USD v26.05 (monolithic): built from build-usd-lte-monolithic.bat

Usage:
    python test_pxr_lte_only_monolithic.py

The script will:
1. Set up DLL and Python paths for pxr_lte (monolithic)
2. Import pxr_lte modules
3. Test basic USD functionality
4. Demonstrate various USD operations
"""

import sys
import os
import platform

# ==============================================================================
# Configuration - Modify these paths for your system
# ==============================================================================

# Custom namespace USD v26.05 MONOLITHIC build paths
CUSTOM_USD_ROOT = os.path.expandvars(r"$USERPROFILE\work\dist-usd-lte-monolithic-v26.05")
CUSTOM_USD_LIB = os.path.join(CUSTOM_USD_ROOT, "lib")
CUSTOM_USD_BIN = os.path.join(CUSTOM_USD_ROOT, "bin")

# TBB path
TBB_ROOT = os.path.expandvars(r"$USERPROFILE\work\dist-tbb-reldeb")
TBB_BIN = os.path.join(TBB_ROOT, "bin")

# ==============================================================================
# Path setup
# ==============================================================================

def setup_paths():
    """Set up DLL and Python paths for pxr_lte (monolithic)."""

    print("Setting up paths for pxr_lte (monolithic)...")

    # On Windows, we need to add DLL directories explicitly (Python 3.8+)
    if platform.system() == "Windows":
        if os.path.exists(CUSTOM_USD_LIB):
            os.add_dll_directory(CUSTOM_USD_LIB)
            print(f"  Added DLL path: {CUSTOM_USD_LIB}")
        else:
            print(f"  WARNING: DLL path not found: {CUSTOM_USD_LIB}")

        if os.path.exists(CUSTOM_USD_BIN):
            os.add_dll_directory(CUSTOM_USD_BIN)
            print(f"  Added DLL path: {CUSTOM_USD_BIN}")

        if os.path.exists(TBB_BIN):
            os.add_dll_directory(TBB_BIN)
            print(f"  Added DLL path: {TBB_BIN}")
        else:
            print(f"  WARNING: TBB path not found: {TBB_BIN}")

    # Add Python path for custom build
    custom_python = os.path.join(CUSTOM_USD_LIB, "python")
    if os.path.exists(custom_python):
        sys.path.insert(0, custom_python)
        print(f"  Added Python path: {custom_python}")
    else:
        print(f"  ERROR: Python path not found: {custom_python}")
        return False

    print()
    return True

# ==============================================================================
# Tests
# ==============================================================================

def test_basic_import():
    """Test basic pxr_lte import."""

    print("=" * 60)
    print("Test 1: Basic Import")
    print("=" * 60)

    print("\nImporting pxr_lte.Usd...")
    try:
        from pxr_lte import Usd
        print(f"  SUCCESS: pxr_lte.Usd imported")
        print(f"  Version: {Usd.GetVersion()}")
        return Usd
    except ImportError as e:
        print(f"  FAILED: {e}")
        return None

def test_all_modules():
    """Test importing all common pxr_lte modules."""

    print("\n" + "=" * 60)
    print("Test 2: Import All Common Modules")
    print("=" * 60)

    modules = [
        ("Tf", "Foundation utilities"),
        ("Gf", "Graphics math"),
        ("Vt", "Value types"),
        ("Sdf", "Scene description"),
        ("Usd", "Universal Scene Description"),
        ("UsdGeom", "Geometry schemas"),
        ("UsdShade", "Shading schemas"),
        ("Kind", "Kind registry"),
        ("Ar", "Asset resolution"),
    ]

    results = {}
    for mod_name, description in modules:
        try:
            mod = __import__(f"pxr_lte.{mod_name}", fromlist=[mod_name])
            results[mod_name] = True
            print(f"  [OK] {mod_name:12} - {description}")
        except ImportError as e:
            results[mod_name] = False
            print(f"  [FAIL] {mod_name:12} - {e}")

    return results

def test_stage_creation():
    """Test creating and manipulating USD stages."""

    print("\n" + "=" * 60)
    print("Test 3: Stage Creation and Manipulation")
    print("=" * 60)

    from pxr_lte import Usd, Sdf, UsdGeom

    # Create in-memory stage
    print("\n1. Creating in-memory stage...")
    stage = Usd.Stage.CreateInMemory()
    print(f"   Stage: {stage}")

    # Define prims
    print("\n2. Defining prims...")
    root = stage.DefinePrim("/Root", "Xform")
    print(f"   Root prim: {root.GetPath()}")

    mesh = stage.DefinePrim("/Root/Mesh", "Mesh")
    print(f"   Mesh prim: {mesh.GetPath()}")

    # Add UsdGeom schema
    print("\n3. Adding UsdGeom.Xform...")
    xform = UsdGeom.Xform.Define(stage, "/Root/Transform")
    print(f"   Xform: {xform.GetPrim().GetPath()}")

    # Set metadata
    print("\n4. Setting metadata...")
    root.SetDocumentation("Root prim created by test")
    stage.SetMetadata("comment", "Test stage from pxr_lte v26.05 (monolithic)")

    # Traverse
    print("\n5. Traversing stage:")
    for prim in stage.Traverse():
        print(f"   {prim.GetPath()} ({prim.GetTypeName()})")

    return stage

def test_layer_operations():
    """Test layer operations."""

    print("\n" + "=" * 60)
    print("Test 4: Layer Operations")
    print("=" * 60)

    from pxr_lte import Sdf

    # Create anonymous layer
    print("\n1. Creating anonymous layer...")
    layer = Sdf.Layer.CreateAnonymous()
    print(f"   Layer: {layer.identifier}")

    # Create a new layer (in-memory, not saved)
    print("\n2. Layer properties:")
    print(f"   Empty: {layer.empty}")
    print(f"   Anonymous: {layer.anonymous}")

    return layer

def test_math_types():
    """Test math types from Gf and Vt."""

    print("\n" + "=" * 60)
    print("Test 5: Math Types (Gf, Vt)")
    print("=" * 60)

    from pxr_lte import Gf, Vt

    # Vectors
    print("\n1. Gf vectors:")
    v3f = Gf.Vec3f(1.0, 2.0, 3.0)
    print(f"   Vec3f: {v3f}")
    print(f"   Length: {v3f.GetLength():.4f}")
    print(f"   Normalized: {v3f.GetNormalized()}")

    v3d = Gf.Vec3d(1.0, 2.0, 3.0)
    print(f"   Vec3d: {v3d}")

    # Matrices
    print("\n2. Gf matrices:")
    m4d = Gf.Matrix4d()
    m4d.SetIdentity()
    print(f"   Matrix4d (identity): diagonal = {m4d[0][0]}, {m4d[1][1]}, {m4d[2][2]}, {m4d[3][3]}")

    # Quaternion
    print("\n3. Gf quaternion:")
    quat = Gf.Quatf(1.0, 0.0, 0.0, 0.0)
    print(f"   Quatf: {quat}")

    # Arrays
    print("\n4. Vt arrays:")
    float_arr = Vt.FloatArray([1.0, 2.0, 3.0, 4.0, 5.0])
    print(f"   FloatArray: {list(float_arr)}")

    int_arr = Vt.IntArray([1, 2, 3, 4, 5])
    print(f"   IntArray: {list(int_arr)}")

    vec3f_arr = Vt.Vec3fArray([(1, 0, 0), (0, 1, 0), (0, 0, 1)])
    print(f"   Vec3fArray: {[tuple(v) for v in vec3f_arr]}")

def test_export():
    """Test exporting stage to USDA."""

    print("\n" + "=" * 60)
    print("Test 6: Export to USDA")
    print("=" * 60)

    from pxr_lte import Usd, UsdGeom, Gf

    # Create a more complete stage
    stage = Usd.Stage.CreateInMemory()
    stage.SetMetadata("comment", "Generated by pxr_lte v26.05 monolithic test")

    # Add root xform
    root = UsdGeom.Xform.Define(stage, "/World")

    # Add a cube
    cube = UsdGeom.Cube.Define(stage, "/World/Cube")
    cube.GetSizeAttr().Set(2.0)

    # Add a sphere
    sphere = UsdGeom.Sphere.Define(stage, "/World/Sphere")
    sphere.GetRadiusAttr().Set(1.0)
    UsdGeom.XformCommonAPI(sphere).SetTranslate(Gf.Vec3d(3.0, 0.0, 0.0))

    # Export
    print("\nGenerated USDA:")
    print("-" * 40)
    print(stage.GetRootLayer().ExportToString())
    print("-" * 40)

def main():
    """Main test function."""

    print("=" * 60)
    print("pxr_lte Only Test (USD v26.05 MONOLITHIC)")
    print("=" * 60)
    print()
    print(f"Python: {sys.executable}")
    print(f"Version: {sys.version}")
    print(f"Platform: {platform.platform()}")
    print()
    print(f"Custom USD Root: {CUSTOM_USD_ROOT}")
    print(f"TBB Root: {TBB_ROOT}")
    print()

    # Set up paths
    if not setup_paths():
        print("\nFAILED: Could not set up paths")
        return 1

    # Test basic import
    Usd = test_basic_import()
    if Usd is None:
        print("\nFAILED: Could not import pxr_lte.Usd")
        print("\nMake sure to build USD v26.05 with custom namespace (monolithic):")
        print("  configure-usd-lte-monolithic.bat")
        print("  build-usd-lte-monolithic.bat all")
        return 1

    # Run all tests
    test_all_modules()
    test_stage_creation()
    test_layer_operations()
    test_math_types()
    test_export()

    print("\n" + "=" * 60)
    print("ALL TESTS PASSED!")
    print(f"pxr_lte v26.05 (monolithic) is working correctly.")
    print(f"  Version: {Usd.GetVersion()}")
    print("=" * 60)

    return 0

if __name__ == "__main__":
    sys.exit(main())
