#!/bin/bash

# Azure to AWS Cost Analyzer - One Script Does It All
# Just run: ./analyze.sh

set -e

echo "🚀 Azure to AWS Cost Analyzer"
echo "============================="
echo ""
echo "This script will:"
echo "• Install Azure CLI if needed"
echo "• Install Python dependencies"
echo "• Help you login to Azure"
echo "• Analyze your Azure resources"
echo "• Show AWS cost estimates"
echo ""
echo "Just sit back and follow the prompts!"
echo ""

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_step() {
    echo -e "${PURPLE}🔷 STEP: $1${NC}"
}

print_success() {
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

# Function to install Azure CLI
install_azure_cli() {
    print_step "Installing Azure CLI"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_info "Detected Linux - installing Azure CLI..."
        if command -v curl &> /dev/null; then
            curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
        else
            print_error "curl not found. Please install curl first: sudo apt-get install curl"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        print_info "Detected macOS"
        if command -v brew &> /dev/null; then
            brew install azure-cli
        else
            print_error "Homebrew not found. Please install Homebrew first:"
            print_error "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    else
        print_error "Unsupported OS. Please install Azure CLI manually:"
        print_error "  Windows: https://aka.ms/installazurecliwindows"
        print_error "  Other: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
}

# Step 1: Check and install Azure CLI
print_step "Checking Azure CLI"
if ! command -v az &> /dev/null; then
    print_warning "Azure CLI not found"
    read -p "Would you like me to install Azure CLI automatically? (y/n): " install_az
    if [[ $install_az =~ ^[Yy]$ ]]; then
        install_azure_cli
        if command -v az &> /dev/null; then
            print_success "Azure CLI installed successfully!"
        else
            print_error "Azure CLI installation failed"
            exit 1
        fi
    else
        print_error "Azure CLI is required. Please install it manually and run this script again."
        exit 1
    fi
else
    print_success "Azure CLI found: $(az --version | head -n1)"
fi

# Step 2: Check Python
print_step "Checking Python"
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is required but not found"
    print_error "Please install Python 3.7+ and run this script again"
    exit 1
fi
print_success "Python 3 found: $(python3 --version)"

if ! command -v pip3 &> /dev/null; then
    print_error "pip3 is required but not found"
    print_error "Please install pip3 and run this script again"
    exit 1
fi
print_success "pip3 found"

# Step 3: Install Python dependencies
print_step "Installing Python dependencies"
print_info "This may take a moment..."

cat > requirements.txt << 'EOF'
azure-identity>=1.15.0
azure-mgmt-resource>=23.0.0
azure-mgmt-compute>=30.0.0
azure-mgmt-storage>=21.0.0
azure-mgmt-sql>=3.0.0
azure-mgmt-web>=7.0.0
requests>=2.31.0
EOF

pip3 install -r requirements.txt -q
if [ $? -eq 0 ]; then
    print_success "Python dependencies installed!"
else
    print_error "Failed to install Python dependencies"
    exit 1
fi

# Step 4: Handle Azure login
print_step "Azure Login"
if az account show &> /dev/null; then
    CURRENT_SUB=$(az account show --query name -o tsv)
    CURRENT_SUB_ID=$(az account show --query id -o tsv)
    print_success "Already logged into Azure!"
    print_info "Current subscription: $CURRENT_SUB"
    print_info "Subscription ID: $CURRENT_SUB_ID"
    
    read -p "Continue with this subscription? (y/n): " continue_sub
    if [[ ! $continue_sub =~ ^[Yy]$ ]]; then
        print_info "Let's login with a different account..."
        az logout &> /dev/null
    fi
fi

if ! az account show &> /dev/null; then
    print_info "You need to login to Azure"
    echo ""
    echo "Choose login method:"
    echo "1) 🌐 Open web browser (recommended for desktops)"
    echo "2) 📱 Device code (for remote/SSH sessions)"
    echo ""
    read -p "Choose (1 or 2): " login_choice
    
    case $login_choice in
        1)
            print_info "Opening web browser for login..."
            az login
            ;;
        2)
            print_info "Starting device code login..."
            echo "You'll get a code to enter at https://microsoft.com/devicelogin"
            az login --use-device-code
            ;;
        *)
            print_info "Using default interactive login..."
            az login
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        print_success "Successfully logged into Azure!"
    else
        print_error "Login failed. Please try again."
        exit 1
    fi
