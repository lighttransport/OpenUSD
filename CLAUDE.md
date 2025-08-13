# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

### Primary Build Method
- **Main build script**: `python build_scripts/build_usd.py /path/to/install/dir` - Downloads dependencies and builds USD
- **Cross-platform**: Windows (requires Visual Studio command prompt), Linux, macOS, iOS, visionOS
- **CMake direct build**: 
  ```bash
  cmake -DTBB_ROOT_DIR=/path/to/tbb -DOPENSUBDIV_ROOT_DIR=/path/to/opensubdiv /path/to/USD/source
  cmake --build . --target install -- -j <NUM_CORES>
  ```

### Testing
- **Run tests**: `ctest -C Release -V` (from build directory)
- **Specific test**: `ctest -C Release -R testUsdShade -V`
- **Build tests**: Enabled by default, disable with `-DPXR_BUILD_TESTS=FALSE`

### Build Configuration
- **Python support**: `-DPXR_ENABLE_PYTHON_SUPPORT=FALSE` to disable
- **Imaging/Hydra**: `-DPXR_BUILD_IMAGING=FALSE` to disable
- **USD tools**: `-DPXR_BUILD_USD_TOOLS=FALSE` to disable
- **Documentation**: `-DPXR_BUILD_DOCUMENTATION=TRUE` to enable

## High-Level Architecture

### Core Library Structure (`pxr/`)
- **`base/`** - Foundation libraries:
  - `arch` - Architecture/platform abstraction
  - `tf` - Tools Foundation (memory, strings, types, Python binding)
  - `gf` - Graphics Foundation (math, vectors, matrices)
  - `vt` - Value Types (arrays, dictionaries)
  - `work` - Task-based parallelism (TBB wrapper)
  - `trace` - Performance tracing

- **`usd/`** - USD Core:
  - `sdf` - Scene Description Foundations (layers, paths)
  - `pcp` - Prim Composition (layering, referencing, variants)
  - `usd` - Main USD API (stages, prims, attributes)
  - `usdGeom`, `usdShade`, `usdLux` - Schema libraries
  - `ar` - Asset Resolution

- **`imaging/`** - Hydra Rendering:
  - `hd` - Hydra core (render delegates, scene indices)
  - `hdSt` - Storm render delegate (OpenGL/Vulkan/Metal)
  - `hgi` - Hardware Graphics Interface abstraction
  - `glf` - OpenGL utilities

- **`usdImaging/`** - USD to Hydra bridge:
  - Scene delegates that connect USD to Hydra
  - `usdview` - Standalone USD viewer

- **`exec/`** - OpenExec execution framework (experimental):
  - Parallel scene processing and computation graphs

### Key Concepts
- **Stages**: USD's main container for scene description
- **Layers**: Individual files/data sources that compose into stages  
- **Prims**: Scene graph nodes with typed schemas
- **Scene Indices**: Hydra's scene representation for rendering
- **Render Delegates**: Hydra backends (Storm, RenderMan, Embree)

### Plugin Architecture
- Libraries use `plugInfo.json` metadata for discovery
- Plugin search via `PXR_PLUGINPATH_NAME` environment variable
- Schema registration through code generation (`usdGenSchema`)

### Build System
- **CMake-based** with custom macros in `cmake/`
- **Monolithic builds** supported via `-DPXR_BUILD_MONOLITHIC=ON`
- **Namespace configuration** via `PXR_SET_EXTERNAL_NAMESPACE`
- **Python bindings** auto-generated with Boost.Python

## USD Tools
- `usdcat` - Print USD file contents
- `usddiff` - Compare USD files  
- `usdview` - Interactive USD viewer
- `usdtree` - Show USD scene graph hierarchy
- `usdstitch` - Combine USD files
- `usdzip`/`usdcompress` - Package/compress USD files

## Development Workflow
1. **Edit source** in `pxr/` subdirectories
2. **Build with CMake** or `build_usd.py`
3. **Run tests** with `ctest`
4. **Test with usdview**: `usdview path/to/file.usd`

## Important Notes
- **64-bit only** - 32-bit builds not supported
- **C++14 minimum** requirement
- **TBB required** for task parallelism
- **Python optional** but recommended for tools and tests
- **OpenSubdiv required** for imaging features