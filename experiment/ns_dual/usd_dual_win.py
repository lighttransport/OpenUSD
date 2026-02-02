"""
usd_dual_win.py - Wrapper to access both USD builds via subprocess (Windows version)

Provides access to:
- Ordinary USD (pxr namespace) built with build_usd.py -> ../dist-pxrusd
- Custom USD (pxr_lte namespace) built with manual CMake -> ../dist-usd-reldeb
"""
import subprocess
import sys
import os

# Get script directory and compute paths relative to OpenUSD repo root
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))  # OpenUSD repo root

# USD build directories
DIST_PXR = os.path.join(os.path.dirname(REPO_ROOT), "dist-pxrusd")  # ../dist-pxrusd
DIST_LTE = os.path.join(os.path.dirname(REPO_ROOT), "dist-usd-reldeb")  # ../dist-usd-reldeb

# TBB for custom build (manual CMake build uses separately downloaded TBB)
DIST_TBB = os.path.join(os.path.dirname(REPO_ROOT), "dist-tbb-reldeb")  # ../dist-tbb-reldeb

# uv-installed Python directory (for python311.dll)
UV_PYTHON_DIR = os.path.join(
    os.environ.get('USERPROFILE', ''),
    'AppData', 'Roaming', 'uv', 'python', 'cpython-3.11.14-windows-x86_64-none'
)


class UsdVariant:
    """Wrapper for a specific USD build."""

    def __init__(self, name, path, namespace="pxr", extra_dll_paths=None):
        self.name = name
        self.path = path
        self.namespace = namespace
        self.extra_dll_paths = extra_dll_paths or []

    def is_installed(self):
        """Check if this USD build is installed."""
        return os.path.exists(os.path.join(self.path, "bin", "usdcat.exe"))

    def execute(self, code, timeout=30):
        """Execute Python code with this USD build."""
        if not self.is_installed():
            return "", f"USD build not found at {self.path}", 1

        env = os.environ.copy()

        # Set Python path for USD modules
        env['PYTHONPATH'] = os.path.join(self.path, "lib", "python")

        # Set PATH for DLLs (USD libs + uv Python for python311.dll)
        dll_paths = [
            UV_PYTHON_DIR,
            os.path.join(self.path, "bin"),
            os.path.join(self.path, "lib"),
        ]
        # Add extra DLL paths (e.g., TBB for custom build)
        dll_paths.extend(self.extra_dll_paths)
        env['PATH'] = ";".join(dll_paths) + ";" + env.get('PATH', '')

        # Set plugin path
        env['PXR_PLUGINPATH_NAME'] = os.path.join(self.path, "lib", "usd")

        result = subprocess.run(
            [sys.executable, '-c', code],
            capture_output=True,
            text=True,
            env=env,
            timeout=timeout
        )

        return result.stdout, result.stderr, result.returncode


# Create instances
ordinary = UsdVariant("ordinary_pxr", DIST_PXR, namespace="pxr")
# Custom build needs TBB DLLs from separate TBB installation
custom = UsdVariant(
    "custom_pxr_lte", DIST_LTE, namespace="pxr_lte",
    extra_dll_paths=[os.path.join(DIST_TBB, "bin")]
)


def check_installation():
    """Check if both USD builds are installed."""
    print("=" * 60)
    print("USD Dual Build Configuration (Windows)")
    print("=" * 60)
    print(f"Ordinary USD (pxr): {DIST_PXR}")
    print(f"  Installed: {ordinary.is_installed()}")
    print(f"Custom USD (pxr_lte): {DIST_LTE}")
    print(f"  Installed: {custom.is_installed()}")
    print(f"TBB (for custom build): {DIST_TBB}")
    print(f"  Exists: {os.path.exists(DIST_TBB)}")
    print(f"uv Python: {UV_PYTHON_DIR}")
    print(f"  Exists: {os.path.exists(UV_PYTHON_DIR)}")
    print("=" * 60)
    return ordinary.is_installed() and custom.is_installed()


if __name__ == "__main__":
    print("Testing USD Dual Wrapper (Windows)...")
    print()

    check_installation()
    print()

    test_code = """
from pxr import Usd
print(f"USD Version: {Usd.GetVersion()}")
stage = Usd.Stage.CreateInMemory()
prim = stage.DefinePrim("/TestPrim")
print(f"Created prim: {prim.GetPath()}")
"""

    print("[Test] Ordinary USD (pxr namespace):")
    if ordinary.is_installed():
        out, err, code = ordinary.execute(test_code)
        if code == 0:
            print(out)
        else:
            print(f"Error: {err}")
    else:
        print("  Not installed")

    print()
    print("[Test] Custom USD (pxr_lte namespace):")
    if custom.is_installed():
        out, err, code = custom.execute(test_code)
        if code == 0:
            print(out)
        else:
            print(f"Error: {err}")
    else:
        print("  Not installed")
