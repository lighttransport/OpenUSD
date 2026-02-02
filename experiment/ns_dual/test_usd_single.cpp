/**
 * test_usd_single.cpp
 *
 * Test USD linking with a single build (either ordinary pxr or custom pxr_lte).
 * Build this with either USD installation to verify linking works.
 *
 * Build for Ordinary USD (pxr):
 *   cl /EHsc /std:c++17 /I "dist-pxrusd/include" test_usd_single.cpp
 *      /link /LIBPATH:"dist-pxrusd/lib" usd_tf.lib usd_sdf.lib usd_usd.lib
 *
 * Build for Custom USD (pxr_lte):
 *   cl /EHsc /std:c++17 /I "dist-usd-reldeb/include" test_usd_single.cpp
 *      /link /LIBPATH:"dist-usd-reldeb/lib" ltetf.lib ltesdf.lib lteusd.lib
 */

#include <iostream>
#include <string>

// USD includes - these resolve to either pxr or pxr_lte depending on build config
#include "pxr/pxr.h"
#include "pxr/usd/usd/stage.h"
#include "pxr/usd/usd/prim.h"
#include "pxr/usd/sdf/path.h"
#include "pxr/base/tf/token.h"

// Use the USD namespace (pxr or pxr_lte depending on build)
PXR_NAMESPACE_USING_DIRECTIVE

int main() {
    std::cout << "========================================\n";
    std::cout << "USD Single Build Test (C++)\n";
    std::cout << "========================================\n\n";

    // Print namespace info
#ifdef PXR_EXTERNAL_NAMESPACE
    std::cout << "External namespace: " << BOOST_PP_STRINGIZE(PXR_EXTERNAL_NAMESPACE) << "\n";
#else
    std::cout << "External namespace: pxr (default)\n";
#endif

    // Create an in-memory stage
    std::cout << "\nCreating in-memory USD stage...\n";
    auto stage = UsdStage::CreateInMemory();
    if (!stage) {
        std::cerr << "ERROR: Failed to create stage\n";
        return 1;
    }
    std::cout << "  Stage created successfully\n";

    // Define a prim
    std::cout << "\nDefining test prim...\n";
    SdfPath primPath("/TestPrim");
    auto prim = stage->DefinePrim(primPath);
    if (!prim.IsValid()) {
        std::cerr << "ERROR: Failed to create prim\n";
        return 1;
    }
    std::cout << "  Created prim: " << prim.GetPath() << "\n";

    // Set some metadata
    prim.SetDocumentation("Created by C++ test");
    std::cout << "  Set documentation metadata\n";

    // Export to string
    std::string usdaContent;
    stage->GetRootLayer()->ExportToString(&usdaContent);
    std::cout << "\nGenerated USDA:\n";
    std::cout << "----------------------------------------\n";
    std::cout << usdaContent;
    std::cout << "----------------------------------------\n";

    std::cout << "\nTest completed successfully!\n";
    std::cout << "========================================\n";

    return 0;
}
