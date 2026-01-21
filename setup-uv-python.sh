#!/bin/bash
# Set up a repo-local Python environment using uv and install USD deps.

set -e

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}"
VENV_DIR="${ROOT_DIR}/.venv"
PYTHON_VERSION="${PYTHON_VERSION:-3.11}"
PY_DEPS=(jinja2 PySide6 PyOpenGL)

if ! command -v uv >/dev/null 2>&1; then
    echo "Error: uv is not installed or not on PATH."
    echo "Install uv first: https://docs.astral.sh/uv/"
    exit 1
fi

echo "========================================"
echo "Setting up Python with uv"
echo "========================================"
echo "Python version: ${PYTHON_VERSION}"
echo "Venv: ${VENV_DIR}"
echo "Packages: ${PY_DEPS[*]}"
echo "========================================"

uv python install "${PYTHON_VERSION}"

if [ ! -d "${VENV_DIR}" ]; then
    uv venv --python "${PYTHON_VERSION}" "${VENV_DIR}"
else
    echo "Using existing venv at ${VENV_DIR}"
fi

uv pip install --python "${VENV_DIR}/bin/python" "${PY_DEPS[@]}"

echo ""
echo "========================================"
echo "Python environment ready"
echo "========================================"
echo "To activate: source ${VENV_DIR}/bin/activate"
echo "========================================"
