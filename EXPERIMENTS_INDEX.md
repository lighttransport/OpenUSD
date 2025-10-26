# USD Build Experiments Index

Quick reference to experiments and proof-of-concept code in this repository.

## Experiments Directory

All experiments are organized under `experiment/` directory.

### Dual Namespace USD Loading (`experiment/ns_dual/`)

**Purpose:** Test loading both ordinary USD and custom namespace USD simultaneously.

**Quick Start:**
```bash
cd experiment/ns_dual
python3 example_use_both.py
```

**Files:**
- 🧪 **Test Scripts**:
  - `test_dual_usd.py` - Shows conflicts when loading both in same process
  - `test_isolated_usd.py` - Demonstrates subprocess isolation solution
  - `example_use_both.py` - Practical usage example
  
- 📚 **Documentation**:
  - `README.md` - Quick start guide
  - `DUAL_USD_USAGE.md` - Complete usage guide (25+ pages)
  - `EXPERIMENT_RESULTS.md` - Detailed findings and analysis
  
- 🛠️ **Utilities**:
  - `usd_dual.py` - Wrapper module for accessing both USD builds
  - `test_cpp_dual_namespace.cpp` - C++ reference implementation

**Key Findings:**
- ✅ Custom namespace (`pxr_lte`) works correctly
- ✅ Library prefixes (`lte*`) prevent binary conflicts
- ⚠️ Python bindings conflict (both use `pxr.*` module names)
- ✅ **Solution:** Subprocess isolation via `usd_dual.py`
- ✅ Both builds produce identical USD output

**Status:** ✅ Complete

---

## Related Documentation

### Build Scripts
Located in repository root:
- `build-tbb.sh` - Build Intel oneTBB from source
- `build-lte-configure.sh` - Configure custom namespace USD
- `build-lte-build.sh` - Build and install custom USD
- `BUILD_SUMMARY.md` - Custom USD build details

### Development Guides
- `CLAUDE.md` - Development guidelines and architecture
- `BUILDING.md` - Official USD build instructions
- `README.md` - Main repository README

### Experiments
- `experiment/README.md` - All experiments index
- `experiment/ns_dual/README.md` - Dual namespace quick start

---

## Quick Navigation

### Run Dual Namespace Example
```bash
cd experiment/ns_dual
python3 example_use_both.py
```

### Read Detailed Findings
```bash
cat experiment/ns_dual/EXPERIMENT_RESULTS.md
```

### Use Dual USD in Your Code
```python
import sys
sys.path.insert(0, 'experiment/ns_dual')
from usd_dual import ordinary, custom

# Execute with ordinary USD
ordinary.execute("from pxr import Usd; print(Usd.GetVersion())")

# Execute with custom USD
custom.execute("from pxr import Usd; print(Usd.GetVersion())")
```

---

## Directory Structure

```
usd-lte/
├── EXPERIMENTS_INDEX.md (this file)
├── BUILD_SUMMARY.md
├── build-tbb.sh
├── build-lte-configure.sh
├── build-lte-build.sh
│
├── experiment/
│   ├── README.md              # Experiments overview
│   └── ns_dual/               # Dual namespace experiment
│       ├── README.md
│       ├── test_dual_usd.py
│       ├── test_isolated_usd.py
│       ├── usd_dual.py
│       ├── example_use_both.py
│       ├── test_cpp_dual_namespace.cpp
│       ├── DUAL_USD_USAGE.md
│       └── EXPERIMENT_RESULTS.md
│
├── dist-pxr/                  # Ordinary USD build
└── ../dist-usd-reldeb/        # Custom namespace USD build
```

---

## Adding New Experiments

1. Create directory: `experiment/<name>/`
2. Add test scripts and documentation
3. Update `experiment/README.md`
4. Update this index file
5. Follow template in `experiment/README.md`

---

## License

All experimental code follows the main USD project license.
See LICENSE.txt in repository root.
