#!/usr/bin/env bash
# ==============================================================================
# Script: run-tests.sh
# Description: Automated test runner for Assembler & Disassembler test suite.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

echo "=================================================================="
echo " Running Assembler & Disassembler Correctness Test Suite"
echo "=================================================================="

# Check Python 3
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is required to run the test suite." >&2
    exit 1
fi

# Run test discovery
python3 -m unittest discover -s tests -v

echo "=================================================================="
echo " All tests passed successfully!"
echo "=================================================================="
