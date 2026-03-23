#!/bin/bash
# Unpropagated Columns Analysis - CI Runner
#
# This script runs the unpropagated columns analysis using the dbt MCP API.
#
# Required environment variables (set in CI secrets):
#   DBT_TOKEN           - dbt Cloud service token
#   DBT_ENVIRONMENT_ID  - Production environment ID
#
# Optional:
#   DBT_HOST_URL        - dbt Cloud host (default: https://cloud.getdbt.com)
#
# Usage:
#   ./run_analysis.sh
#   ./run_analysis.sh --source raw_insurance

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_PATH="${SCRIPT_DIR}/unpropagated_columns_report.csv"
VENV_DIR="${SCRIPT_DIR}/.venv"

# Load .env file if it exists
if [ -f "${SCRIPT_DIR}/.env" ]; then
    echo "Loading environment from .env file..."
    set -a
    source "${SCRIPT_DIR}/.env"
    set +a
fi

# Activate virtual environment if it exists
if [ -d "$VENV_DIR" ]; then
    echo "Activating virtual environment..."
    source "${VENV_DIR}/bin/activate"
fi

# Check for required environment variables
if [ -z "$DBT_TOKEN" ]; then
    echo "Error: DBT_TOKEN environment variable is required"
    exit 1
fi

if [ -z "$DBT_ENVIRONMENT_ID" ]; then
    echo "Error: DBT_ENVIRONMENT_ID environment variable is required"
    exit 1
fi

# Set default host if not provided
export DBT_HOST_URL="${DBT_HOST_URL:-https://cloud.getdbt.com}"

echo "=========================================="
echo "Unpropagated Columns Analysis"
echo "=========================================="
echo "Host: ${DBT_HOST_URL}"
echo "Environment ID: ${DBT_ENVIRONMENT_ID}"
echo "Output: ${REPORT_PATH}"
echo "=========================================="

# Run the analysis
python3 "${SCRIPT_DIR}/unpropagated_columns.py" \
    --output "${REPORT_PATH}" \
    "$@"

# Check results
if [ -f "${REPORT_PATH}" ]; then
    echo ""
    echo "Report generated successfully"
    
    # Count dropped columns
    DROPPED=$(grep -c "dropped_at" "${REPORT_PATH}" 2>/dev/null || echo "0")
    
    if [ "$DROPPED" -gt 0 ]; then
        echo "⚠️  Found ${DROPPED} unpropagated columns"
        # Uncomment to fail CI on unpropagated columns:
        # exit 1
    else
        echo "✓ All source columns are propagated"
    fi
else
    echo "Error: Report was not generated"
    exit 1
fi
