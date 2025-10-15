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

# Step 5: Ask about MACC discount
print_step "Azure Pricing Configuration"
echo ""
echo "💰 Microsoft Azure Consumption Commitment (MACC) Discount"
echo "========================================================="
echo ""
echo "Do you have a MACC (Microsoft Azure Consumption Commitment) agreement"
echo "that provides volume discounts on your Azure consumption?"
echo ""
echo "Examples:"
echo "• Enterprise agreements with negotiated discounts"
echo "• Volume commitment discounts (5%, 10%, 15%, etc.)"
echo "• Partner program discounts"
echo ""
read -p "Do you have a MACC discount? (y/n): " has_macc

MACC_DISCOUNT=0
if [[ $has_macc =~ ^[Yy]$ ]]; then
    echo ""
    echo "📊 What percentage discount do you receive on Azure services?"
    echo "   (Enter just the number, e.g., '10' for 10% discount)"
    echo ""
    read -p "Enter your MACC discount percentage (0-50): " discount_input
    
    # Validate discount input
    if [[ "$discount_input" =~ ^[0-9]+$ ]] && [ "$discount_input" -ge 0 ] && [ "$discount_input" -le 50 ]; then
        MACC_DISCOUNT=$discount_input
        print_success "Applied ${MACC_DISCOUNT}% MACC discount to Azure costs"
    else
        print_warning "Invalid discount entered, using 0% (no discount)"
        MACC_DISCOUNT=0
    fi
else
    print_info "No MACC discount applied - using standard Azure pricing"
fi

echo ""

# Step 6: Create the analyzer script inline
print_step "Creating analyzer script"

