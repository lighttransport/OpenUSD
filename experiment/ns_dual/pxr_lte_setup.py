"""
Helper module for setting up custom namespace USD (pxr_lte) alongside standard USD.

This module automatically configures Python paths and DLL search directories
to allow importing both 'pxr' (standard USD) and 'pxr_lte' (custom namespace USD)
in the same Python process.

Usage:
    # Method 1: Import to auto-setup
    import pxr_lte_setup
    from pxr import Usd as StandardUsd
    from pxr_lte import Usd as CustomUsd

    # Method 2: Explicit setup with custom paths
    import pxr_lte_setup
    pxr_lte_setup.setup(
        custom_usd_root="C:/path/to/dist-usd-lte",
        tbb_root="C:/path/to/tbb"
    )
    from pxr_lte import Usd

Environment Variables:
    CUSTOM_USD_ROOT - Path to custom USD installation (default: ~/dist-usd-lte)
    TBB_ROOT        - Path to TBB installation (default: ~/dist-tbb-reldeb)
"""

import sys
import os
import platform
from pathlib import Path

__version__ = "1.0.0"
__all__ = ["setup", "is_setup", "get_paths"]

# Module state
_is_setup = False
_paths = {}

# Default paths (can be overridden via environment variables or setup())
DEFAULT_CUSTOM_USD_ROOT = Path.home() / "work" / "dist-usd-lte"
DEFAULT_TBB_ROOT = Path.home() / "work" / "dist-tbb-reldeb"


def get_paths():
    """Get the currently configured paths.

    Returns:
        dict: Dictionary with 'custom_usd_root' and 'tbb_root' keys
    """
    return _paths.copy()


def is_setup():
    """Check if setup has been called.

    Returns:
        bool: True if setup() has been called
    """
    return _is_setup


def setup(custom_usd_root=None, tbb_root=None, verbose=False):
    """Set up paths for custom namespace USD.

    This function adds the necessary DLL search directories and Python paths
    to enable importing pxr_lte alongside standard pxr.

    Args:
        custom_usd_root: Path to custom USD installation.
                        Defaults to CUSTOM_USD_ROOT env var or ~/dist-usd-lte
        tbb_root: Path to TBB installation.
                 Defaults to TBB_ROOT env var or ~/dist-tbb-reldeb
        verbose: If True, print setup information

    Returns:
        bool: True if setup was successful
    """
    global _is_setup, _paths

    # Resolve paths
    if custom_usd_root is None:
        custom_usd_root = os.environ.get(
            "CUSTOM_USD_ROOT",
            str(DEFAULT_CUSTOM_USD_ROOT)
        )
    if tbb_root is None:
        tbb_root = os.environ.get(
            "TBB_ROOT",
            str(DEFAULT_TBB_ROOT)
        )

    custom_usd_root = Path(custom_usd_root)
    tbb_root = Path(tbb_root)

    # Derive paths
    custom_lib = custom_usd_root / "lib"
    custom_bin = custom_usd_root / "bin"
    custom_python = custom_lib / "python"
    tbb_bin = tbb_root / "bin"

    # Store paths
    _paths = {
        "custom_usd_root": str(custom_usd_root),
        "tbb_root": str(tbb_root),
        "custom_lib": str(custom_lib),
        "custom_bin": str(custom_bin),
        "custom_python": str(custom_python),
        "tbb_bin": str(tbb_bin),
    }

    if verbose:
        print(f"Setting up pxr_lte paths:")
        print(f"  Custom USD root: {custom_usd_root}")
        print(f"  TBB root: {tbb_root}")

    # Validate paths
    if not custom_python.exists():
        if verbose:
            print(f"  WARNING: Python path does not exist: {custom_python}")
        # Don't fail - user might want to set up before installation

    # Add DLL directories (Windows only, Python 3.8+)
    if platform.system() == "Windows":
        dll_dirs = [custom_lib, custom_bin, tbb_bin]
        for dll_dir in dll_dirs:
            if dll_dir.exists():
                try:
                    os.add_dll_directory(str(dll_dir))
                    if verbose:
                        print(f"  Added DLL directory: {dll_dir}")
                except Exception as e:
                    if verbose:
                        print(f"  WARNING: Failed to add DLL directory {dll_dir}: {e}")

    # Add Python path
    custom_python_str = str(custom_python)
    if custom_python_str not in sys.path:
        sys.path.insert(0, custom_python_str)
        if verbose:
            print(f"  Added Python path: {custom_python}")

    _is_setup = True

    if verbose:
        print("  Setup complete!")

    return True


def _auto_setup():
    """Automatically run setup on module import."""
    global _is_setup

    # Only auto-setup if not already done
    if not _is_setup:
        # Check if pxr_lte is already importable (no setup needed)
        try:
            import pxr_lte
            # Already works, just mark as setup
            _is_setup = True
        except ImportError:
            # Need to set up paths
            # Use silent setup by default; users can call setup(verbose=True) for details
            setup(verbose=False)


# Auto-setup on import
_auto_setup()


# Convenience function to verify setup
def verify():
    """Verify that both pxr and pxr_lte can be imported.

    Returns:
        tuple: (pxr_ok, pxr_lte_ok) - True if import succeeded

    Raises:
        RuntimeError: If setup() hasn't been called
    """
    if not _is_setup:
        raise RuntimeError("setup() must be called before verify()")

    pxr_ok = False
    pxr_lte_ok = False

    try:
        from pxr import Tf
        pxr_ok = True
    except ImportError:
        pass

    try:
        from pxr_lte import Tf
        pxr_lte_ok = True
    except ImportError:
        pass

    return pxr_ok, pxr_lte_ok


if __name__ == "__main__":
    # When run as script, do verbose setup and verification
    print("pxr_lte_setup - Dual USD Setup Helper")
    print("=" * 50)

    setup(verbose=True)

    print()
    print("Verification:")
    pxr_ok, pxr_lte_ok = verify()
    print(f"  pxr import: {'OK' if pxr_ok else 'NOT AVAILABLE (needs separate setup)'}")
    print(f"  pxr_lte import: {'OK' if pxr_lte_ok else 'FAILED'}")

    if pxr_lte_ok:
        print()
        print("SUCCESS: pxr_lte can be imported!")
        print()
        print("Example usage:")
        print("  import pxr_lte_setup  # Auto-configures paths")
        print("  from pxr_lte import Usd as CustomUsd")
        if pxr_ok:
            print()
            print("  # Standard pxr is also available:")
            print("  from pxr import Usd as StandardUsd")
        else:
            print()
            print("  # Note: Standard pxr requires separate setup")
            print("  # (pip install usd-core, or add pxr build to PYTHONPATH)")
    else:
        print()
        print("pxr_lte import failed. Check build and paths.")
        sys.exit(1)
