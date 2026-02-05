/**
 * nsdual_module.cpp
 *
 * A minimal C++ Python extension module that links with custom namespace USD.
 * This tests that a native module using custom namespace USD can coexist
 * with standard pxr Python module.
 *
 * The actual namespace (pxr or pxr_lte) is determined by the USD build
 * configuration via PXR_NS macro in pxr/pxr.h - no hardcoding here.
 *
 * Uses raw CPython API to minimize dependencies.
 *
 * Build:
 *   build_nsdual_module.bat
 *
 * Test:
 *   python test_nsdual_coexist.py
 */

#define PY_SSIZE_T_CLEAN
#include <Python.h>

#include <string>
#include <sstream>

// USD includes - namespace is determined by PXR_NS in pxr.h
#include "pxr/pxr.h"
#include "pxr/usd/usd/stage.h"
#include "pxr/usd/usd/prim.h"
#include "pxr/usd/sdf/path.h"
#include "pxr/usd/sdf/layer.h"
#include "pxr/base/tf/token.h"
#include "pxr/base/gf/vec3f.h"

// Use the namespace defined by the USD build (PXR_NS from pxr.h)
PXR_NAMESPACE_USING_DIRECTIVE

// Helper to stringify macro values
#define NSDUAL_STRINGIFY_HELPER(x) #x
#define NSDUAL_STRINGIFY(x) NSDUAL_STRINGIFY_HELPER(x)

// Get namespace string at compile time from PXR_NS
#if defined(PXR_NS) && PXR_USE_NAMESPACES
    #define NSDUAL_NAMESPACE_STR NSDUAL_STRINGIFY(PXR_NS)
#else
    #define NSDUAL_NAMESPACE_STR "pxr"
#endif

//------------------------------------------------------------------------------
// Module functions
//------------------------------------------------------------------------------

/**
 * Get the USD namespace used by this module.
 * Returns: string with namespace name (from PXR_NS macro)
 */
static PyObject* nsdual_get_namespace(PyObject* self, PyObject* args) {
    return PyUnicode_FromString(NSDUAL_NAMESPACE_STR);
}

/**
 * Get the USD version from the linked library.
 * Returns: tuple (major, minor, patch)
 */
static PyObject* nsdual_get_version(PyObject* self, PyObject* args) {
    // UsdGetVersion() returns a tuple-like structure
    // We'll construct version from defines
#ifdef PXR_MAJOR_VERSION
    return Py_BuildValue("(iii)", PXR_MAJOR_VERSION, PXR_MINOR_VERSION, PXR_PATCH_VERSION);
#else
    // Fallback - try to get from stage
    auto stage = UsdStage::CreateInMemory();
    if (stage) {
        // Version info not directly accessible, return placeholder
        return Py_BuildValue("(iii)", 0, 0, 0);
    }
    Py_RETURN_NONE;
#endif
}

/**
 * Create an in-memory USD stage and return its USDA representation.
 * Args: prim_name (str) - name of the prim to create
 * Returns: string with USDA content
 */
static PyObject* nsdual_create_stage(PyObject* self, PyObject* args) {
    const char* prim_name = "/TestPrim";

    if (!PyArg_ParseTuple(args, "|s", &prim_name)) {
        return NULL;
    }

    // Create in-memory stage using custom namespace USD
    auto stage = UsdStage::CreateInMemory();
    if (!stage) {
        PyErr_SetString(PyExc_RuntimeError, "Failed to create USD stage");
        return NULL;
    }

    // Define a prim
    SdfPath primPath(prim_name);
    auto prim = stage->DefinePrim(primPath, TfToken("Xform"));
    if (!prim.IsValid()) {
        PyErr_SetString(PyExc_RuntimeError, "Failed to create prim");
        return NULL;
    }

    // Set metadata to identify this was created by the linked USD namespace
    prim.SetDocumentation("Created by nsdual module using " NSDUAL_NAMESPACE_STR " namespace");

    // Export to string
    std::string usdaContent;
    stage->GetRootLayer()->ExportToString(&usdaContent);

    return PyUnicode_FromString(usdaContent.c_str());
}

/**
 * Create a simple mesh with vertices using custom namespace USD.
 * Returns: string with USDA content
 */
