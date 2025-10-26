# USD LTE Build Summary

## Build Configuration
- **Custom Namespace**: `pxr_lte`
- **Library Prefix**: `lte`
- **Build Type**: RelWithDebInfo
- **Install Location**: `/mnt/nvme02/work/dist-usd-reldeb`

## Build Results

### Libraries Built
- **Total Libraries**: 45 shared libraries with `lte` prefix
- **Core Libraries**: lteusd.so (107MB), ltesdf.so (256MB), ltepcp.so (45MB)
- **Geometry**: lteusdGeom.so (50MB)
- **Shading**: lteusdShade.so (21MB)
- **Execution**: lteexec.so (79MB)

### Tools Built
- `usdcat` - USD file viewer
- `usdtree` - USD hierarchy viewer
- `usdchecker` - USD validation tool
- `sdfdump` - SDF layer dump tool
- `sdffilter` - SDF layer filter
- And 9 other USD utilities

### Installation Size
- **Total**: 2.6 GB

## Library Verification
All libraries are correctly prefixed with `lte`:
```bash
$ ls /mnt/nvme02/work/dist-usd-reldeb/lib/lte*.so | head -5
ltearch.so
ltear.so
lteboost.so
lteef.so
lteesf.so
...
```

Tools correctly link to prefixed libraries:
```bash
$ ldd /mnt/nvme02/work/dist-usd-reldeb/bin/usdcat | grep lte
lteusdUtils.so
lteusd.so
ltesdf.so
ltetf.so
ltepython.so
...
```

## Usage

To use this build, set the following environment variables:

```bash
export PYTHONPATH=/mnt/nvme02/work/dist-usd-reldeb/lib/python:${PYTHONPATH}
export LD_LIBRARY_PATH=/mnt/nvme02/work/dist-usd-reldeb/lib:${LD_LIBRARY_PATH}
export PATH=/mnt/nvme02/work/dist-usd-reldeb/bin:${PATH}
```

## Build Scripts

### 1. Build TBB (one-time)
```bash
./build-tbb.sh
```

### 2. Configure USD
```bash
./build-lte-configure.sh
```

### 3. Build USD
```bash
./build-lte-build.sh
```

## Features Enabled
- ✅ Python bindings
- ✅ USD core libraries
- ✅ USD tools
- ✅ USD validation
- ❌ Imaging (disabled)
- ❌ USD Imaging (disabled)
- ❌ usdview (disabled)
- ❌ Plugins: Alembic, Draco, MaterialX, OpenImageIO, OpenColorIO, Embree, Vulkan

## Build Time
- Configuration: ~1 second
- Compilation: ~2 minutes (32 parallel jobs)

## Dependencies
- Intel oneTBB 2021.12.0 (built from source)
- Python 3.11.9
- CMake with Ninja generator
