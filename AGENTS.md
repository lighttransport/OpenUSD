# Repository Guidelines

## Project Structure & Module Organization
- `pxr/` houses core USD libraries (base, usd, imaging, usdImaging, exec) and most production code.
- `build_scripts/` contains build tooling like `build_usd.py`.
- `cmake/` holds USD-specific CMake modules and defaults.
- `docs/` and `extras/` include documentation, tutorials, and reference material.
- `third_party/` vendors external dependencies; treat as read-only unless updating a pinned version.
- Tests live alongside code under `pxr/**/testenv/`, with baselines in `pxr/**/testenv/**/baseline/`.

## Build, Test, and Development Commands
- `python build_scripts/build_usd.py /path/to/install` builds USD plus dependencies (primary workflow).
- `cmake -S . -B build -DTBB_ROOT_DIR=/path/to/tbb -DOPENSUBDIV_ROOT_DIR=/path/to/opensubdiv` configures a direct build.
- `cmake --build build --target install -- -j <NUM_CORES>` compiles and installs from the build directory.
- `ctest -C Release -V` runs the full test suite from the build directory.
- `ctest -C Release -R testUsdShade -V` runs a focused test selection.
- Helper scripts like `build-lte*.sh` and `build-lte*.bat` are repo-specific wrappers; check `BUILD_SUMMARY.md` for expected usage.

## Coding Style & Naming Conventions
- C++14 is the minimum standard; Python is used for tools and some tests.
- Use 4-space indentation and match the surrounding file’s brace/layout style; avoid reformatting unrelated code.
- File naming follows standard USD patterns (`*.cpp`, `*.h`, `test*.cpp`, `test*.py`), with tests colocated in `testenv/`.

## Testing Guidelines
- Tests are enabled by default; disable with `-DPXR_BUILD_TESTS=FALSE` only for constrained builds.
- Place new tests in the nearest `pxr/<area>/testenv/` with `test*` filenames and baseline assets in `baseline/`.
- There is no explicit coverage gate in this repo; add tests for new behavior and bug fixes when practical.

## Commit & Pull Request Guidelines
- Commit summaries are short and descriptive; component prefixes like `gf:` or `[usdGeom]` are common when scoped.
- PRs should link issues, describe behavior changes, and include build/test evidence (and screenshots for rendering/UI changes).
- Contributors are expected to follow `CONTRIBUTING.md` and complete the appropriate USD CLA (`USD_CLA_*.pdf`).

## Configuration & Environment Notes
- 64-bit builds only; 32-bit is not supported.
- TBB and OpenSubdiv are required for imaging features; Python support is optional but recommended for tools/tests.
