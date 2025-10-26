# USD Build Experiments

This directory contains experiments and proof-of-concept code for testing various USD build configurations and features.

## Experiments

### `ns_dual/` - Dual Namespace USD Loading

**Purpose:** Test loading both ordinary USD (standard `pxr` namespace) and custom namespace USD (`pxr_lte` namespace with `lte` library prefix) simultaneously.

**Key Question:** Can both USD builds coexist and be used from the same Python environment?

**Answer:** ✅ Yes, via subprocess isolation. Direct import in the same process conflicts, but using separate processes works perfectly.

**Status:** ✅ Complete

**Files:**
- `test_dual_usd.py` - Conflict demonstration
- `test_isolated_usd.py` - Subprocess isolation solution
- `usd_dual.py` - Wrapper module for dual USD access
- `example_use_both.py` - Practical usage example
- `DUAL_USD_USAGE.md` - Complete usage guide
- `EXPERIMENT_RESULTS.md` - Detailed findings
- `README.md` - Quick start guide

**Quick Start:**
```bash
cd ns_dual
python3 example_use_both.py
```

**Key Findings:**
- ✅ Custom namespace (`pxr_lte`) configured correctly
- ✅ Library prefixes (`lte*`) prevent binary conflicts
- ⚠️ Python bindings conflict (both use `pxr.*`)
- ✅ Subprocess isolation solves the problem
- ✅ Both builds produce identical USD output

## Future Experiments

### Planned Experiments

1. **Performance Benchmarking**
   - Compare build times
   - Runtime performance comparison
   - Memory usage analysis

2. **Binary Size Optimization**
   - Test minimal USD builds
   - Strip unnecessary components
   - Shared library dependencies

3. **Cross-Platform Testing**
   - Test on macOS ARM64
   - Test on Windows
   - Cross-compilation tests

4. **Plugin Isolation**
   - Test custom plugins with namespace isolation
   - Plugin ABI compatibility
   - Plugin discovery mechanisms

## Experiment Template

When creating a new experiment:

1. Create a new directory: `experiment/<experiment_name>/`
2. Include these files:
   - `README.md` - Overview and quick start
   - Test scripts/code
   - Documentation of findings
   - Example usage

3. Update this index with:
   - Experiment name and purpose
   - Status (planned/in-progress/complete)
   - Key findings
   - Links to detailed docs

## Related Documentation

- Parent directory: Main USD build scripts
- `../BUILD_SUMMARY.md` - Custom USD build details
- `../CLAUDE.md` - Development guidelines

## Contributing

To add a new experiment:

1. Create experiment directory under `experiment/`
2. Follow the template structure above
3. Document findings thoroughly
4. Update this index file
5. Add entry to parent directory's documentation if relevant

## Directory Structure

```
experiment/
├── README.md              (this file)
└── ns_dual/               (dual namespace experiment)
    ├── README.md          (quick start)
    ├── test_dual_usd.py
    ├── test_isolated_usd.py
    ├── usd_dual.py
    ├── example_use_both.py
    ├── DUAL_USD_USAGE.md
    └── EXPERIMENT_RESULTS.md
```

## Testing

All experiments should include:
- ✅ Test scripts that demonstrate the concept
- ✅ Documentation of findings
- ✅ Usage examples
- ✅ Known limitations and workarounds

## License

All experiment code follows the same license as the parent USD project (see LICENSE.txt in repository root).
