@echo off
setlocal enabledelayedexpansion

echo.
echo 🚀 Azure to AWS Cost Analyzer - Windows (Debug Version)
echo ========================================================
echo.

REM Test Azure CLI
echo 1. Testing Azure CLI...
where az >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Azure CLI not found
    pause
    exit /b 1
)
echo ✅ Azure CLI found

REM Test Azure login
echo.
echo 2. Testing Azure login...
az account show >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Not logged into Azure
    echo Please run: az login
    pause
    exit /b 1
)
echo ✅ Logged into Azure

REM Show current subscription
echo.
echo 3. Current Azure subscription:
az account show --query "{name:name, id:id, user:user.name}" -o table

REM Test Python
echo.
echo 4. Testing Python...
python --version >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Python not found
    pause
    exit /b 1
)
echo ✅ Python found:
python --version

REM Test Python packages
echo.
echo 5. Testing Python packages...
python -c "import azure.identity; print('✅ azure-identity OK')" 2>nul || echo ❌ azure-identity missing
python -c "import azure.mgmt.resource; print('✅ azure-mgmt-resource OK')" 2>nul || echo ❌ azure-mgmt-resource missing
python -c "import requests; print('✅ requests OK')" 2>nul || echo ❌ requests missing

REM Test Azure credential access from Python
echo.
echo 6. Testing Azure access from Python...
python -c "
import subprocess
try:
    result = subprocess.run(['az', 'account', 'show', '--query', 'id', '-o', 'tsv'], capture_output=True, text=True, check=True)
    print('✅ Can get subscription ID:', result.stdout.strip())
except Exception as e:
    print('❌ Error getting subscription:', e)
"

echo.
echo 7. Running analyzer with verbose output...
echo.
python scripts/azure_to_aws_cost_analyzer.py --macc-discount 0

echo.
echo Debug complete!
pause