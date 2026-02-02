#!/usr/bin/env python
# Copyright 2024 Pixar
# Licensed under the terms set forth in the LICENSE.txt file available at
# https://openusd.org/license.
"""
Patch moduleDeps.cpp to use a custom Python package name.

Usage: python patchModuleDeps.py <input_file> <output_file> <package_name>
"""

import sys

if len(sys.argv) != 4:
    print("Usage: patchModuleDeps.py <input_file> <output_file> <package_name>")
    sys.exit(1)

input_file = sys.argv[1]
output_file = sys.argv[2]
package_name = sys.argv[3]

with open(input_file, 'r') as f:
    content = f.read()

# Replace pxr. with the custom package name
content = content.replace('TfToken("pxr.', f'TfToken("{package_name}.')

with open(output_file, 'w') as f:
    f.write(content)
