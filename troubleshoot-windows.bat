@echo off
setlocal enabledelayedexpansion
REM Comprehensive Windows Troubleshooting Script for Azure Resource Discovery

echo.
echo 🔧 Azure Resource Discovery - Windows Troubleshooting
echo ====================================================
echo.
echo This script will diagnose and fix common Windows installation issues.
echo.

REM Create a log file
set LOGFILE=%TEMP%\azure_discovery_troubleshooting.log
echo Starting troubleshooting at %DATE% %TIME% > %LOGFILE%

REM Check Python installation
echo 🔷 Step 1: Checking Python installation...
python --version >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Python not found in PATH
    echo Checking for Python launcher...
    py --version >nul 2>nul
    if !ERRORLEVEL! EQU 0 (
        echo ✅ Python launcher found, using 'py' instead of 'python'
        set PYTHON_CMD=py
        echo Python found with launcher: >> %LOGFILE%
        py --version >> %LOGFILE% 2>&1
    ) else (
        echo ❌ No Python installation found
        echo Please install Python from https://python.org/downloads
        echo Make sure to check "Add Python to PATH" during installation
        pause
        exit /b 1
    )
) else (
    set PYTHON_CMD=python
    echo ✅ Python found
    echo Python version: >> %LOGFILE%
    python --version >> %LOGFILE% 2>&1
)

REM Check pip
echo.
echo 🔷 Step 2: Checking pip...
%PYTHON_CMD% -m pip --version >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ pip not working, trying to install/repair...
    %PYTHON_CMD% -m ensurepip --upgrade
    %PYTHON_CMD% -m pip --version >nul 2>nul
    if !ERRORLEVEL! NEQ 0 (
        echo ❌ Could not get pip working
        pause
        exit /b 1
    )
)
echo ✅ pip is working
echo pip version: >> %LOGFILE%
%PYTHON_CMD% -m pip --version >> %LOGFILE% 2>&1

REM Check Azure CLI
echo.
echo 🔷 Step 3: Checking Azure CLI...
az --version >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Azure CLI not found
    echo Please install from: https://aka.ms/installazurecliwindows
    echo After installation, restart your command prompt and run this script again
    pause
    exit /b 1
)
echo ✅ Azure CLI found
echo Azure CLI version: >> %LOGFILE%
az --version | findstr "azure-cli" >> %LOGFILE% 2>&1

REM Check internet connectivity
echo.
echo 🔷 Step 4: Checking internet connectivity...
ping -n 1 pypi.org >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ⚠️  Cannot reach pypi.org - you may have internet connectivity issues
    echo Internet connectivity issue noted >> %LOGFILE%
) else (
    echo ✅ Internet connectivity OK
)

REM Clear any pip cache issues
echo.
echo 🔷 Step 5: Clearing pip cache...
%PYTHON_CMD% -m pip cache purge >nul 2>nul
echo Pip cache cleared

REM Install/upgrade pip tools
echo.
echo 🔷 Step 6: Upgrading pip and setuptools...
echo Upgrading pip...
%PYTHON_CMD% -m pip install --upgrade pip --user --no-warn-script-location
echo Upgrading setuptools...
%PYTHON_CMD% -m pip install --upgrade setuptools --user --no-warn-script-location
echo Upgrading wheel...
%PYTHON_CMD% -m pip install --upgrade wheel --user --no-warn-script-location

REM Try installing packages with different methods
echo.
echo 🔷 Step 7: Installing Azure packages...
echo This may take several minutes...

REM List of packages to install
set PACKAGES=azure-identity azure-mgmt-resource azure-mgmt-compute azure-mgmt-storage azure-mgmt-sql azure-mgmt-web requests

echo Method 1: Installing all packages at once...
%PYTHON_CMD% -m pip install %PACKAGES% --user --upgrade --no-warn-script-location
if %ERRORLEVEL% EQU 0 (
    echo ✅ Bulk installation successful
    goto :test_imports
)

echo Method 1 failed, trying individual installation...
for %%p in (%PACKAGES%) do (
    echo Installing %%p...
    %PYTHON_CMD% -m pip install %%p --user --upgrade --no-warn-script-location
    if !ERRORLEVEL! NEQ 0 (
        echo ⚠️  %%p failed, trying without upgrade flag...
        %PYTHON_CMD% -m pip install %%p --user --no-warn-script-location
        if !ERRORLEVEL! NEQ 0 (
            echo ❌ %%p failed completely, trying with --force-reinstall...
            %PYTHON_CMD% -m pip install %%p --user --force-reinstall --no-warn-script-location
        )
    )
)

:test_imports
echo.
echo 🔷 Step 8: Testing package imports...
echo Testing azure-identity...
%PYTHON_CMD% -c "import azure.identity; print('✅ azure-identity works')" 2>nul || echo "❌ azure-identity failed"

echo Testing azure-mgmt-resource...
%PYTHON_CMD% -c "import azure.mgmt.resource; print('✅ azure-mgmt-resource works')" 2>nul || echo "❌ azure-mgmt-resource failed"

echo Testing requests...
%PYTHON_CMD% -c "import requests; print('✅ requests works')" 2>nul || echo "❌ requests failed"

echo Testing all imports together...
%PYTHON_CMD% -c "import azure.identity, azure.mgmt.resource, azure.mgmt.compute, azure.mgmt.storage, azure.mgmt.sql, azure.mgmt.web, requests; print('✅ All packages imported successfully')" 2>nul || (
    echo ❌ Some packages still not working
    echo Trying one more comprehensive fix...
    %PYTHON_CMD% -m pip install --upgrade --force-reinstall %PACKAGES% --user --no-warn-script-location
)

REM Final test
echo.
echo 🔷 Step 9: Final verification...
%PYTHON_CMD% scripts/azure_to_aws_cost_analyzer.py --help >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo.
    echo 🎉 SUCCESS! The analyzer should now work.
    echo You can run: analyze.bat or analyze-simple.bat
    echo.
) else (
    echo.
    echo ❌ The analyzer still has issues.
    echo Check the log file: %LOGFILE%
    echo.
    echo Manual steps you can try:
    echo 1. Run Command Prompt as Administrator
    echo 2. Try: %PYTHON_CMD% -m pip install --upgrade --force-reinstall azure-identity azure-mgmt-resource requests --user
    echo 3. Restart your computer and try again
    echo 4. Contact support with the log file
    echo.
)

echo.
echo 📋 Log file saved to: %LOGFILE%
echo You can review this file to see what happened during troubleshooting.
echo.
pause