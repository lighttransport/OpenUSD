# OpenUSD Build Scripts

This repository contains multiple build approaches for OpenUSD on Windows.

## Build Methods

### 1. Official build_usd.py (Recommended for most users)

**Script**: `build-usd-minimal.bat`

Uses the official Pixar `build_usd.py` script which automatically downloads and builds all dependencies.

**Features**:
- Automatic dependency management (TBB, Boost, etc.)
- Minimal configuration (USD core only, no Hydra/imaging)
- RelWithDebInfo build
- Python 3.11 bindings (via uv)
- Install to: `../dist-pxrusd`

**Usage**:
```batch
REM 1. Install Python via uv
setup-uv-python.bat

REM 2. Build USD (downloads deps automatically)
build-usd-minimal.bat

REM 3. Setup environment
setup-pxrusd-env.bat

REM 4. Test
usdcat --help
```

**Pros**:
- Official supported method
- Handles all dependency downloads
- Easier for beginners
- Standard Pixar configuration

**Cons**:
- Downloads everything (slower initial setup)
- Less control over individual components
- Larger build artifacts

---

### 2. Manual CMake Build with Custom Namespace

**Scripts**: `build-lte-configure.bat`, `build-lte-build.bat`

Direct CMake configuration with custom namespace (`pxr_lte`) and pre-downloaded TBB.

**Features**:
- Custom namespace: `pxr_lte` (allows side-by-side with standard USD)
- Manual TBB setup via `build-tbb-prebuilt.bat`
- Fine-grained CMake control
- RelWithDebInfo build
- Python 3.11 bindings (via uv or rez)
- Install to: `../dist-usd-reldeb`

**Usage**:
```batch
REM 1. Setup Python environment (choose one)
setup-uv-python.bat
REM OR
setup-rez-python.bat

REM 2. Download TBB
build-tbb-prebuilt.bat

REM 3. Configure CMake
build-lte-configure.bat

REM 4. Build and install
build-lte-build.bat

REM 5. Setup environment
setup-usd-env.bat

REM 6. Test
usdcat --help
```

**Pros**:
- Custom namespace support
- Full CMake control
- Can co-exist with other USD builds
- Smaller dependency footprint (manual TBB only)

**Cons**:
- More manual steps
- Need to manage TBB separately
- More complex for beginners

---

## Python Environment Options

### uv (Recommended)

Fast Python package installer.

**Setup**:
```batch
setup-uv-python.bat
```

Creates:
- `.venv/` - Virtual environment with Jinja2, PySide6, PyOpenGL

### rez

Package management system for VFX/animation pipelines.

**Setup**:
```batch
setup-rez-python.bat
```

Creates:
- `.rez/` - Rez environment
- `.rez-packages/` - Rez package definitions

**Usage**:
```batch
.rez\activate.bat
rez-env python
```

---

## Build Configurations Comparison

| Feature | build_usd.py | Manual CMake |
|---------|-------------|--------------|
| **Namespace** | `pxr` (standard) | `pxr_lte` (custom) |
| **TBB** | Auto-download | Manual (prebuilt) |
| **Boost** | Auto-download | Auto-built |
| **Dependencies** | Automated | Manual |
| **Install Dir** | `../dist-pxrusd` | `../dist-usd-reldeb` |
| **Build Type** | RelWithDebInfo | RelWithDebInfo |
| **Python** | 3.11 (uv) | 3.11 (uv/rez) |
| **Imaging** | Disabled | Disabled |
| **Tools** | Enabled | Enabled |
| **Tests** | Disabled | Disabled |

---

## Environment Setup

Both builds provide environment setup scripts:

| Build Method | Setup Script |
|--------------|--------------|
| build_usd.py | `setup-pxrusd-env.bat` |
| Manual CMake | `setup-usd-env.bat` |

Both scripts set:
- `PATH` - USD binaries, libraries, Python DLLs
- `PYTHONPATH` - USD Python modules
- `PXR_PLUGINPATH_NAME` - USD plugins

---

## Directory Structure

```
OpenUSD/
├── build_scripts/
│   └── build_usd.py              # Official Pixar build script
├── build-usd-minimal.bat         # Wrapper for build_usd.py
├── build-tbb-prebuilt.bat        # Download prebuilt TBB (manual build)
├── build-lte-configure.bat       # CMake configure (manual build)
├── build-lte-build.bat           # CMake build (manual build)
├── setup-uv-python.bat           # Setup uv Python environment
├── setup-rez-python.bat          # Setup rez Python environment
├── setup-pxrusd-env.bat          # Runtime env for build_usd.py
└── setup-usd-env.bat             # Runtime env for manual build

../dist-pxrusd/                   # build_usd.py installation
../dist-usd-reldeb/               # Manual CMake installation
../dist-tbb-reldeb/               # TBB prebuilt (manual build)

.venv/                            # uv Python environment (gitignored)
.rez/                             # Rez environment (gitignored)
.rez-packages/                    # Rez packages (gitignored)
build-reldeb/                     # CMake build directory (gitignored)
build-custom/                     # TBB download cache (gitignored)
```

---

## Quick Start

**For standard USD development** (recommended):
```batch
setup-uv-python.bat
build-usd-minimal.bat
setup-pxrusd-env.bat
```

**For custom namespace or side-by-side builds**:
```batch
setup-uv-python.bat
build-tbb-prebuilt.bat
build-lte-configure.bat
build-lte-build.bat
setup-usd-env.bat
```