fi

# Handle multiple subscriptions
SUB_COUNT=$(az account list --query "length(@)" -o tsv 2>/dev/null || echo "0")
if [ "$SUB_COUNT" -gt 1 ]; then
    print_info "You have $SUB_COUNT subscriptions"
    read -p "Would you like to see them and choose one? (y/n): " show_subs
    if [[ $show_subs =~ ^[Yy]$ ]]; then
        echo ""
        az account list --output table
        echo ""
        read -p "Enter subscription ID or name (or press Enter for current): " chosen_sub
        if [ ! -z "$chosen_sub" ]; then
            az account set --subscription "$chosen_sub"
            if [ $? -eq 0 ]; then
                print_success "Switched to subscription: $chosen_sub"
            else
                print_warning "Failed to switch, using current subscription"
            fi
        fi
    fi
fi

# Show final subscription info
FINAL_SUB=$(az account show --query name -o tsv)
FINAL_SUB_ID=$(az account show --query id -o tsv)
print_success "Using subscription: $FINAL_SUB ($FINAL_SUB_ID)"

# Step 5: Create the analyzer script inline
print_step "Creating analyzer script"

cat > azure_analyzer.py << 'EOF'
#!/usr/bin/env python3
import json, sys, subprocess, logging
from datetime import datetime
from typing import Dict, List, Any, Optional

try:
    from azure.identity import DefaultAzureCredential, AzureCliCredential
    from azure.mgmt.resource import ResourceManagementClient
    from azure.mgmt.compute import ComputeManagementClient
    from azure.mgmt.storage import StorageManagementClient
    from azure.mgmt.sql import SqlManagementClient
    from azure.mgmt.web import WebSiteManagementClient
except ImportError as e:
    print(f"Missing package: {e}")
    sys.exit(1)

logging.basicConfig(level=logging.WARNING)
logger = logging.getLogger(__name__)

