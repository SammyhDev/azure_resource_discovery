#!/bin/bash

# Simple wrapper script for Azure to AWS Cost Analyzer
# This script guides users through the entire process

set -e  # Exit on any error

echo "🔍 Azure to AWS Cost Analyzer"
echo "=============================="
echo ""

# Color definitions for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
echo "Checking prerequisites..."

# Check Python 3
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed"
    echo "Please install Python 3.7 or higher and try again."
    exit 1
fi
print_status "Python 3 found: $(python3 --version)"

# Check pip3
if ! command -v pip3 &> /dev/null; then
    print_error "pip3 is not installed"
    echo "Please install pip3 and try again."
    exit 1
fi
print_status "pip3 found"

# Check Azure CLI
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed"
    echo ""
    echo "Please install Azure CLI:"
    echo "- Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    echo "- macOS: brew install azure-cli"
    echo "- Windows: Download from https://aka.ms/installazurecliwindows"
    echo ""
    exit 1
fi
print_status "Azure CLI found: $(az --version | head -n1)"

# Check Azure login status
if ! az account show &> /dev/null; then
    print_error "Not logged into Azure CLI"
    echo ""
    print_info "Let's get you logged into Azure..."
    echo ""
    echo "This will open a web browser for authentication."
    echo "If you're using a remote/headless environment, you'll get a device code instead."
    echo ""
    read -p "Would you like me to start the Azure login process now? (y/n): " start_login
    
    if [[ $start_login =~ ^[Yy]$ ]]; then
        print_info "Starting Azure CLI login..."
        az login
        
        if [ $? -eq 0 ]; then
            print_status "Successfully logged into Azure!"
            
            # Check if user has multiple subscriptions
            SUB_COUNT=$(az account list --query "length(@)" -o tsv)
            if [ "$SUB_COUNT" -gt 1 ]; then
                echo ""
                print_info "You have $SUB_COUNT subscriptions. Here they are:"
                az account list --output table
                echo ""
                print_warning "Multiple subscriptions found!"
                read -p "Would you like to select a specific subscription? (y/n): " select_sub
                
                if [[ $select_sub =~ ^[Yy]$ ]]; then
                    read -p "Enter the subscription ID or name: " sub_choice
                    az account set --subscription "$sub_choice"
                    if [ $? -eq 0 ]; then
                        print_status "Subscription set successfully!"
                    else
                        print_error "Failed to set subscription. Using default."
                    fi
                else
                    print_info "Using default subscription."
                fi
            fi
        else
            print_error "Azure login failed"
            echo ""
            echo "Troubleshooting tips:"
            echo "• Make sure you have internet connectivity"
            echo "• Try: az login --use-device-code (for headless environments)"
            echo "• Try: az login --tenant YOUR_TENANT_ID (if you have multiple tenants)"
            echo ""
            exit 1
        fi
    else
        echo ""
        echo "Please login to Azure manually and then run this script again:"
        echo ""
        print_info "For interactive login:"
        echo "  az login"
        echo ""
        print_info "For device code login (headless/remote):"
        echo "  az login --use-device-code"
        echo ""
        print_info "For specific tenant:"
        echo "  az login --tenant YOUR_TENANT_ID"
        echo ""
        print_info "After login, if you have multiple subscriptions:"
        echo "  az account list --output table"
        echo "  az account set --subscription \"your-subscription-id\""
        echo ""
        exit 1
    fi
fi

# Show current subscription and validate access
echo ""
print_info "Validating Azure access..."
CURRENT_SUB=$(az account show --query name -o tsv 2>/dev/null)
CURRENT_SUB_ID=$(az account show --query id -o tsv 2>/dev/null)
TENANT_ID=$(az account show --query tenantId -o tsv 2>/dev/null)

if [ -z "$CURRENT_SUB" ]; then
    print_error "Unable to get subscription information"
    exit 1
fi

print_status "✓ Active subscription: $CURRENT_SUB"
print_status "✓ Subscription ID: $CURRENT_SUB_ID"
print_status "✓ Tenant ID: $TENANT_ID"

# Test if we can actually list resources (basic permission check)
echo ""
print_info "Testing Azure permissions..."
if az group list --query "length(@)" -o tsv &> /dev/null; then
    RESOURCE_GROUP_COUNT=$(az group list --query "length(@)" -o tsv)
    print_status "✓ Can access Azure resources ($RESOURCE_GROUP_COUNT resource groups found)"
else
    print_warning "Limited access to Azure resources detected"
    echo "  This might affect the completeness of the analysis."
    echo "  Make sure you have at least 'Reader' role on the subscription."
fi

echo ""

# Check if dependencies are installed
echo "Checking Python dependencies..."
MISSING_DEPS=false

check_package() {
    if ! python3 -c "import $1" &> /dev/null; then
        print_warning "Missing package: $1"
        MISSING_DEPS=true
    fi
}

check_package "azure.identity"
check_package "azure.mgmt.resource"
check_package "azure.mgmt.compute"
check_package "azure.mgmt.storage"
check_package "azure.mgmt.sql"
check_package "azure.mgmt.web"
check_package "requests"

if [ "$MISSING_DEPS" = true ]; then
    echo ""
    print_info "Installing missing Python dependencies..."
    pip3 install -r requirements.txt
    if [ $? -eq 0 ]; then
        print_status "Dependencies installed successfully!"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
else
    print_status "All Python dependencies are installed"
fi

echo ""
echo "🚀 Ready to analyze your Azure resources!"
echo ""

# Ask user what they want to do
echo "What would you like to do?"
echo "1) Run analysis and display results on screen"
echo "2) Run analysis and save text report to file"
echo "3) Run analysis and save JSON report to file"
echo "4) Run test mode (no Azure resources needed)"
echo "5) Exit"
echo ""
read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        print_info "Running analysis with screen output..."
        python3 azure_to_aws_cost_analyzer.py
        ;;
    2)
        REPORT_FILE="azure_aws_analysis_$(date +%Y%m%d_%H%M%S).txt"
        print_info "Running analysis and saving to $REPORT_FILE..."
        python3 azure_to_aws_cost_analyzer.py --output "$REPORT_FILE"
        print_status "Report saved to $REPORT_FILE"
        ;;
    3)
        JSON_FILE="azure_aws_analysis_$(date +%Y%m%d_%H%M%S).json"
        print_info "Running analysis and saving to $JSON_FILE..."
        python3 azure_to_aws_cost_analyzer.py --json --output "$JSON_FILE"
        print_status "JSON report saved to $JSON_FILE"
        ;;
    4)
        print_info "Running test mode..."
        python3 test_analyzer.py
        ;;
    5)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        print_error "Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo ""
print_status "Analysis complete!"
echo ""
print_info "Remember: These are rough cost estimates for planning purposes."
print_info "Use the AWS Pricing Calculator for detailed cost planning."
echo ""