static PyObject* nsdual_create_mesh(PyObject* self, PyObject* args) {
    auto stage = UsdStage::CreateInMemory();
    if (!stage) {
        PyErr_SetString(PyExc_RuntimeError, "Failed to create USD stage");
        return NULL;
    }

    // Define mesh prim
    auto meshPrim = stage->DefinePrim(SdfPath("/Mesh"), TfToken("Mesh"));
    if (!meshPrim.IsValid()) {
        PyErr_SetString(PyExc_RuntimeError, "Failed to create mesh prim");
        return NULL;
    }

    stage->SetMetadata(TfToken("comment"),
        std::string("Created by nsdual C++ module (") + NSDUAL_NAMESPACE_STR + " namespace)");

    // Export to string
    std::string usdaContent;
    stage->GetRootLayer()->ExportToString(&usdaContent);

    return PyUnicode_FromString(usdaContent.c_str());
}

/**
 * Test Gf math types from custom namespace USD.
 * Returns: dict with vector info
 */
static PyObject* nsdual_test_math(PyObject* self, PyObject* args) {
    // Create a vector using custom namespace Gf
    GfVec3f vec(1.0f, 2.0f, 3.0f);
    float length = vec.GetLength();
    GfVec3f normalized = vec.GetNormalized();

    // Build result dict
    PyObject* result = PyDict_New();
    if (!result) return NULL;

    // Add vector as tuple
    PyObject* vecTuple = Py_BuildValue("(fff)", vec[0], vec[1], vec[2]);
    PyDict_SetItemString(result, "vector", vecTuple);
    Py_DECREF(vecTuple);

    // Add length
    PyObject* lengthObj = PyFloat_FromDouble(length);
    PyDict_SetItemString(result, "length", lengthObj);
    Py_DECREF(lengthObj);

    // Add normalized as tuple
    PyObject* normTuple = Py_BuildValue("(fff)", normalized[0], normalized[1], normalized[2]);
    PyDict_SetItemString(result, "normalized", normTuple);
    Py_DECREF(normTuple);

    // Add namespace info (from PXR_NS macro)
    PyObject* nsObj = PyUnicode_FromString(NSDUAL_NAMESPACE_STR);
    PyDict_SetItemString(result, "namespace", nsObj);
    Py_DECREF(nsObj);

    return result;
}

/**
 * Get module info as a dict.
 */
static PyObject* nsdual_info(PyObject* self, PyObject* args) {
    PyObject* result = PyDict_New();
    if (!result) return NULL;

    // Namespace from PXR_NS macro (no hardcoding)
    PyDict_SetItemString(result, "namespace", PyUnicode_FromString(NSDUAL_NAMESPACE_STR));

    // Version from PXR_*_VERSION macros in pxr.h
    PyDict_SetItemString(result, "version",
        Py_BuildValue("(iii)", PXR_MAJOR_VERSION, PXR_MINOR_VERSION, PXR_PATCH_VERSION));

    // Monolithic flag
    PyDict_SetItemString(result, "monolithic", Py_True);
    Py_INCREF(Py_True);

    return result;
}

//------------------------------------------------------------------------------
// Module definition
//------------------------------------------------------------------------------

static PyMethodDef NSDualMethods[] = {
    {"get_namespace", nsdual_get_namespace, METH_NOARGS,
     "Get the USD namespace used by this module (pxr_lte for custom build)."},
    {"get_version", nsdual_get_version, METH_NOARGS,
     "Get the USD version as (major, minor, patch) tuple."},
    {"create_stage", nsdual_create_stage, METH_VARARGS,
     "Create an in-memory USD stage and return USDA string."},
    {"create_mesh", nsdual_create_mesh, METH_NOARGS,
     "Create a simple mesh using custom namespace USD."},
    {"test_math", nsdual_test_math, METH_NOARGS,
     "Test Gf math types and return vector info dict."},
    {"info", nsdual_info, METH_NOARGS,
     "Get module info as dict (namespace, version, monolithic)."},
    {NULL, NULL, 0, NULL}
};

static struct PyModuleDef nsdualmodule = {
    PyModuleDef_HEAD_INIT,
    "nsdual",                              /* module name */
    "C++ module linked with custom namespace USD (pxr_lte monolithic).\n"
    "Tests coexistence with standard pxr Python module.",  /* docstring */
    -1,                                    /* per-interpreter state size */
    NSDualMethods
};

PyMODINIT_FUNC PyInit_nsdual(void) {
    return PyModule_Create(&nsdualmodule);
}