class SimpleAnalyzer:
    def __init__(self):
        try:
            result = subprocess.run(['az', 'account', 'show', '--query', 'id', '-o', 'tsv'], 
                                  capture_output=True, text=True, check=True)
            self.subscription_id = result.stdout.strip()
        except:
            print("❌ Not logged into Azure CLI")
            sys.exit(1)
        
        try:
            self.credential = AzureCliCredential()
        except:
            self.credential = DefaultAzureCredential()
        
        self.resource_client = ResourceManagementClient(self.credential, self.subscription_id)
        self.compute_client = ComputeManagementClient(self.credential, self.subscription_id)
        self.storage_client = StorageManagementClient(self.credential, self.subscription_id)
        self.sql_client = SqlManagementClient(self.credential, self.subscription_id)
        self.web_client = WebSiteManagementClient(self.credential, self.subscription_id)

    def get_azure_costs(self):
        """Get Azure pricing estimates (rough approximations)"""
        return {
            # Azure VM costs per month (rough estimates in USD)
            'vm_costs': {
                'standard_b1s': 7.59, 'standard_b1ms': 15.18, 'standard_b2s': 30.37,
                'standard_b2ms': 60.74, 'standard_b4ms': 121.47, 'standard_d2s_v3': 96.36,
                'standard_d4s_v3': 192.72, 'standard_d8s_v3': 385.44, 'default': 50.0
            },
            # Azure Storage costs per GB per month
            'storage_costs': {
                'standard_lrs': 0.0208, 'standard_grs': 0.0416, 'premium_lrs': 0.15,
                'hot': 0.0208, 'cool': 0.0108, 'archive': 0.00099
            },
            # Azure SQL Database costs per month (rough estimates)
            'sql_costs': {
                'basic': 5.0, 'standard_s0': 15.0, 'standard_s1': 30.0, 'standard_s2': 75.0,
                'premium_p1': 465.0, 'gp_gen5_2': 420.0, 'default': 50.0
            },
            # Azure App Service costs per month
            'app_costs': {
                'free': 0.0, 'shared': 9.49, 'basic_b1': 13.14, 'standard_s1': 56.94,
                'premium_p1v2': 85.41, 'default': 25.0
            }
        }

    def analyze(self):
        print("🔍 Discovering Azure resources...")
        resources = {'vms': [], 'storage': [], 'sql': [], 'apps': [], 'other': []}
        total_aws_cost = 0
        total_azure_cost = 0
        
        try:
            all_resources = list(self.resource_client.resources.list())
            print(f"   Found {len(all_resources)} total resources")
            
            # AWS pricing
            aws_vm_costs = {'t3.nano': 3.8, 't3.micro': 7.6, 't3.small': 15.2, 't3.medium': 30.4, 't3.large': 60.8, 'm5.large': 70.1, 'm5.xlarge': 140.2}
            aws_storage_cost_per_gb = 0.023
            aws_db_costs = {'db.t3.micro': 12.8, 'db.t3.small': 25.6, 'db.t3.medium': 51.2}
            
            # Azure pricing
            azure_costs = self.get_azure_costs()
            
            for resource in all_resources:
                resource_type = resource.type.lower()
                
                if 'virtualmachine' in resource_type:
                    try:
                        rg = resource.id.split('/')[4]
                        vm = self.compute_client.virtual_machines.get(rg, resource.name)
                        vm_size = vm.hardware_profile.vm_size.lower()
                        
                        # AWS mapping and cost
                        size_map = {'standard_b1s': 't3.nano', 'standard_b1ms': 't3.micro', 'standard_b2s': 't3.small', 
                                   'standard_b2ms': 't3.medium', 'standard_b4ms': 't3.large', 'standard_d2s_v3': 'm5.large'}
                        aws_type = size_map.get(vm_size, 't3.medium')
                        aws_cost = aws_vm_costs.get(aws_type, 30.4)
                        
                        # Azure cost
                        azure_cost = azure_costs['vm_costs'].get(vm_size, azure_costs['vm_costs']['default'])
                        
                        total_aws_cost += aws_cost
                        total_azure_cost += azure_cost
                        resources['vms'].append({
                            'name': vm.name, 'azure_size': vm.hardware_profile.vm_size, 
                            'aws_type': aws_type, 'aws_cost': aws_cost, 'azure_cost': azure_cost
                        })
                    except: pass
                
                elif 'storageaccount' in resource_type:
                    estimated_gb = 100  # Assume 100GB average usage
                    
                    # AWS S3 cost
                    aws_cost = estimated_gb * aws_storage_cost_per_gb
                    
                    # Azure Storage cost (assume Standard LRS)
                    azure_cost = estimated_gb * azure_costs['storage_costs']['standard_lrs']
                    
                    total_aws_cost += aws_cost
                    total_azure_cost += azure_cost
                    resources['storage'].append({
                        'name': resource.name, 'estimated_gb': estimated_gb,
                        'aws_cost': aws_cost, 'azure_cost': azure_cost
                    })
                
                elif 'database' in resource_type and 'sql' in resource_type:
                    # AWS RDS cost
                    aws_cost = aws_db_costs['db.t3.medium']  # Default
                    
                    # Azure SQL cost (assume Standard S1)
                    azure_cost = azure_costs['sql_costs']['standard_s1']
                    
                    total_aws_cost += aws_cost
                    total_azure_cost += azure_cost
                    resources['sql'].append({
                        'name': resource.name, 'aws_cost': aws_cost, 'azure_cost': azure_cost
                    })
                
                elif 'microsoft.web/sites' in resource_type:
                    # AWS Lambda + API Gateway cost
                    aws_cost = 10.0  # Lambda estimate
                    
                    # Azure App Service cost (assume Basic B1)
                    azure_cost = azure_costs['app_costs']['basic_b1']
                    
                    total_aws_cost += aws_cost
                    total_azure_cost += azure_cost
                    resources['apps'].append({
                        'name': resource.name, 'aws_cost': aws_cost, 'azure_cost': azure_cost
                    })
                
                else:
                    resources['other'].append({'name': resource.name, 'type': resource.type})
            
            return resources, total_aws_cost, total_azure_cost
            
        except Exception as e:
            print(f"❌ Error analyzing resources: {e}")
            return resources, 0, 0

