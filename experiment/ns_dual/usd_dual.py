
"""
usd_dual.py - Wrapper to access both USD builds via subprocess
"""
import subprocess
import sys
import json
import os

DIST_PXR = "/mnt/nvme02/work/usd-lte/dist-pxr"
DIST_LTE = "/mnt/nvme02/work/dist-usd-reldeb"

class UsdVariant:
    """Wrapper for a specific USD build."""

    def __init__(self, name, path):
        self.name = name
        self.path = path

    def execute(self, code):
        """Execute Python code with this USD build."""
        env = os.environ.copy()
        env['PYTHONPATH'] = f"{self.path}/lib/python"
        env['LD_LIBRARY_PATH'] = f"{self.path}/lib"

        result = subprocess.run(
            [sys.executable, '-c', code],
            capture_output=True,
            text=True,
            env=env
        )

        return result.stdout, result.stderr, result.returncode

# Create instances
ordinary = UsdVariant("ordinary", DIST_PXR)
custom = UsdVariant("custom_lte", DIST_LTE)

if __name__ == "__main__":
    print("Testing wrapper...")

    test = """
from pxr import Usd
print(f"USD Version: {Usd.GetVersion()}")
    """

    print("Ordinary USD:")
    out, err, code = ordinary.execute(test)
    print(out)

    print("Custom USD:")
    out, err, code = custom.execute(test)
    print(out)
