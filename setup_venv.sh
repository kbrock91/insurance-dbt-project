#!/bin/bash
# Setup script for dbt-core with Snowflake virtual environment

set -e

VENV_NAME="venv"
PYTHON_VERSION="python3"

echo "=== dbt-core Snowflake Environment Setup ==="

# Check Python version
if ! command -v $PYTHON_VERSION &> /dev/null; then
    echo "Error: $PYTHON_VERSION not found. Please install Python 3.9+."
    exit 1
fi

PYTHON_VER=$($PYTHON_VERSION --version 2>&1 | cut -d' ' -f2)
echo "Using Python version: $PYTHON_VER"

# Create virtual environment
if [ -d "$VENV_NAME" ]; then
    echo "Virtual environment '$VENV_NAME' already exists."
    read -p "Delete and recreate? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$VENV_NAME"
        echo "Removed existing virtual environment."
    else
        echo "Keeping existing environment. Activating..."
    fi
fi

if [ ! -d "$VENV_NAME" ]; then
    echo "Creating virtual environment..."
    $PYTHON_VERSION -m venv "$VENV_NAME"
fi

# Activate virtual environment
echo "Activating virtual environment..."
source "$VENV_NAME/bin/activate"

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install requirements
echo "Installing dbt-core and dbt-snowflake..."
pip install -r requirements.txt

# Verify installation
echo ""
echo "=== Installation Complete ==="
echo "dbt version:"
dbt --version

echo ""
echo "=== Next Steps ==="
echo "1. Activate the environment:  source $VENV_NAME/bin/activate"
echo "2. Configure Snowflake profile in ~/.dbt/profiles.yml"
echo "3. Test connection:           dbt debug"
echo "4. Run models:                dbt run"
echo ""
echo "Example profiles.yml entry for Snowflake:"
cat << 'EOF'

insurance_dbt_zna:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <your_account>
      user: <your_user>
      password: <your_password>  # Or use authenticator: externalbrowser
      role: <your_role>
      database: analytics
      warehouse: <your_warehouse>
      schema: dbt_<your_name>_insurance
      threads: 4

EOF
