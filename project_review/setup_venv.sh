#!/bin/bash
# Setup virtual environment for unpropagated columns analysis
#
# Usage:
#   ./setup_venv.sh
#
# After setup, activate with:
#   source .venv/bin/activate

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/.venv"

echo "Setting up virtual environment..."

# Find Python 3.10+
PYTHON_CMD=""
for cmd in python3.13 python3.12 python3.11 python3.10; do
    if command -v $cmd &> /dev/null; then
        PYTHON_CMD=$cmd
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo "Error: Python 3.10 or higher is required but not found."
    echo "Please install Python 3.10+ and try again."
    exit 1
fi

echo "Using Python: $PYTHON_CMD ($($PYTHON_CMD --version))"

# Create venv if it doesn't exist or was created with wrong Python version
if [ -d "$VENV_DIR" ]; then
    # Check if existing venv uses correct Python
    VENV_PYTHON_VERSION=$("${VENV_DIR}/bin/python" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+')
    if [[ "$VENV_PYTHON_VERSION" < "3.10" ]]; then
        echo "Existing venv uses Python $VENV_PYTHON_VERSION, need 3.10+. Recreating..."
        rm -rf "$VENV_DIR"
    fi
fi

if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment at ${VENV_DIR}"
    $PYTHON_CMD -m venv "$VENV_DIR"
else
    echo "Virtual environment already exists at ${VENV_DIR}"
fi

# Activate and install dependencies
echo "Installing dependencies..."
source "${VENV_DIR}/bin/activate"
pip install --upgrade pip
pip install -r "${SCRIPT_DIR}/requirements.txt"

echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo ""
echo "To activate the virtual environment:"
echo "  source ${VENV_DIR}/bin/activate"
echo ""
echo "To run the analysis:"
echo "  export DBT_TOKEN='your-token'"
echo "  export DBT_ENVIRONMENT_ID='your-env-id'"
echo "  python unpropagated_columns.py"
echo ""
echo "To deactivate when done:"
echo "  deactivate"
