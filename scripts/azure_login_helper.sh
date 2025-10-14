#!/bin/bash

# Azure CLI Login Helper Script
# This script helps users login to Azure CLI with detailed guidance

set -e

echo "🔐 Azure CLI Login Helper"
echo "========================="
echo ""

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed"
    echo ""
    echo "Please install Azure CLI first:"
    echo ""
    echo "🐧 Linux (Ubuntu/Debian):"
    echo "  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    echo ""
    echo "🐧 Linux (RHEL/CentOS/Fedora):"
    echo "  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc"
    echo "  sudo dnf install -y azure-cli"
    echo ""
    echo "🍎 macOS:"
    echo "  brew install azure-cli"
    echo ""
    echo "🪟 Windows:"
    echo "  Download from: https://aka.ms/installazurecliwindows"
    echo ""
    echo "🐳 Docker:"
    echo "  docker run -it mcr.microsoft.com/azure-cli"
    echo ""
    exit 1
fi

print_status "Azure CLI found: $(az --version | head -n1)"

# Check current login status
echo ""
print_info "Checking current login status..."

if az account show &> /dev/null; then
    CURRENT_SUB=$(az account show --query name -o tsv)
    CURRENT_SUB_ID=$(az account show --query id -o tsv)
    TENANT_ID=$(az account show --query tenantId -o tsv)
    
    print_status "Already logged in!"
    echo "  Subscription: $CURRENT_SUB"
    echo "  Subscription ID: $CURRENT_SUB_ID"
    echo "  Tenant ID: $TENANT_ID"
    echo ""
    
    read -p "Would you like to login with a different account? (y/n): " relogin
    if [[ ! $relogin =~ ^[Yy]$ ]]; then
        # Check if they want to switch subscriptions
        SUB_COUNT=$(az account list --query "length(@)" -o tsv)
        if [ "$SUB_COUNT" -gt 1 ]; then
            echo ""
            print_info "You have $SUB_COUNT subscriptions available."
            read -p "Would you like to see them and possibly switch? (y/n): " show_subs
            if [[ $show_subs =~ ^[Yy]$ ]]; then
                echo ""
                az account list --output table
                echo ""
                read -p "Enter subscription ID/name to switch (or press Enter to keep current): " new_sub
                if [ ! -z "$new_sub" ]; then
                    az account set --subscription "$new_sub"
                    if [ $? -eq 0 ]; then
                        print_status "Switched to subscription: $new_sub"
                    else
                        print_error "Failed to switch subscription"
                    fi
                fi
            fi
        fi
        echo ""
        print_status "Login process complete!"
        exit 0
    fi
fi

# Guide user through login options
echo ""
print_info "Azure CLI Login Options:"
echo ""
echo "1) 🌐 Interactive Login (opens web browser)"
echo "   - Best for desktop environments"
echo "   - Opens browser for authentication"
echo ""
echo "2) 📱 Device Code Login (for remote/headless environments)"
echo "   - Shows a code to enter on another device"
echo "   - Good for SSH sessions, containers, etc."
echo ""
echo "3) 🏢 Service Principal Login (for automation)"
echo "   - Uses client ID and secret"
echo "   - For scripts and CI/CD pipelines"
echo ""
echo "4) 🆔 Managed Identity Login (for Azure VMs)"
echo "   - Uses Azure VM's managed identity"
echo "   - Only works on Azure VMs with managed identity enabled"
echo ""

read -p "Choose login method (1-4): " login_method

case $login_method in
    1)
        print_info "Starting interactive login..."
        echo "This will open your default web browser."
        echo ""
        read -p "Press Enter to continue or Ctrl+C to cancel..."
        
        az login
        ;;
    2)
        print_info "Starting device code login..."
        echo "You'll get a code to enter at https://microsoft.com/devicelogin"
        echo ""
        read -p "Press Enter to continue or Ctrl+C to cancel..."
        
        az login --use-device-code
        ;;
    3)
        print_info "Service Principal login requires:"
        echo "- Application (client) ID"
        echo "- Client secret or certificate"
        echo "- Tenant ID"
        echo ""
        
        read -p "Enter Application (client) ID: " client_id
        read -p "Enter Tenant ID: " tenant_id
        read -s -p "Enter Client Secret: " client_secret
        echo ""
        
        az login --service-principal -u "$client_id" -p "$client_secret" --tenant "$tenant_id"
        ;;
    4)
        print_info "Attempting managed identity login..."
        az login --identity
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

# Check if login was successful
if [ $? -eq 0 ]; then
    print_status "Login successful!"
    
    # Show account information
    echo ""
    print_info "Account Information:"
    CURRENT_SUB=$(az account show --query name -o tsv)
    CURRENT_SUB_ID=$(az account show --query id -o tsv)
    TENANT_ID=$(az account show --query tenantId -o tsv)
    USER_NAME=$(az account show --query user.name -o tsv)
    
    echo "  User: $USER_NAME"
    echo "  Subscription: $CURRENT_SUB"
    echo "  Subscription ID: $CURRENT_SUB_ID"
    echo "  Tenant ID: $TENANT_ID"
    
    # Handle multiple subscriptions
    SUB_COUNT=$(az account list --query "length(@)" -o tsv)
    if [ "$SUB_COUNT" -gt 1 ]; then
        echo ""
        print_warning "You have $SUB_COUNT subscriptions available."
        echo ""
        read -p "Would you like to see all subscriptions? (y/n): " show_all
        
        if [[ $show_all =~ ^[Yy]$ ]]; then
            echo ""
            az account list --output table
            echo ""
            read -p "Would you like to switch to a different subscription? (y/n): " switch_sub
            
            if [[ $switch_sub =~ ^[Yy]$ ]]; then
                read -p "Enter subscription ID or name: " new_sub
                az account set --subscription "$new_sub"
                if [ $? -eq 0 ]; then
                    NEW_SUB_NAME=$(az account show --query name -o tsv)
                    print_status "Switched to subscription: $NEW_SUB_NAME"
                else
                    print_error "Failed to switch subscription"
                fi
            fi
        fi
    fi
    
    # Test permissions
    echo ""
    print_info "Testing permissions..."
    if az group list --query "length(@)" -o tsv &> /dev/null; then
        RG_COUNT=$(az group list --query "length(@)" -o tsv)
        print_status "Can access $RG_COUNT resource groups"
        
        # Quick resource count
        print_info "Checking resources..."
        RESOURCE_COUNT=$(az resource list --query "length(@)" -o tsv 2>/dev/null || echo "0")
        if [ "$RESOURCE_COUNT" -gt 0 ]; then
            print_status "Found $RESOURCE_COUNT resources in subscription"
        else
            print_warning "No resources found or limited access"
        fi
    else
        print_warning "Limited permissions detected"
        echo "  You may need 'Reader' role for full analysis"
    fi
    
    echo ""
    print_status "Azure CLI setup complete!"
    echo ""
    print_info "You can now run the resource analyzer:"
    echo "  ./run_analyzer.sh"
    echo "  or"
    echo "  python3 azure_to_aws_cost_analyzer.py"
    
else
    print_error "Login failed"
    echo ""
    echo "Troubleshooting tips:"
    echo "• Check your internet connection"
    echo "• Verify your credentials"
    echo "• Try a different login method"
    echo "• Check if your organization requires specific login procedures"
    echo ""
    echo "For more help, visit:"
    echo "https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli"
fi