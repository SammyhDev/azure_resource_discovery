# Azure Resource Discovery & AWS Cost Analyzer

This tool discovers all resources in your Azure subscription and provides detailed cost comparisons between Azure and AWS. Perfect for cloud migration planning and cost optimization!

## 🚀 Ultra-Simple Usage with Dynamic Pricing

### Linux/macOS/WSL
**One command does everything:**
```bash
./analyze.sh
```

### Windows
**Choose your preferred method:**
```cmd
# Command Prompt
analyze.bat

# PowerShell  
.\analyze.ps1
```

That's it! The script will:
- ✅ Install Azure CLI if needed
- ✅ Install Python dependencies  
- ✅ Guide you through Azure login
- ✅ **Fetch live pricing from Azure API** (349+ VM SKUs)
- ✅ Discover all your Azure resources
- ✅ Show equivalent AWS costs with current market rates

## ✨ Key Features

- 🎯 **Ultra-Simple**: Single script handles everything automatically
- 🔄 **Dynamic Pricing**: Real-time pricing from Azure API (349+ VM SKUs)
- 💾 **Smart Caching**: 6-hour cache for performance with always-current data
- 🏢 **MACC Discount Support**: Applies enterprise volume discounts for accurate comparisons
- 🔐 **Secure Login**: Guided Azure CLI authentication with multiple options
- 📊 **Comprehensive Analysis**: Discovers VMs, Storage, SQL, Apps, and more
- 💰 **Live Cost Comparison**: Side-by-side Azure vs AWS with current rates
- 📈 **Enterprise-Ready**: Factors in your actual discounted Azure pricing  
- 📄 **Detailed Reports**: Saves analysis to timestamped files
- 🔄 **Multiple Subscriptions**: Easy subscription selection
- 🛠️ **Professional Tools**: Full analyzer suite for advanced users

## 📊 What You Get

### Side-by-Side Cost Comparison:
```bash
🌐 APP SERVICES → LAMBDA + API GATEWAY
------------------------------------------------------------
   • your-web-app
     Azure: Basic B1 ($13.14/month)
     AWS: Lambda + API Gateway ($8.50/month)
     💰 AWS saves $4.64/month (35.3%)

💰 COST COMPARISON SUMMARY
================================================================================
Azure (Current):     $26.28/month
AWS (Equivalent):    $17.00/month
💰 Potential AWS Savings: $9.28/month (35.3%)
💡 Annual AWS Savings:    $111.36/year
```

---

## 💻 Windows Users - Important Note

If you get PowerShell execution policy errors when trying to run bash scripts, use the Windows-specific versions:

**❌ Don't use:** `./analyze.sh` (this is for Linux/macOS)  
**✅ Use instead:** `analyze.bat` or `.\analyze.ps1`

### Quick Fix for PowerShell Issues:
```powershell
# If you get execution policy errors, run this once:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then run the analyzer:
.\analyze.ps1
```

---

## 🎯 Alternative Methods (Advanced Users)

### Method 1: Guided Interactive Setup
```bash
./scripts/run_analyzer.sh
```
Interactive script with step-by-step guidance

### Method 2: Azure Login Help Only  
```bash
./scripts/azure_login_helper.sh
```
Dedicated Azure login assistance

### Method 3: Full-Featured Analyzer
```bash
python3 scripts/azure_to_aws_cost_analyzer.py
```
Advanced analyzer with JSON output options

That's it! You'll get a comprehensive report showing:
- All your Azure resources
- Equivalent AWS services
- Estimated monthly costs in AWS

## 📊 What It Discovers & Analyzes

### Azure Resources → AWS Equivalents with Cost Comparison:
- **💻 Virtual Machines** → EC2 Instances (with exact size matching)
- **💾 Storage Accounts** → S3 Buckets (with tier comparisons)  
- **🗄️ SQL Databases** → RDS Instances (performance tier mapping)
- **🌐 App Services** → Lambda + API Gateway (serverless migration)
- **📋 Other Resources** → Catalogued with recommendations

### Comprehensive Cost Analysis:
- **Current Azure costs** (fetched from live Azure Pricing API)
- **Equivalent AWS costs** (real-time pricing with smart caching)
- **Side-by-side comparison** for each resource
- **Potential savings calculations** with percentages
- **Annual cost impact** projections
- **Migration recommendations** with cost optimization tips

### 🚀 Dynamic Pricing System:
- **Real-time Updates**: Fetches current pricing from official APIs
- **Smart Caching**: 6-hour cache for performance
- **349 Azure VM SKUs**: Comprehensive coverage of all VM types
- **Auto-Fallback**: Verified pricing if APIs are unavailable

### 🏢 Enterprise MACC Support:
- **Volume Discounts**: Applies your MACC discount percentages automatically
- **Accurate Comparisons**: Uses your actual Azure costs, not list prices
- **Enterprise Planning**: Perfect for organizations with volume commitments
- **Easy Configuration**: Simple interactive setup during analysis

## 💡 Usage Examples

### Basic Usage
```bash
# Analyze default subscription
python3 azure_to_aws_cost_analyzer.py
```

### Advanced Usage
```bash
# Specify subscription ID
python3 azure_to_aws_cost_analyzer.py --subscription-id "your-subscription-id"

# Save report to file
python3 azure_to_aws_cost_analyzer.py --output azure_aws_analysis.txt

# Get JSON output for further processing
python3 azure_to_aws_cost_analyzer.py --json --output report.json

# Help
python3 azure_to_aws_cost_analyzer.py --help
```

## 📋 Sample Output