def main():
    analyzer = SimpleAnalyzer()
    resources, total_aws_cost, total_azure_cost = analyzer.analyze()
    
    print("\n" + "="*80)
    print("🎯 AZURE VS AWS COST COMPARISON REPORT")
    print("="*80)
    print(f"📅 Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    if resources['vms']:
        print("💻 VIRTUAL MACHINES → EC2 INSTANCES")
        print("-" * 60)
        for vm in resources['vms']:
            print(f"   • {vm['name']}")
            print(f"     Azure: {vm['azure_size']} (${vm['azure_cost']:.2f}/month)")
            print(f"     AWS: {vm['aws_type']} (${vm['aws_cost']:.2f}/month)")
            savings = vm['azure_cost'] - vm['aws_cost']
            if savings > 0:
                print(f"     💰 AWS saves ${savings:.2f}/month ({savings/vm['azure_cost']*100:.1f}%)")
            elif savings < 0:
                print(f"     💸 Azure saves ${-savings:.2f}/month ({-savings/vm['aws_cost']*100:.1f}%)")
            else:
                print(f"     ⚖️  Similar costs")
        print()
    
    if resources['storage']:
        print("💾 STORAGE ACCOUNTS → S3 BUCKETS")
        print("-" * 60)
        for storage in resources['storage']:
            print(f"   • {storage['name']} (assuming {storage['estimated_gb']}GB)")
            print(f"     Azure: Standard LRS (${storage['azure_cost']:.2f}/month)")
            print(f"     AWS: S3 Standard (${storage['aws_cost']:.2f}/month)")
            savings = storage['azure_cost'] - storage['aws_cost']
            if savings > 0:
                print(f"     💰 AWS saves ${savings:.2f}/month ({savings/storage['azure_cost']*100:.1f}%)")
            elif savings < 0:
                print(f"     💸 Azure saves ${-savings:.2f}/month ({-savings/storage['aws_cost']*100:.1f}%)")
            else:
                print(f"     ⚖️  Similar costs")
        print()
    
    if resources['sql']:
        print("🗄️  SQL DATABASES → RDS INSTANCES")
        print("-" * 60)
        for db in resources['sql']:
            print(f"   • {db['name']}")
            print(f"     Azure: Standard S1 (${db['azure_cost']:.2f}/month)")
            print(f"     AWS: RDS db.t3.medium (${db['aws_cost']:.2f}/month)")
            savings = db['azure_cost'] - db['aws_cost']
            if savings > 0:
                print(f"     💰 AWS saves ${savings:.2f}/month ({savings/db['azure_cost']*100:.1f}%)")
            elif savings < 0:
                print(f"     💸 Azure saves ${-savings:.2f}/month ({-savings/db['aws_cost']*100:.1f}%)")
            else:
                print(f"     ⚖️  Similar costs")
        print()
    
    if resources['apps']:
        print("🌐 APP SERVICES → LAMBDA + API GATEWAY")
        print("-" * 60)
        for app in resources['apps']:
            print(f"   • {app['name']}")
            print(f"     Azure: Basic B1 (${app['azure_cost']:.2f}/month)")
            print(f"     AWS: Lambda + API Gateway (${app['aws_cost']:.2f}/month)")
            savings = app['azure_cost'] - app['aws_cost']
            if savings > 0:
                print(f"     💰 AWS saves ${savings:.2f}/month ({savings/app['azure_cost']*100:.1f}%)")
            elif savings < 0:
                print(f"     💸 Azure saves ${-savings:.2f}/month ({-savings/app['aws_cost']*100:.1f}%)")
            else:
                print(f"     ⚖️  Similar costs")
        print()
    
    if resources['other']:
        print(f"📋 OTHER RESOURCES ({len(resources['other'])} found)")
        print("-" * 50)
        for other in resources['other'][:5]:  # Show first 5
            print(f"   • {other['name']} ({other['type']})")
        if len(resources['other']) > 5:
            print(f"   ... and {len(resources['other']) - 5} more")
        print()
    
    print("="*80)
    print("💰 COST COMPARISON SUMMARY")
    print("="*80)
    print(f"Azure (Current):     ${total_azure_cost:.2f}/month")
    print(f"AWS (Equivalent):    ${total_aws_cost:.2f}/month")
    print("-" * 80)
    
    total_savings = total_azure_cost - total_aws_cost
    if total_savings > 0:
        print(f"💰 Potential AWS Savings: ${total_savings:.2f}/month ({total_savings/total_azure_cost*100:.1f}%)")
        print(f"💡 Annual AWS Savings:    ${total_savings*12:.2f}/year")
    elif total_savings < 0:
        print(f"💸 Azure is Cheaper by:   ${-total_savings:.2f}/month ({-total_savings/total_aws_cost*100:.1f}%)")
        print(f"💡 Stay with Azure:       Saves ${-total_savings*12:.2f}/year")
    else:
        print("⚖️  Costs are very similar between Azure and AWS")
    
    print("="*80)
    print()
    print("📝 IMPORTANT NOTES:")
    print("   • These are rough estimates for planning purposes")
    print("   • Actual costs vary based on usage, region, and discounts")
    print("   • Use official pricing calculators for detailed estimates")
    print("   • Consider reserved instances for 25-60% additional savings")
    print("   • Factor in migration costs and operational complexity")
    
    # Save report
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = f"azure_aws_analysis_{timestamp}.txt"
    
    with open(filename, 'w') as f:
        f.write("AZURE VS AWS COST COMPARISON REPORT\n")
        f.write("="*50 + "\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        
        f.write("COST SUMMARY:\n")
        f.write(f"Azure (Current):    ${total_azure_cost:.2f}/month\n")
        f.write(f"AWS (Equivalent):   ${total_aws_cost:.2f}/month\n")
        total_savings = total_azure_cost - total_aws_cost
        if total_savings > 0:
            f.write(f"AWS Savings:        ${total_savings:.2f}/month ({total_savings/total_azure_cost*100:.1f}%)\n")
        elif total_savings < 0:
            f.write(f"Azure Advantage:    ${-total_savings:.2f}/month ({-total_savings/total_aws_cost*100:.1f}%)\n")
        f.write(f"Annual Impact:      ${total_savings*12:.2f}/year\n\n")
        
        f.write("DETAILED BREAKDOWN:\n\n")
        
        f.write("VIRTUAL MACHINES:\n")
        for vm in resources['vms']:
            f.write(f"  {vm['name']}: Azure {vm['azure_size']} (${vm['azure_cost']:.2f}) → AWS {vm['aws_type']} (${vm['aws_cost']:.2f})\n")
        
        f.write("\nSTORAGE ACCOUNTS:\n")
        for storage in resources['storage']:
            f.write(f"  {storage['name']}: Azure (${storage['azure_cost']:.2f}) → AWS S3 (${storage['aws_cost']:.2f})\n")
        
        f.write("\nSQL DATABASES:\n")
        for db in resources['sql']:
            f.write(f"  {db['name']}: Azure (${db['azure_cost']:.2f}) → AWS RDS (${db['aws_cost']:.2f})\n")
        
        f.write("\nAPP SERVICES:\n")
        for app in resources['apps']:
            f.write(f"  {app['name']}: Azure (${app['azure_cost']:.2f}) → AWS Lambda (${app['aws_cost']:.2f})\n")
    
    print(f"📄 Report saved to: {filename}")

if __name__ == "__main__":
    main()
EOF

print_success "Analyzer script created!"

# Step 6: Run the analysis
print_step "Running Azure Resource Analysis"
print_info "This will scan your Azure subscription and estimate AWS costs..."
echo ""

python3 azure_analyzer.py

# Step 7: Cleanup and summary
print_step "Analysis Complete!"
echo ""
print_success "🎉 All done! Here's what happened:"
print_info "   ✓ Installed Azure CLI (if needed)"
print_info "   ✓ Installed Python dependencies"
print_info "   ✓ Logged into your Azure account"
print_info "   ✓ Scanned your Azure resources"
print_info "   ✓ Estimated AWS costs"
print_info "   ✓ Saved detailed report to file"
echo ""
print_info "💡 Tips for next time:"
print_info "   • Your Azure login will stay active for a while"
print_info "   • Just run './analyze.sh' again to re-analyze"
print_info "   • Check the saved report file for details"
echo ""
print_success "Thanks for using Azure to AWS Cost Analyzer! 🚀"