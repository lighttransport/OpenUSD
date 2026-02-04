/**
 * test_usd_single.cpp
 *
 * Test USD linking with a single build (pxr_lte custom namespace v24.11).
 * Build this with the custom USD installation to verify linking works.
 *
 * Build for Custom USD v24.11 (pxr_lte):
 *   cl /EHsc /std:c++17 /MD /I "dist-usd-lte-v24.11/include" test_usd_single.cpp
 *      /link /LIBPATH:"dist-usd-lte-v24.11/lib" lte_tf.lib lte_sdf.lib lte_usd.lib
 */

#include <iostream>
#include <string>

// USD includes - these resolve to pxr_lte namespace
#include "pxr/pxr.h"
#include "pxr/usd/usd/stage.h"
#include "pxr/usd/usd/prim.h"
#include "pxr/usd/sdf/path.h"
#include "pxr/base/tf/token.h"

// Use the USD namespace (pxr_lte for custom build)
PXR_NAMESPACE_USING_DIRECTIVE

int main() {
    std::cout << "========================================\n";
    std::cout << "USD v24.11 Single Build Test (C++)\n";
    std::cout << "========================================\n\n";

    // Print namespace info
#ifdef PXR_EXTERNAL_NAMESPACE
    std::cout << "External namespace: " << BOOST_PP_STRINGIZE(PXR_EXTERNAL_NAMESPACE) << "\n";
#else
    std::cout << "External namespace: pxr (default)\n";
#endif

#ifdef PXR_INTERNAL_NS
    std::cout << "Internal namespace: " << BOOST_PP_STRINGIZE(PXR_INTERNAL_NS) << "\n";
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

    // Define child prims
    std::cout << "\nDefining child prims...\n";
    auto childXform = stage->DefinePrim(SdfPath("/TestPrim/Xform"), TfToken("Xform"));
    auto childMesh = stage->DefinePrim(SdfPath("/TestPrim/Mesh"), TfToken("Mesh"));
    std::cout << "  Created: " << childXform.GetPath() << " (" << childXform.GetTypeName() << ")\n";
    std::cout << "  Created: " << childMesh.GetPath() << " (" << childMesh.GetTypeName() << ")\n";

    // Set some metadata
    prim.SetDocumentation("Created by C++ test for USD v24.11");
    stage->SetMetadata(TfToken("comment"), std::string("Test stage from pxr_lte"));
    std::cout << "\n  Set documentation metadata\n";

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