```
================================================================================
AZURE RESOURCE DISCOVERY & AWS COST ESTIMATION REPORT
================================================================================
Generated: 2025-10-14 10:30:45

AZURE RESOURCES SUMMARY
----------------------------------------
Virtual Machines: 3
Storage Accounts: 2
SQL Databases: 1
App Services: 2
Other Resources: 5

VIRTUAL MACHINES
----------------------------------------
• web-server-01 (Standard_B2s) in East US
• db-server-01 (Standard_D2s_v3) in East US
• test-vm (Standard_B1ms) in West Europe

AWS COST ESTIMATES
----------------------------------------
EC2 Instances (from Azure VMs):
  • web-server-01 → t3.small: $15.20/month
  • db-server-01 → m5.large: $70.10/month
  • test-vm → t3.micro: $7.60/month

S3 Storage (from Azure Storage):
  • storageaccount01 → S3 Standard: $2.30/month
  • backupstorage → S3 IA: $1.25/month

================================================================================
ESTIMATED TOTAL MONTHLY AWS COST: $96.45
================================================================================
```

## ⚙️ Manual Installation

If the setup script doesn't work, you can install manually:

```bash
# Install Python dependencies
pip3 install -r requirements.txt

# Or install individually:
pip3 install azure-identity azure-mgmt-resource azure-mgmt-compute \
            azure-mgmt-storage azure-mgmt-sql azure-mgmt-web requests
```

## 🔧 Configuration

### Authentication
The script uses Azure CLI authentication by default. Make sure you're logged in:
```bash
az login
az account set --subscription "your-subscription-id"
```

### Subscription Selection
- **Automatic**: Uses your default Azure CLI subscription
- **Manual**: Use `--subscription-id` parameter

## ⚠️ Important Notes

### Cost Estimates Accuracy
- **Rough Estimates**: Prices are approximations based on typical usage
- **Variable Factors**: Actual costs depend on:
  - Real resource utilization
  - Data transfer costs
  - Reserved instance discounts
  - Specific AWS regions
  - Current AWS pricing (prices change)

### For Accurate Planning
- Use [AWS Pricing Calculator](https://calculator.aws/) for detailed estimates
- Consider AWS migration tools and services
- Factor in migration costs and downtime
- Review AWS architectural best practices

## 🛡️ Permissions Required

The script needs read access to:
- Resource groups
- Virtual machines
- Storage accounts
- SQL servers and databases
- App services
- General resource information

Typically, the **Reader** role on the subscription is sufficient.

## 🐛 Troubleshooting

### Azure CLI Login Issues

**"Unable to get default subscription" error:**
1. Run the login helper: `./azure_login_helper.sh`
2. Or manually: `az login`
3. If multiple subscriptions: `az account set --subscription "your-subscription-id"`

**Login fails in remote/headless environment:**
```bash
az login --use-device-code
```

**Browser doesn't open:**
- Use device code login: `az login --use-device-code`
- Or set browser manually: `az login --use-device-code`

**Multiple tenants:**
```bash
az login --tenant "your-tenant-id"
```

### Common Issues

**"Missing required package" error:**
```bash
pip3 install -r requirements.txt
```

**Permission errors:**
- Ensure you have **Reader** role on the subscription
- Check that your Azure CLI session hasn't expired: `az account show`
- Try refreshing login: `az account get-access-token`

**No resources found:**
- Verify you're analyzing the correct subscription: `az account show`
- Check that resources exist: `az resource list --query "length(@)"`
- Ensure you have proper permissions

**SSL/Certificate errors:**
```bash
az login --use-device-code
```

**"Command 'az' not found":**
- Install Azure CLI: see Prerequisites section
- Or use the setup script: `./run_analyzer.sh`

## 📝 Output Formats

### Text Report (Default)
Human-readable report with summaries and cost estimates

### JSON Output
Machine-readable format for integration with other tools:
```bash
python3 azure_to_aws_cost_analyzer.py --json --output data.json
```

## 🤝 Contributing

Feel free to:
- Report bugs
- Suggest improvements
- Add support for more Azure services
- Improve cost estimation accuracy
- Add new output formats

## � Repository Structure

```
azure_resource_discovery/
├── analyze.sh                 # 🚀 Main script - just run this!
├── requirements.txt           # Python dependencies
├── Makefile                   # Build automation
├── scripts/                   # Advanced tools
│   ├── azure_to_aws_cost_analyzer.py  # Full-featured analyzer
│   ├── run_analyzer.sh                 # Interactive guided setup
│   ├── azure_login_helper.sh          # Azure login assistance
│   ├── setup.sh                       # Manual setup script
│   └── pricing_accuracy_check.py      # Pricing validation tool
├── docs/                      # Documentation
│   └── AWS_COST_ACCURACY.md   # Detailed accuracy analysis
└── examples/                  # Sample outputs and tests
    ├── test_analyzer.py       # Test suite
    └── *.txt                  # Example reports
```

## 🎯 Accuracy & Reliability

- **Overall Accuracy**: 7.4% average error rate ([detailed analysis](docs/AWS_COST_ACCURACY.md))
- **EC2 Pricing**: 0.7% error (extremely accurate)
- **S3 Storage**: 0.0% error (perfectly accurate)  
- **RDS Databases**: 11.1% error (good accuracy)
- **Based on**: Current AWS pricing (October 2024)

## �📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Useful Links

- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [AWS Pricing Calculator](https://calculator.aws/)
- [Azure to AWS Services Comparison](https://docs.aws.amazon.com/whitepapers/latest/aws-microsoft-workload-comparison/services-comparison.html)
- [Cost Accuracy Analysis](docs/AWS_COST_ACCURACY.md)