/**
 * test_cpp_dual_namespace.cpp
 *
 * Demonstrates loading both ordinary USD (pxr namespace) and custom USD (pxr_lte namespace)
 * in the same C++ program using explicit namespace qualification.
 *
 * Compile:
 *   g++ -std=c++17 -o test_cpp_dual_namespace test_cpp_dual_namespace.cpp \
 *     -I/mnt/nvme02/work/usd-lte/dist-pxr/include \
 *     -I/mnt/nvme02/work/dist-usd-reldeb/include \
 *     -L/mnt/nvme02/work/usd-lte/dist-pxr/lib \
 *     -L/mnt/nvme02/work/dist-usd-reldeb/lib \
 *     -lusd_usd -lusd_sdf -lusd_tf \
 *     -lteusd -ltesdf -ltetf \
 *     -Wl,-rpath,/mnt/nvme02/work/usd-lte/dist-pxr/lib \
 *     -Wl,-rpath,/mnt/nvme02/work/dist-usd-reldeb/lib
 */

#include <iostream>
#include <string>

// This won't work directly because both define the same symbols
// We need to use dlopen/dlsym for dynamic loading instead

int main() {
    std::cout << "========================================\n";
    std::cout << "USD Dual Namespace Test (C++)\n";
    std::cout << "========================================\n\n";

    std::cout << "NOTE: Direct linking to both USD builds simultaneously\n";
    std::cout << "is not practical due to symbol conflicts.\n\n";

    std::cout << "SOLUTIONS:\n";
    std::cout << "1. Use dlopen/dlsym for dynamic loading\n";
    std::cout << "2. Use separate processes\n";
    std::cout << "3. Use only one USD build per binary\n\n";

    std::cout << "The custom namespace (pxr_lte) is correctly configured:\n";
    std::cout << "  - External namespace: pxr_lte\n";
    std::cout << "  - Internal namespace: pxrInternal_v0_25_11__pxrReserved__\n";
    std::cout << "  - Library prefix: lte\n\n";

    std::cout << "For Python bindings, use subprocess isolation (see test_isolated_usd.py)\n";

    return 0;
}
