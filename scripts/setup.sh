#!/bin/bash

# Azure to AWS Cost Analyzer Setup Script

echo "🚀 Setting up Azure to AWS Cost Analyzer..."

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.7 or higher."
    exit 1
fi

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed."
    echo "Please install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if user is logged into Azure CLI
if ! az account show &> /dev/null; then
    echo "❌ You are not logged into Azure CLI."
    echo "Please run: az login"
    exit 1
fi

echo "✅ Prerequisites check passed!"

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip3 install -r requirements.txt

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully!"
else
    echo "❌ Failed to install dependencies."
    exit 1
fi

# Make the main script executable
chmod +x azure_to_aws_cost_analyzer.py

echo ""
echo "🎉 Setup complete! You can now run the analyzer:"
echo ""
echo "Basic usage:"
echo "  python3 azure_to_aws_cost_analyzer.py"
echo ""
echo "Advanced usage:"
echo "  python3 azure_to_aws_cost_analyzer.py --subscription-id YOUR_SUB_ID --output report.txt"
echo "  python3 azure_to_aws_cost_analyzer.py --json --output report.json"
echo ""
echo "For help:"
echo "  python3 azure_to_aws_cost_analyzer.py --help"
echo ""