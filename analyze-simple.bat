@echo off
setlocal enabledelayedexpansion
REM Simplified Azure Resource Discovery - Just the essentials

echo.
echo 🚀 Azure Resource Discovery - Simple Version
echo ===========================================
echo.

REM Check Python
python --version >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Python not found! Install from https://python.org/downloads
    pause
    exit /b 1
)
echo ✅ Python found

REM Check Azure CLI
az --version >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Azure CLI not found! Install from https://aka.ms/installazurecliwindows
    pause
    exit /b 1
)
echo ✅ Azure CLI found

REM Install dependencies - multiple methods
echo.
echo 🔷 Installing dependencies (this may take a few minutes)...

REM Try the simple approach first
python -m pip install azure-identity azure-mgmt-resource azure-mgmt-compute azure-mgmt-storage azure-mgmt-sql azure-mgmt-web requests --user --upgrade

REM Test if the main packages work
python -c "import azure.identity, azure.mgmt.resource, requests" >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ All dependencies installed successfully!
) else (
    echo ⚠️  Some packages may have failed. Trying alternative method...
    
    REM Try installing one by one
    python -m pip install azure-identity --user
    python -m pip install azure-mgmt-resource --user
    python -m pip install azure-mgmt-compute --user
    python -m pip install azure-mgmt-storage --user
    python -m pip install azure-mgmt-sql --user
    python -m pip install azure-mgmt-web --user
    python -m pip install requests --user
)

REM Ask about MACC discount
echo.
set /p "macc_discount=Enter your MACC discount percentage (0 if none): "
if "%macc_discount%"=="" set macc_discount=0

REM Run the analyzer
echo.
echo 🔷 Running analysis...
python scripts/azure_to_aws_cost_analyzer.py --macc-discount %macc_discount%

echo.
echo 🎉 Analysis complete! Check the output above for your results.
pause