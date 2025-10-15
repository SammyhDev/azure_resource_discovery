@echo off
REM Dependency Checker and Installer for Azure Resource Discovery
REM Run this if you have issues with the main analyzer

echo.
echo 🔧 Azure Resource Discovery - Dependency Checker
echo ================================================
echo.

REM Check Python
echo 🔷 Checking Python...
python --version >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    python --version
    echo ✅ Python is installed
) else (
    echo ❌ Python not found
    echo Download from: https://python.org/downloads
    goto :end
)

REM Check pip
echo.
echo 🔷 Checking pip...
pip --version >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    pip --version
    echo ✅ pip is available
) else (
    echo ❌ pip not found
    echo Try: python -m ensurepip --upgrade
    goto :end
)

REM Check Azure CLI
echo.
echo 🔷 Checking Azure CLI...
az --version >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    az --version | findstr "azure-cli"
    echo ✅ Azure CLI is installed
) else (
    echo ❌ Azure CLI not found
    echo Download from: https://aka.ms/installazurecliwindows
    goto :end
)

REM Upgrade pip first
echo.
echo 🔷 Upgrading pip...
python -m pip install --upgrade pip --user

REM Install Python packages
echo.
echo 🔷 Installing Python packages...
echo.

REM Method 1: Try with python -m pip (more reliable)
echo Installing: azure-identity
python -m pip install azure-identity --user --upgrade --no-warn-script-location
echo.
echo Installing: azure-mgmt-resource
python -m pip install azure-mgmt-resource --user --upgrade --no-warn-script-location
echo.
echo Installing: azure-mgmt-compute  
python -m pip install azure-mgmt-compute --user --upgrade --no-warn-script-location
echo.
echo Installing: azure-mgmt-storage
python -m pip install azure-mgmt-storage --user --upgrade --no-warn-script-location
echo.
echo Installing: azure-mgmt-sql
python -m pip install azure-mgmt-sql --user --upgrade --no-warn-script-location
echo.
echo Installing: azure-mgmt-web
python -m pip install azure-mgmt-web --user --upgrade --no-warn-script-location
echo.
echo Installing: requests
python -m pip install requests --user --upgrade --no-warn-script-location

echo.
echo 🔷 Alternative installation attempt (if any failed above)...
pip install azure-identity azure-mgmt-resource azure-mgmt-compute azure-mgmt-storage azure-mgmt-sql azure-mgmt-web requests --user --upgrade --no-warn-script-location

echo.
echo 🔷 Testing imports...
python -c "import azure.identity; print('✅ azure-identity works')" 2>nul || echo "❌ azure-identity failed"
python -c "import azure.mgmt.resource; print('✅ azure-mgmt-resource works')" 2>nul || echo "❌ azure-mgmt-resource failed"
python -c "import azure.mgmt.compute; print('✅ azure-mgmt-compute works')" 2>nul || echo "❌ azure-mgmt-compute failed"
python -c "import azure.mgmt.storage; print('✅ azure-mgmt-storage works')" 2>nul || echo "❌ azure-mgmt-storage failed"
python -c "import azure.mgmt.sql; print('✅ azure-mgmt-sql works')" 2>nul || echo "❌ azure-mgmt-sql failed"
python -c "import azure.mgmt.web; print('✅ azure-mgmt-web works')" 2>nul || echo "❌ azure-mgmt-web failed"
python -c "import requests; print('✅ requests works')" 2>nul || echo "❌ requests failed"

echo.
echo 🎯 Dependency check complete!
echo.
echo If all packages show ✅, you can now run:
echo   analyze.bat   (for Command Prompt)
echo   analyze.ps1   (for PowerShell)
echo.

:end
pause