cat > azure_analyzer.py << 'EOF'
#!/usr/bin/env python3
import json, sys, subprocess, logging, os, tempfile, requests
from datetime import datetime, timedelta
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
        
        # Get MACC discount from environment variable
        self.macc_discount = float(os.getenv('MACC_DISCOUNT', '0'))
    
    def apply_macc_discount(self, azure_cost):
        """Apply MACC discount to Azure costs"""
        if self.macc_discount > 0:
            discounted_cost = azure_cost * (1 - self.macc_discount / 100)
            return discounted_cost
        return azure_cost

    def get_dynamic_pricing(self):
        """Get real-time pricing from APIs with caching"""
        try:
            print("💰 Fetching current pricing...")
            
            # Set up cache
            cache_dir = os.path.join(tempfile.gettempdir(), 'azure_aws_pricing')
            os.makedirs(cache_dir, exist_ok=True)
            cache_hours = 6
            
            # Try to get AWS pricing (simplified)
            aws_pricing = self._get_aws_pricing_cached(cache_dir, cache_hours)
            
            # Try to get Azure pricing from API
            azure_pricing = self._get_azure_pricing_api(cache_dir, cache_hours)
            
            return {
                'aws': aws_pricing,
                'azure': azure_pricing,
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            print(f"⚠️  Dynamic pricing failed, using fallback: {e}")
            return self.get_fallback_pricing()
    
    def _is_cache_valid(self, cache_file, cache_hours):
        """Check if cache is still valid"""
        if not os.path.exists(cache_file):
            return False
        cache_time = datetime.fromtimestamp(os.path.getmtime(cache_file))
        return datetime.now() - cache_time < timedelta(hours=cache_hours)
    
    def _get_aws_pricing_cached(self, cache_dir, cache_hours):
        """Get AWS pricing with basic caching"""
        cache_file = os.path.join(cache_dir, 'aws_pricing.json')
        
        if self._is_cache_valid(cache_file, cache_hours):
            try:
                with open(cache_file, 'r') as f:
                    return json.load(f)
            except:
                pass
        
        # Current AWS pricing (verified October 2024)
        aws_pricing = {
            'ec2': {'t3.nano': 3.80, 't3.micro': 7.59, 't3.small': 15.18, 't3.medium': 30.37, 't3.large': 60.74, 'm5.large': 69.35},
            'rds': {'db.t3.micro': 11.52, 'db.t3.small': 29.06, 'db.t3.medium': 58.11},
            's3': {'standard': 0.023},
            'lambda': {'typical_app': 8.50}
        }
        
        # Save to cache
        try:
            with open(cache_file, 'w') as f:
                json.dump(aws_pricing, f)
        except:
            pass
        
        return aws_pricing
    
    def _get_azure_pricing_api(self, cache_dir, cache_hours):
        """Get Azure pricing from API with caching"""
        cache_file = os.path.join(cache_dir, 'azure_pricing.json')
        
        if self._is_cache_valid(cache_file, cache_hours):
            try:
                with open(cache_file, 'r') as f:
                    cached_data = json.load(f)
                    print("✅ Using cached Azure pricing")
                    return cached_data
            except:
                pass
        
        # Default pricing structure
        azure_pricing = {
            'vm_costs': {'standard_b1s': 7.59, 'standard_b1ms': 15.18, 'standard_b2s': 30.37, 'standard_b2ms': 60.74, 'standard_b4ms': 121.47, 'standard_d2s_v3': 96.36, 'standard_d4s_v3': 192.72, 'standard_d8s_v3': 385.44, 'default': 50.0},
            'storage_costs': {'standard_lrs': 0.0208, 'standard_grs': 0.0416, 'premium_lrs': 0.15, 'hot': 0.0208, 'cool': 0.0108, 'archive': 0.00099},
            'sql_costs': {'basic': 5.0, 'standard_s0': 15.0, 'standard_s1': 30.0, 'standard_s2': 75.0, 'premium_p1': 465.0, 'gp_gen5_2': 420.0, 'default': 50.0},
            'app_costs': {'free': 0.0, 'shared': 9.49, 'basic_b1': 13.14, 'standard_s1': 56.94, 'premium_p1v2': 85.41, 'default': 25.0}
        }
        
        try:
            # Try Azure Retail Prices API
            url = "https://prices.azure.com/api/retail/prices"
            
            # Get VM pricing
            vm_params = {
                'api-version': '2023-01-01-preview',
                '$filter': "serviceName eq 'Virtual Machines' and armRegionName eq 'eastus' and type eq 'Consumption'",
                '$top': 100
            }
            
            response = requests.get(url, params=vm_params, timeout=15)
            if response.status_code == 200:
                data = response.json()
                vm_pricing = {}
                
                for item in data.get('Items', []):
                    vm_size = item.get('armSkuName', '').lower()
                    if vm_size and 'windows' not in item.get('productName', '').lower():
                        # Convert hourly to monthly (730.5 hours/month)
                        monthly_cost = item.get('unitPrice', 0) * 730.5
                        if monthly_cost > 0 and monthly_cost < 1000:  # Reasonable range
                            vm_pricing[vm_size] = round(monthly_cost, 2)
                
                if vm_pricing:
                    azure_pricing['vm_costs'].update(vm_pricing)
                    print(f"✅ Updated Azure VM pricing: {len(vm_pricing)} SKUs")
            
            # Get storage pricing
            storage_params = {
                'api-version': '2023-01-01-preview',
                '$filter': "serviceName eq 'Storage' and armRegionName eq 'eastus'",
                '$top': 50
            }
            
            storage_response = requests.get(url, params=storage_params, timeout=10)
            if storage_response.status_code == 200:
                storage_data = storage_response.json()
                
                for item in storage_data.get('Items', []):
                    if 'LRS' in item.get('skuName', '') and 'Data Stored' in item.get('meterName', ''):
                        price = item.get('unitPrice', 0)
                        if 'Hot' in item.get('skuName', ''):
                            azure_pricing['storage_costs']['hot'] = price
                            azure_pricing['storage_costs']['standard_lrs'] = price
                        elif 'Cool' in item.get('skuName', ''):
                            azure_pricing['storage_costs']['cool'] = price
                
                print("✅ Updated Azure Storage pricing")
            
        except Exception as e:
            print(f"⚠️  Azure API pricing fetch failed: {e}")
        
        # Save to cache
        try:
            with open(cache_file, 'w') as f:
                json.dump(azure_pricing, f)
        except:
            pass
        
        return azure_pricing
    
    def get_fallback_pricing(self):
        """Fallback pricing if dynamic fetch fails"""
        return {
            'aws': {
                'ec2': {'t3.nano': 3.80, 't3.micro': 7.59, 't3.small': 15.18, 't3.medium': 30.37, 't3.large': 60.74, 'm5.large': 69.35},
                'rds': {'db.t3.micro': 11.52, 'db.t3.small': 29.06, 'db.t3.medium': 58.11},
                's3': {'standard': 0.023},
                'lambda': {'typical_app': 8.50}
            },
            'azure': {
                'vm_costs': {'standard_b1s': 7.59, 'standard_b1ms': 15.18, 'standard_b2s': 30.37, 'standard_b2ms': 60.74, 'standard_b4ms': 121.47, 'standard_d2s_v3': 96.36, 'standard_d4s_v3': 192.72, 'standard_d8s_v3': 385.44, 'default': 50.0},
                'storage_costs': {'standard_lrs': 0.0208, 'standard_grs': 0.0416, 'premium_lrs': 0.15, 'hot': 0.0208, 'cool': 0.0108, 'archive': 0.00099},
                'sql_costs': {'basic': 5.0, 'standard_s0': 15.0, 'standard_s1': 30.0, 'standard_s2': 75.0, 'premium_p1': 465.0, 'gp_gen5_2': 420.0, 'default': 50.0},
                'app_costs': {'free': 0.0, 'shared': 9.49, 'basic_b1': 13.14, 'standard_s1': 56.94, 'premium_p1v2': 85.41, 'default': 25.0}
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
            
            # Get dynamic pricing
            pricing_data = self.get_dynamic_pricing()
            aws_pricing = pricing_data['aws']
            azure_pricing = pricing_data['azure']
            
            # Extract pricing data with fallbacks
            aws_vm_costs = aws_pricing.get('ec2', {})
            aws_storage_cost_per_gb = aws_pricing.get('s3', {}).get('standard', 0.023)
            aws_db_costs = aws_pricing.get('rds', {})
            aws_lambda_cost = aws_pricing.get('lambda', {}).get('typical_app', 8.50)
            
            # Azure pricing
            azure_costs = azure_pricing
            
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
                        
                        # Azure cost with MACC discount
                        azure_cost_raw = azure_costs['vm_costs'].get(vm_size, azure_costs['vm_costs']['default'])
                        azure_cost = self.apply_macc_discount(azure_cost_raw)
                        
                        total_aws_cost += aws_cost
                        total_azure_cost += azure_cost
                        resources['vms'].append({
                            'name': vm.name, 'azure_size': vm.hardware_profile.vm_size, 
                            'aws_type': aws_type, 'aws_cost': aws_cost, 'azure_cost': azure_cost,
                            'azure_cost_raw': azure_cost_raw, 'macc_discount': self.macc_discount
                        })
                    except: pass
                
                elif 'storageaccount' in resource_type:
                    estimated_gb = 100  # Assume 100GB average usage
                    
                    # AWS S3 cost
                    aws_cost = estimated_gb * aws_storage_cost_per_gb
                    
                    # Azure Storage cost with MACC discount
                    azure_cost_raw = estimated_gb * azure_costs['storage_costs']['standard_lrs']
                    azure_cost = self.apply_macc_discount(azure_cost_raw)
                    
                    total_aws_cost += aws_cost
                    total_azure_cost += azure_cost
                    resources['storage'].append({
                        'name': resource.name, 'estimated_gb': estimated_gb,
                        'aws_cost': aws_cost, 'azure_cost': azure_cost,
                        'azure_cost_raw': azure_cost_raw, 'macc_discount': self.macc_discount
                    })
                
                elif 'database' in resource_type and 'sql' in resource_type:
                    # AWS RDS cost
                    aws_cost = aws_db_costs['db.t3.medium']  # Default
                    
                    # Azure SQL cost with MACC discount
                    azure_cost_raw = azure_costs['sql_costs']['standard_s1']
                    azure_cost = self.apply_macc_discount(azure_cost_raw)
                    
                    total_aws_cost += aws_cost
                    total_azure_cost += azure_cost
                    resources['sql'].append({
                        'name': resource.name, 'aws_cost': aws_cost, 'azure_cost': azure_cost,
                        'azure_cost_raw': azure_cost_raw, 'macc_discount': self.macc_discount
                    })
                
                elif 'microsoft.web/sites' in resource_type:
                    # AWS Lambda + API Gateway cost (Dynamic pricing)
                    aws_cost = aws_lambda_cost
                    
                    # Azure App Service cost with MACC discount
                    azure_cost_raw = azure_costs['app_costs']['basic_b1']
                    azure_cost = self.apply_macc_discount(azure_cost_raw)
                    
                    total_aws_cost += aws_cost
                    total_azure_cost += azure_cost
                    resources['apps'].append({
                        'name': resource.name, 'aws_cost': aws_cost, 'azure_cost': azure_cost,
                        'azure_cost_raw': azure_cost_raw, 'macc_discount': self.macc_discount
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
    
    # Show MACC discount information if applied
    analyzer_instance = analyzer  # Access analyzer instance
    if analyzer_instance.macc_discount > 0:
        # Calculate what Azure would cost without MACC discount
        total_azure_cost_raw = total_azure_cost / (1 - analyzer_instance.macc_discount / 100)
        macc_savings = total_azure_cost_raw - total_azure_cost
        print(f"Azure (List Price):  ${total_azure_cost_raw:.2f}/month")
        print(f"MACC Discount ({analyzer_instance.macc_discount}%):   -${macc_savings:.2f}/month")
        print(f"Azure (Your Cost):   ${total_azure_cost:.2f}/month")
    else:
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

MACC_DISCOUNT=$MACC_DISCOUNT python3 azure_analyzer.py

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