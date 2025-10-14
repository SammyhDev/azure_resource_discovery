# Quick Start Guide

## 🚀 Get Started in 30 Seconds

### Step 1: Get the Code
```bash
git clone https://github.com/SammyhDev/azure_resource_discovery.git
cd azure_resource_discovery
```

### Step 2: Run the Analyzer
```bash
./analyze.sh
```

That's it! The script handles everything automatically.

## 🎯 What Happens Next

### 1. Automatic Setup
- ✅ Checks for Azure CLI (installs if needed)
- ✅ Installs Python dependencies
- ✅ Validates prerequisites

### 2. Azure Login
- 🌐 Opens browser for login OR
- 📱 Provides device code for remote sessions
- 🔐 Handles multiple subscriptions

### 3. Resource Discovery
- 🔍 Scans your Azure subscription
- 📊 Identifies VMs, Storage, Databases, Apps
- 💰 Calculates current Azure costs

### 4. AWS Cost Analysis
- 🎯 Maps to equivalent AWS services
- 💵 Calculates AWS pricing
- 📈 Shows potential savings

### 5. Results
```bash
💰 COST COMPARISON SUMMARY
================================================================================
Azure (Current):     $26.28/month
AWS (Equivalent):    $20.00/month
💰 Potential AWS Savings: $6.28/month (23.9%)
💡 Annual AWS Savings:    $75.36/year
================================================================================
```

## 📋 Sample Output

### Resource Breakdown:
```bash
🌐 APP SERVICES → LAMBDA + API GATEWAY
------------------------------------------------------------
   • your-web-app
     Azure: Basic B1 ($13.14/month)  
     AWS: Lambda + API Gateway ($10.00/month)
     💰 AWS saves $3.14/month (23.9%)

💻 VIRTUAL MACHINES → EC2 INSTANCES
------------------------------------------------------------  
   • production-vm
     Azure: Standard_D2s_v3 ($96.36/month)
     AWS: m5.large ($69.12/month)
     💰 AWS saves $27.24/month (28.3%)
```

## 🎛️ Advanced Options

### Save Report to File:
```bash
./analyze.sh  # Follow prompts to save report
```

### Use Different Scripts:
```bash
# Interactive guided setup
./scripts/run_analyzer.sh

# Just help with Azure login
./scripts/azure_login_helper.sh

# Full-featured analyzer with JSON output
python3 scripts/azure_to_aws_cost_analyzer.py --json --output report.json
```

## ❓ Need Help?

### Common Issues:
- **Azure CLI not found**: Script will install automatically
- **Login fails**: Try device code option for remote sessions
- **No resources found**: Check subscription permissions

### Get Support:
- Check the main [README](../README.md)
- Review [troubleshooting guide](../README.md#troubleshooting)
- Check [cost accuracy details](AWS_COST_ACCURACY.md)

## 🎉 Success!

Once complete, you'll have:
- ✅ Complete Azure resource inventory
- ✅ AWS cost comparison 
- ✅ Potential savings analysis
- ✅ Detailed report file
- ✅ Migration planning data

Ready to make informed cloud decisions! 🚀