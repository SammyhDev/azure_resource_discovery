@echo off
REM Windows Batch Script for Azure Resource Discovery
REM This script sets up and runs the Azure analyzer on Windows

echo.
echo 🚀 Azure to AWS Cost Analyzer - Windows Version
echo ================================================
echo.
echo This script will:
echo • Check for required tools
echo • Help you login to Azure
echo • Install Python dependencies
echo • Analyze your Azure resources
echo • Show AWS cost estimates
echo.
echo Just follow the prompts!
echo.

REM Check if Azure CLI is installed
where az >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Azure CLI not found!
    echo.
    echo Please install Azure CLI first:
    echo 1. Go to: https://aka.ms/installazurecliwindows
    echo 2. Download and install Azure CLI
    echo 3. Restart your command prompt
    echo 4. Run this script again
    echo.
    pause
    exit /b 1
)

echo ✅ Azure CLI found!

REM Check if Python is installed
python --version >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Python not found!
    echo.
    echo Please install Python first:
    echo 1. Go to: https://python.org/downloads
    echo 2. Download and install Python 3.8 or later
    echo 3. Make sure to check "Add Python to PATH"
    echo 4. Restart your command prompt
    echo 5. Run this script again
    echo.
    pause
    exit /b 1
)

echo ✅ Python found!

REM Install Python dependencies
echo.
echo 🔷 Installing Python dependencies...
echo ℹ️  This may take a moment - installing Azure SDK packages...
echo.

REM Try pip install with verbose output
pip install -r requirements.txt --user --upgrade
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Failed to install Python dependencies with pip
    echo.
    echo 🔧 Troubleshooting steps:
    echo 1. Make sure you have internet connection
    echo 2. Try running as Administrator
    echo 3. Update pip: python -m pip install --upgrade pip
    echo 4. Manual install: pip install azure-identity azure-mgmt-resource azure-mgmt-compute azure-mgmt-storage azure-mgmt-sql azure-mgmt-web requests
    echo.
    echo 📋 Required packages:
    type requirements.txt
    echo.
    pause
    exit /b 1
)

echo.
echo ✅ Python dependencies installed successfully!

REM Check Azure login
echo.
echo 🔷 Checking Azure login...
az account show >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo You need to login to Azure
    echo.
    echo Choose login method:
    echo 1^) 🌐 Open web browser ^(recommended^)
    echo 2^) 📱 Device code ^(for remote sessions^)
    echo.
    set /p "login_choice=Choose (1 or 2): "
    
    if "!login_choice!"=="1" (
        echo Opening web browser for login...
        az login
    ) else if "!login_choice!"=="2" (
        echo Starting device code login...
        echo You'll get a code to enter at https://microsoft.com/devicelogin
        az login --use-device-code
    ) else (
        echo Using default login...
        az login
    )
    
    if %ERRORLEVEL% NEQ 0 (
        echo ❌ Login failed. Please try again.
        pause
        exit /b 1
    )
)

echo ✅ Azure login successful!

REM Ask about MACC discount
echo.
echo 🔷 Azure Pricing Configuration
echo.
echo 💰 Microsoft Azure Consumption Commitment ^(MACC^) Discount
echo ==========================================================
echo.
echo Do you have a MACC ^(Microsoft Azure Consumption Commitment^) agreement
echo that provides volume discounts on your Azure consumption?
echo.
echo Examples:
echo • Enterprise agreements with negotiated discounts
echo • Volume commitment discounts ^(5%%, 10%%, 15%%, etc.^)
echo • Partner program discounts
echo.
set /p "has_macc=Do you have a MACC discount? (y/n): "

set MACC_DISCOUNT=0
if /i "!has_macc!"=="y" (
    echo.
    echo 📊 What percentage discount do you receive on Azure services?
    echo    ^(Enter just the number, e.g., '10' for 10%% discount^)
    echo.
    set /p "discount_input=Enter your MACC discount percentage (0-50): "
    
    REM Basic validation - check if it's a number
    echo !discount_input! | findstr /r "^[0-9][0-9]*$" >nul
    if !ERRORLEVEL! EQU 0 (
        if !discount_input! LEQ 50 (
            set MACC_DISCOUNT=!discount_input!
            echo ✅ Applied !MACC_DISCOUNT!%% MACC discount to Azure costs
        ) else (
            echo ⚠️  Invalid discount entered, using 0%% ^(no discount^)
            set MACC_DISCOUNT=0
        )
    ) else (
        echo ⚠️  Invalid discount entered, using 0%% ^(no discount^)
        set MACC_DISCOUNT=0
    )
) else (
    echo ℹ️  No MACC discount applied - using standard Azure pricing
)

echo.

REM Run the Python analyzer
echo 🔷 Running Azure Resource Analysis
echo ℹ️  This will scan your Azure subscription and estimate AWS costs...
echo.

set MACC_DISCOUNT=%MACC_DISCOUNT%
python scripts/azure_to_aws_cost_analyzer.py --macc-discount %MACC_DISCOUNT%

if %ERRORLEVEL% NEQ 0 (
    echo ❌ Analysis failed. Please check the error messages above.
    pause
    exit /b 1
)

echo.
echo 🔷 Analysis Complete!
echo.
echo ✅ 🎉 All done! Here's what happened:
echo ℹ️     ✓ Checked Azure CLI and Python
echo ℹ️     ✓ Installed Python dependencies
echo ℹ️     ✓ Logged into your Azure account
echo ℹ️     ✓ Applied MACC discount if specified
echo ℹ️     ✓ Scanned your Azure resources
echo ℹ️     ✓ Estimated AWS costs
echo.
echo ℹ️  💡 Tips for next time:
echo ℹ️     • Your Azure login will stay active for a while
echo ℹ️     • Just run 'analyze.bat' again to re-analyze
echo ℹ️     • Check any generated report files for details
echo.
echo ✅ Thanks for using Azure to AWS Cost Analyzer! 🚀
echo.
pause