@echo off
setlocal enabledelayedexpansion

echo.
echo 🔍 Azure Login Debug Script
echo ===========================
echo.

echo Testing Azure CLI installation...
where az >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Azure CLI not found!
    exit /b 1
) else (
    echo ✅ Azure CLI found!
)

echo.
echo Testing Azure login status...
az account show >nul 2>nul
set "login_result=%ERRORLEVEL%"
echo Login test result: !login_result!

if !login_result! NEQ 0 (
    echo ❌ Not logged in - would prompt for login
) else (
    echo ✅ Already logged in!
    echo.
    echo Current account details:
    az account show --query "{name:name, user:user.name, id:id}" -o table
)

echo.
echo Debug complete!
pause