# Building USD v26.05 (Custom Namespace) with llvm-mingw

Status of an in-progress experiment to build the `v26.05-custom-namespace`
branch using the [llvm-mingw](https://github.com/mstorsjo/llvm-mingw)
toolchain (`x86_64-w64-mingw32-clang`/`clang++`) instead of MSVC, as an
alternative to the Visual Studio 2022 build documented in
[v26.05_custom_namespace_build.md](v26.05_custom_namespace_build.md).

**This is not yet a working build.** It gets substantially far (most core
libraries and several Python wrapper modules build and link), but stops on a
class of bug that is not fully enumerated yet. See
[Current Status](#current-status) below.

## Toolchain

- llvm-mingw: `D:\local\llvm-mingw-20260602-ucrt-x86_64` (clang 22.1.7,
  target `x86_64-w64-windows-gnu`)
- Generator: Ninja (not Visual Studio)
- Python: 3.12.12, installed via `uv python install 3.12` (works equally with
  3.11; not version-specific)
- TBB: **oneTBB 2021.9.0 built from source with this same toolchain** — see
  below for why the prebuilt MSVC-built TBB (`dist-tbb-reldeb`) cannot be used

## Why TBB Had to Be Rebuilt

The existing `dist-tbb-reldeb` (TBB 2020.3, built with MSVC) cannot be linked
against from mingw-clang for two independent reasons, discovered in order:

1. **Header incompatibility**: `tbb/task.h` constructs an out-of-range enum
   value in a `static const` in-class initializer (`kind_type(bound+1)`,
   `kind_type` only has 2 legal enumerators). MSVC tolerates this; clang 22
   correctly rejects it as a non-constant-expression hard error. Workaround
   attempted: patching the field types to `uintptr_t` (fixes compilation),
   but see #2.
2. **C++ ABI mismatch**: even after fixing #1, linking fails with undefined
   symbols like `tbb::task_group_context::is_group_execution_cancelled()`.
   The prebuilt `tbb.lib` exports **MSVC-mangled** C++ symbols
   (`?is_group_execution_cancelled@task_group_context@tbb@@...`), completely
   different from the Itanium mangling clang/lld produce for the same C++
   signatures. No linker flag bridges this — it's two different, incompatible
   binary interfaces for the same C++ API.

**Resolution**: cloned oneTBB v2021.9.0 (a modern, actively-maintained release
with a from-scratch CMake build, unrelated header/API surface to the old
2020.3 tree) and built it with the same llvm-mingw toolchain:

```bash
git clone --depth 1 --branch v2021.9.0 https://github.com/oneapi-src/oneTBB.git
mkdir build-tbb-mingw && cd build-tbb-mingw
cmake -G Ninja \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_C_COMPILER=D:/local/llvm-mingw-20260602-ucrt-x86_64/bin/x86_64-w64-mingw32-clang.exe \
    -DCMAKE_CXX_COMPILER=D:/local/llvm-mingw-20260602-ucrt-x86_64/bin/x86_64-w64-mingw32-clang++.exe \
    -DCMAKE_RC_COMPILER=D:/local/llvm-mingw-20260602-ucrt-x86_64/bin/x86_64-w64-mingw32-windres.exe \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=../dist-tbb-mingw \
    -DTBB_TEST=OFF -DTBB_STRICT=OFF \
    ../oneTBB
cmake --build . --parallel
cmake --build . --target install
```

Two configure-time gotchas:
- `-DCMAKE_POLICY_VERSION_MINIMUM=3.5` is required — CMake 4.x rejects
  oneTBB's old `cmake_minimum_required` outright otherwise.
- `-DCMAKE_RC_COMPILER` **must** be passed on the very first configure of a
  fresh build directory. CMake's RC-compiler auto-detection (falls back to a
  bare `windres`, not found on `PATH`) gets baked into
  `CMakeFiles/<ver>/CMakeRCCompiler.cmake` on first run and is not
  re-detected by a later `cmake -DCMAKE_RC_COMPILER=... .` re-run in the same
  build dir — you must wipe and reconfigure from scratch.

Verified with a smoke test using modern oneTBB API (`tbb::parallel_for`,
`tbb::info::default_concurrency()`) — compiles, links, and runs correctly.

Note: oneTBB 2021.9.0 has a different (much smaller, modernized) API surface
than TBB 2020.3 — e.g. `tbb::task_scheduler_init` is gone. USD v26.05's CMake
(`find_package(TBB CONFIG COMPONENTS tbb)` in `cmake/defaults/Packages.cmake`)
picks up oneTBB's own generated `TBBConfig.cmake` automatically when pointed
at it via `-DTBB_DIR=.../dist-tbb-mingw/lib/cmake/TBB`, so no USD-side TBB
detection changes were needed.

## CMake Configure Flags (non-monolithic core-library build)

```bash
cmake -G Ninja \
    -DCMAKE_C_COMPILER=D:/local/llvm-mingw-20260602-ucrt-x86_64/bin/x86_64-w64-mingw32-clang.exe \
    -DCMAKE_CXX_COMPILER=D:/local/llvm-mingw-20260602-ucrt-x86_64/bin/x86_64-w64-mingw32-clang++.exe \
    -DCMAKE_RC_COMPILER=D:/local/llvm-mingw-20260602-ucrt-x86_64/bin/x86_64-w64-mingw32-windres.exe \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=.../dist-usd-lte-mingw-v26.05 \
    -DPXR_ENABLE_PYTHON_SUPPORT=ON \
    -DPython3_EXECUTABLE=.../cpython-3.12.12-windows-x86_64-none/python.exe \
    -DPython3_INCLUDE_DIR=.../cpython-3.12.12-windows-x86_64-none/include \
    -DPython3_LIBRARY=.../cpython-3.12.12-windows-x86_64-none/libs/python312.lib \
    -DPXR_PYTHON_SHEBANG=.../python.exe \
    -DTBB_DIR=.../dist-tbb-mingw/lib/cmake/TBB \
    -DPXR_ENABLE_NAMESPACES=ON \
    -DPXR_SET_EXTERNAL_NAMESPACE=pxr_lte \
    -DPXR_LIB_PREFIX=lte_ \
    -DPXR_PYTHON_PACKAGE_NAME=pxr_lte \
    -DPXR_BUILD_IMAGING=OFF -DPXR_BUILD_USD_IMAGING=OFF -DPXR_BUILD_USDVIEW=OFF \
    -DPXR_BUILD_TESTS=OFF -DPXR_BUILD_EXAMPLES=OFF -DPXR_BUILD_TUTORIALS=OFF \
    -DPXR_BUILD_DOCUMENTATION=OFF -DPXR_BUILD_USD_TOOLS=ON \
    -DPXR_ENABLE_MATERIALX_SUPPORT=OFF \
    -DCMAKE_CXX_FLAGS="-D__TBB_NO_IMPLICIT_LINKAGE -DNOMINMAX" \
    <source dir>
```

For a monolithic build (see [Current Status](#current-status) for why this
matters), add `-DPXR_BUILD_MONOLITHIC=ON` and use a separate build/install
directory.

## Source Fixes Required

All fixes below are scoped as tightly as possible (usually
`#if defined(ARCH_OS_WINDOWS) && !defined(ARCH_COMPILER_MSVC)`, or
unconditional only when the change is a strict portability correction with
no possible effect on MSVC/Linux/macOS) to avoid any risk of regressing the
already-verified MSVC build.

### 1. CMake: PDB install rules gated on `WIN32` alone

`cmake/macros/Private.cmake` (x2) and `cmake/macros/Public.cmake` (x1) had
`install(FILES $<TARGET_PDB_FILE:...>)` guarded only by `if(WIN32)`. PDBs are
an MSVC/link.exe-only concept; lld/mingw don't produce them, and the
`$<TARGET_PDB_FILE:...>` generator expression itself is a **hard configure
error** ("TARGET_PDB_FILE is not supported by the target linker") for a
non-MSVC linker, not just a missing-file warning. Fixed by changing the guard
to `if(WIN32 AND MSVC)` in all three spots.

### 2. `pxr/base/arch/attributes.h`: constructor/destructor section mechanism

USD uses `ARCH_CONSTRUCTOR`/`ARCH_DESTRUCTOR` macros (backing
`TF_REGISTRY_FUNCTION` and friends) that place a small struct into a named
linker section (`.pxrctor`/`.pxrdtor`), later walked at runtime by scanning
the PE/Mach-O/ELF section table. The `#elif` chain choosing the
implementation checked `ARCH_COMPILER_GCC || ARCH_COMPILER_CLANG` *before*
`ARCH_OS_WINDOWS`, so a Windows+clang build (any clang, not just mingw) took
the Linux/macOS-style branch — which doesn't even declare
`Arch_ConstructorEntry`/`Arch_ConstructorInit` — a straight-up compile error.

Fix:
- Added `&& !defined(ARCH_OS_WINDOWS)` to the GCC/clang branch's condition so
  Windows always reaches the `ARCH_OS_WINDOWS` branch regardless of compiler.
- Inside the Windows branch, split the entry-emitting macros by compiler:
  MSVC keeps its original `__declspec(allocate(".pxrctor"))` +
  `#pragma section(...)` mechanism unchanged; added a GCC/clang path using
  `__attribute__((used, section(".pxrctor")))` instead (confirmed empirically
  that `__declspec(allocate(...))` is silently *ignored* — not merely
  unavailable — under mingw-clang, which would have caused silent runtime
  registration failures rather than a compile error).
- Changed `__declspec(align(16))` on the shared `Arch_ConstructorEntry` struct
  to portable `alignas(16)` (both compilers honor this identically; avoids
  divergent behavior for no reason).

The runtime section-scanning code in `attributes.cpp` needed no changes — it
only depends on `ARCH_OS_WINDOWS`, and scans the PE section table by name
regardless of which compiler produced it.

### 3. `pxr/base/arch/library.cpp`: `GetProcAddress` return type

```cpp
return GetProcAddress(...);  // FARPROC -> void* implicit conversion
```
MSVC/GCC allow this as an extension; clang doesn't (function-pointer-to-
object-pointer implicit conversion is not standard C++). Fixed with an
explicit `reinterpret_cast<void*>(...)`. Unconditional — a strict portability
fix with no platform-specific behavior change.

### 4. `pxr/base/arch/fileSystem.cpp`: missing `<share.h>`

`_SH_DENYNO` (used with `_sopen`) isn't declared without including
`<share.h>` explicitly on this toolchain (MSVC's `<io.h>` apparently pulls it
in transitively; mingw's doesn't). Added `#include <share.h>` to the existing
`ARCH_OS_WINDOWS` include block. Unconditional, no defined() guard needed
since `share.h` exists in both MSVC's and mingw's CRT.

### 5. `pxr/base/arch/errno.cpp`: `strerror_r` vs `strerror_s`

```cpp
#elif !defined(ARCH_COMPILER_MSVC)
    strerror_r(errorCode, msg_buf, 256);   // POSIX-only, not in Windows UCRT
#else
    strerror_s(msg_buf, 256, errorCode);
```
The condition was compiler-based (`!MSVC`) when it should have been OS-based:
Windows' UCRT (used by *any* compiler on Windows, MSVC or mingw) only
provides `strerror_s`, never the POSIX `strerror_r`. Changed the condition
to `!defined(ARCH_OS_WINDOWS)`.

### 6. The big one: `TF_API`-annotated inline singleton accessors

This is the most structurally significant fix, and the one still generating
new occurrences as the build progresses further into the tree (see
[Current Status](#current-status)).

**Root cause.** Many classes expose their `TfSingleton`-backed instance via a
pattern like this, written directly in the header:

```cpp
class TfScriptModuleLoader : public TfWeakBase {
public:
    typedef TfScriptModuleLoader This;
    TF_API static This &GetInstance() {
        return TfSingleton<This>::GetInstance();   // inline body!
    }
```

`TF_API` expands to `__declspec(dllexport)` when compiling the owning
library, `__declspec(dllimport)` (`__attribute__((dllimport))` under clang)
everywhere else. **MSVC has a documented, MSVC-specific rule**: a function
marked `dllimport` is *never* inlined, even if its definition is visible —
the compiler always emits a call through the imported symbol. This is
exactly why Pixar's code can get away with `TfSingleton<T>`'s internals
(`_instance`, `_CreateOrWaitForInstance`, etc.) never being exported from the
owning DLL: every consumer, even though it can see the inline body, is forced
by MSVC to call the one real definition living in the owning DLL.

**mingw-clang does not implement this MSVC-only rule.** It inlines the
wrapper's body into the consumer anyway, so the consumer ends up directly
referencing `TfSingleton<T>::_instance` / `_CreateOrWaitForInstance` — private
implementation details that were never exported from the owning DLL, causing
`ld.lld: undefined symbol` at link time for every DLL boundary this crosses.

**First fix attempt (rejected): export `TfSingleton<T>`'s explicit
instantiation.** Tried making `TF_INSTANTIATE_SINGLETON(T)` add
`ARCH_EXPORT`/dllexport on Windows-non-MSVC. Confirmed via a minimal repro
that clang **refuses** this with `warning: 'dllexport' attribute ignored on
explicit instantiation definition — 'dllexport' attribute is missing on
previous declaration`. The "previous declaration" is the *primary* class
template (`template <class T> class TfSingleton { ... };`, deliberately
unattributed since it's generic and shared by every T). Clang requires
dllexport/dllimport consistency across every declaration of an entity; you
cannot retroactively add the attribute only at the explicit-instantiation
point. This is a hard wall, not a workaround-able warning — reverted.

**Actual fix: make the wrapper genuinely non-inline.** Move the body out of
the header, guarded to Windows-non-MSVC only:

```cpp
// header
#if defined(ARCH_OS_WINDOWS) && !defined(ARCH_COMPILER_MSVC)
    TF_API static This &GetInstance();               // declaration only
#else
    TF_API static This &GetInstance() {               // unchanged elsewhere
        return TfSingleton<This>::GetInstance();
    }
#endif

// .cpp, right after TF_INSTANTIATE_SINGLETON(T)
#if defined(ARCH_OS_WINDOWS) && !defined(ARCH_COMPILER_MSVC)
This &This::GetInstance() { return TfSingleton<This>::GetInstance(); }
#endif
```

This sidesteps the whole export/import question: `TfSingleton<T>`'s internals
are now referenced *only* from the one `.cpp` that owns the explicit
instantiation, so they never need to cross a DLL boundary at all, on any
compiler.

**Classes fixed so far with this exact pattern** (each discovered one at a
time via a link failure, then fixed and the build re-run):

| Class | Files |
|---|---|
| `TfScriptModuleLoader` | `pxr/base/tf/scriptModuleLoader.h`, `.cpp` |
| `TfDiagnosticMgr` | `pxr/base/tf/diagnosticMgr.h`, `.cpp` |
| `Tf_PyEnumRegistry` | `pxr/base/tf/pyEnum.h`, `.cpp` |
| `TfRefPtrTracker` | `pxr/base/tf/refPtrTracker.h`, `.cpp` |
| `TraceCollector` | `pxr/base/trace/collector.h`, `.cpp` |
| `Vt_ValueFromPythonRegistry` | `pxr/base/vt/valueFromPython.h`, `.cpp` |
| `SdfSchema` | `pxr/usd/sdf/schema.h`, `.cpp` |
| `UsdSchemaRegistry` | `pxr/usd/usd/schemaRegistry.h`, `.cpp` |

## Current Status

**Non-monolithic (regular per-library shared-lib) build**: blocked broadly.
Every cross-library DLL boundary that touches one of these singleton-style
accessors hits the bug above, and with dozens of core libraries this is a
large, open-ended surface.

**Switched to `-DPXR_BUILD_MONOLITHIC=ON`.** This collapses nearly all
*core* library-to-library DLL boundaries into a single `lte_usd_ms.dll`, so
the bug above only remains at the boundary between that one monolithic DLL
and each separate Python wrapper module (`_tf.pyd`, `_usd.pyd`,
`_usdGeom.pyd`, etc. — these always stay separate `.pyd` files regardless of
monolithic core). This is a *much* smaller, more tractable surface, and it
converged nicely for several modules in a row: after the 8 fixes above,
`_tf`, `_trace`, `_ts`, `_sdf`, and `_usd` all build and link successfully.

**Where it stopped**: `_usdGeom.pyd` hit a **new kind of instance of the same
root cause**, not a `TfSingleton`:

```cpp
// pxr/usd/usdGeom/hermiteCurves.h
class UsdGeomHermiteCurves::PointAndTangentArrays {
    explicit PointAndTangentArrays(const VtVec3fArray& interleaved);  // never exported
    ...
    USDGEOM_API static PointAndTangentArrays Separate(const VtVec3fArray& interleaved) {
        return PointAndTangentArrays(interleaved);   // inline body, same problem
    }
};
```

This confirms the underlying issue is not specific to `TfSingleton` — it's a
general property of *any* `XXX_API`-annotated inline function anywhere in the
codebase that touches something not independently exported. That makes the
remaining surface area unbounded-in-practice: it can only be discovered one
link failure at a time, in any of the remaining libraries (`usdShade`,
`usdLux`, `usdSkel`, `usdPhysics`, `usdRender`, etc.), each requiring its own
case-by-case fix using the same non-inline pattern.

**Not yet attempted / open questions:**
- Whether there's a smaller number of *distinct* API-inline-accessor patterns
  left (vs. this being genuinely scattered across every schema/module), which
  would determine whether finishing this is a small tail or a long one.
- Whether a more systemic fix is possible/worthwhile — e.g. a compiler flag
  or attribute that forces clang to honor MSVC's "dllimport never inlines"
  semantics globally, rather than fixing each occurrence by hand. (Not
  investigated; `-fno-inline-functions` etc. would be far too heavy-handed,
  and no MSVC-compatibility clang flag for this specific behavior is known
  to exist for the mingw/GNU target as opposed to the MSVC target.)
- Building for the MSVC-ABI target instead of mingw/GNU (i.e. `clang-cl`
  against the real MSVC STL/CRT via the Visual Studio installation already
  present) would very likely sidestep both this issue and the original
  TBB ABI mismatch, since MSVC-ABI semantics would apply. This was
  deliberately not pursued since the user specifically asked for the
  llvm-mingw (GNU-environment) toolchain at `D:\local\llvm-mingw-...`, which
  does not bundle MSVC-compatible headers/libs and isn't really meant for
  this mode of use.

## Build Directories (local, not committed)

- `../oneTBB` — oneTBB v2021.9.0 source checkout
- `build-tbb-mingw` / `../dist-tbb-mingw` — mingw-built TBB
- `build-lte-mingw` / `../dist-usd-lte-mingw-v26.05` — non-monolithic attempt
  (blocked, see above)
- `build-lte-mingw-mono` / `../dist-usd-lte-mingw-mono-v26.05` — monolithic
  attempt (furthest progress, currently stopped at `_usdGeom.pyd`)
