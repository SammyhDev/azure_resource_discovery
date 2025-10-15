# Azure Resource Discovery - Windows PowerShell Script
# Ultra-simple Azure to AWS cost analyzer for Windows

# Enable delayed variable expansion
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "🚀 Azure to AWS Cost Analyzer - Windows PowerShell Version" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will:" -ForegroundColor White
Write-Host "• Check for required tools" -ForegroundColor Green
Write-Host "• Help you login to Azure" -ForegroundColor Green
Write-Host "• Install Python dependencies" -ForegroundColor Green
Write-Host "• Analyze your Azure resources" -ForegroundColor Green
Write-Host "• Show AWS cost estimates" -ForegroundColor Green
Write-Host ""
Write-Host "Just follow the prompts!" -ForegroundColor Yellow
Write-Host ""

# Function to print colored messages
function Write-Step {
    param($Message)
    Write-Host "🔷 STEP: $Message" -ForegroundColor Magenta
}

function Write-Success {
    param($Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param($Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param($Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param($Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
}

# Check if Azure CLI is installed
Write-Step "Checking Azure CLI"
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Success "Azure CLI found: $($azVersion.'azure-cli')"
}
catch {
    Write-Error "Azure CLI not found!"
    Write-Host ""
    Write-Host "Please install Azure CLI first:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://aka.ms/installazurecliwindows" -ForegroundColor White
    Write-Host "2. Download and install Azure CLI" -ForegroundColor White
    Write-Host "3. Restart PowerShell" -ForegroundColor White
    Write-Host "4. Run this script again" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if Python is installed
Write-Step "Checking Python"
try {
    $pythonVersion = python --version
    Write-Success "Python found: $pythonVersion"
    
    # Check pip
    pip --version | Out-Null
    Write-Success "pip found"
}
catch {
    Write-Error "Python not found!"
    Write-Host ""
    Write-Host "Please install Python first:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://python.org/downloads" -ForegroundColor White
    Write-Host "2. Download and install Python 3.8 or later" -ForegroundColor White
    Write-Host "3. Make sure to check 'Add Python to PATH'" -ForegroundColor White
    Write-Host "4. Restart PowerShell" -ForegroundColor White
    Write-Host "5. Run this script again" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Install Python dependencies
Write-Step "Installing Python dependencies"
Write-Info "This may take a moment..."
try {
    pip install -r requirements.txt | Out-Null
    Write-Success "Python dependencies installed!"
}
catch {
    Write-Error "Failed to install Python dependencies"
    Write-Host "Error: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check Azure login
Write-Step "Azure Login"
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Success "Already logged into Azure!"
    Write-Info "Current subscription: $($account.name)"
    Write-Info "Subscription ID: $($account.id)"
    
    $continue = Read-Host "Continue with this subscription? (y/n)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        # Show subscriptions and let user choose
        $subs = az account list --output json | ConvertFrom-Json
        if ($subs.Count -gt 1) {
            Write-Info "You have $($subs.Count) subscriptions"
            $showSubs = Read-Host "Would you like to see them and choose one? (y/n)"
            if ($showSubs -eq "y" -or $showSubs -eq "Y") {
                Write-Host ""
                az account list --output table
                Write-Host ""
                $chosenSub = Read-Host "Enter subscription ID or name (or press Enter for current)"
                if ($chosenSub) {
                    az account set --subscription $chosenSub
                    Write-Success "Switched to subscription: $chosenSub"
                }
            }
        }
    }
}
catch {
    Write-Info "You need to login to Azure"
    Write-Host ""
    Write-Host "Choose login method:" -ForegroundColor White
    Write-Host "1) 🌐 Open web browser (recommended)" -ForegroundColor White
    Write-Host "2) 📱 Device code (for remote sessions)" -ForegroundColor White
    Write-Host ""
    $loginChoice = Read-Host "Choose (1 or 2)"
    
    try {
        switch ($loginChoice) {
            "1" {
                Write-Info "Opening web browser for login..."
                az login | Out-Null
            }
            "2" {
                Write-Info "Starting device code login..."
                Write-Host "You'll get a code to enter at https://microsoft.com/devicelogin" -ForegroundColor Yellow
                az login --use-device-code | Out-Null
            }
            default {
                Write-Info "Using default login..."
                az login | Out-Null
            }
        }
        Write-Success "Successfully logged into Azure!"
    }
    catch {
        Write-Error "Login failed. Please try again."
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Ask about MACC discount
Write-Step "Azure Pricing Configuration"
Write-Host ""
Write-Host "💰 Microsoft Azure Consumption Commitment (MACC) Discount" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Do you have a MACC (Microsoft Azure Consumption Commitment) agreement" -ForegroundColor White
Write-Host "that provides volume discounts on your Azure consumption?" -ForegroundColor White
Write-Host ""
Write-Host "Examples:" -ForegroundColor Yellow
Write-Host "• Enterprise agreements with negotiated discounts" -ForegroundColor White
Write-Host "• Volume commitment discounts (5%, 10%, 15%, etc.)" -ForegroundColor White
Write-Host "• Partner program discounts" -ForegroundColor White
Write-Host ""

$hasMacc = Read-Host "Do you have a MACC discount? (y/n)"
$maccDiscount = 0

if ($hasMacc -eq "y" -or $hasMacc -eq "Y") {
    Write-Host ""
    Write-Host "📊 What percentage discount do you receive on Azure services?" -ForegroundColor Cyan
    Write-Host "   (Enter just the number, e.g., '10' for 10% discount)" -ForegroundColor White
    Write-Host ""
    
    $discountInput = Read-Host "Enter your MACC discount percentage (0-50)"
    
    # Validate discount input
    if ($discountInput -match '^\d+$' -and [int]$discountInput -ge 0 -and [int]$discountInput -le 50) {
        $maccDiscount = [int]$discountInput
        Write-Success "Applied $maccDiscount% MACC discount to Azure costs"
    }
    else {
        Write-Warning "Invalid discount entered, using 0% (no discount)"
        $maccDiscount = 0
    }
}
else {
    Write-Info "No MACC discount applied - using standard Azure pricing"
}

Write-Host ""

# Run the analysis
Write-Step "Running Azure Resource Analysis"
Write-Info "This will scan your Azure subscription and estimate AWS costs..."
Write-Host ""

try {
    $env:MACC_DISCOUNT = $maccDiscount
    python scripts/azure_to_aws_cost_analyzer.py --macc-discount $maccDiscount
    
    Write-Host ""
    Write-Step "Analysis Complete!"
    Write-Host ""
    Write-Success "🎉 All done! Here's what happened:"
    Write-Info "   ✓ Checked Azure CLI and Python"
    Write-Info "   ✓ Installed Python dependencies"
    Write-Info "   ✓ Logged into your Azure account"
    Write-Info "   ✓ Applied MACC discount if specified"
    Write-Info "   ✓ Scanned your Azure resources"
    Write-Info "   ✓ Estimated AWS costs"
    Write-Host ""
    Write-Info "💡 Tips for next time:"
    Write-Info "   • Your Azure login will stay active for a while"
    Write-Info "   • Just run 'analyze.ps1' again to re-analyze"
    Write-Info "   • Check any generated report files for details"
    Write-Host ""
    Write-Success "Thanks for using Azure to AWS Cost Analyzer! 🚀"
}
catch {
    Write-Error "Analysis failed. Please check the error messages above."
    Write-Host "Error: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Read-Host "Press Enter to exit"