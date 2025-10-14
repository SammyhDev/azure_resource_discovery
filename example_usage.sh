#!/bin/bash
#
# Example usage script for Azure Resource Discovery
#
# This script demonstrates how to use the Azure Resource Discovery tool
# to generate reports for your Azure subscription.
#

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Azure Resource Discovery - Example Usage"
echo "=========================================="
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed"
    echo "Please install Python 3.7 or higher"
    exit 1
fi

echo -e "${GREEN}✓${NC} Python 3 is installed"

# Check if dependencies are installed
if ! python3 -c "import azure.identity" &> /dev/null; then
    echo ""
    echo -e "${YELLOW}⚠${NC} Dependencies not installed. Installing..."
    pip install -r requirements.txt
    if [ $? -ne 0 ]; then
        echo "❌ Error: Failed to install dependencies"
        exit 1
    fi
fi

echo -e "${GREEN}✓${NC} Dependencies are installed"
echo ""

# Check if user provided subscription ID
if [ -z "$1" ]; then
    echo "Usage: $0 <subscription-id> [output-directory]"
    echo ""
    echo "Example:"
    echo "  $0 12345678-1234-1234-1234-123456789abc ./reports"
    echo ""
    echo "You can also set it as an environment variable:"
    echo "  export AZURE_SUBSCRIPTION_ID=12345678-1234-1234-1234-123456789abc"
    echo "  $0 \$AZURE_SUBSCRIPTION_ID"
    exit 1
fi

SUBSCRIPTION_ID="$1"
OUTPUT_DIR="${2:-.}"

echo "Configuration:"
echo "  Subscription ID: $SUBSCRIPTION_ID"
echo "  Output Directory: $OUTPUT_DIR"
echo ""

# Check Azure authentication
echo "Checking Azure authentication..."
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} Not authenticated with Azure CLI"
    echo "Please authenticate using: az login"
    exit 1
fi

echo -e "${GREEN}✓${NC} Azure authentication verified"
echo ""

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Run the script
echo "Starting resource discovery..."
echo ""
python3 azure_resource_discovery.py --subscription-id "$SUBSCRIPTION_ID" --output-dir "$OUTPUT_DIR"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Success!${NC} Reports generated in: $OUTPUT_DIR"
    echo ""
    echo "Generated files:"
    ls -lh "$OUTPUT_DIR"/*ResourcesReport_* 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
else
    echo ""
    echo "❌ Error: Report generation failed"
    exit 1
fi
