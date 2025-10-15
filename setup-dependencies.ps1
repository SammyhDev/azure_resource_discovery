# Dependency Checker and Installer for Azure Resource Discovery
# Run this if you have issues with the main analyzer

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "🔧 Azure Resource Discovery - Dependency Checker" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Function to print colored messages
function Write-Step {
    param($Message)
    Write-Host "🔷 $Message" -ForegroundColor Magenta
}

function Write-Success {
    param($Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param($Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Check Python
Write-Step "Checking Python..."
try {
    $pythonVersion = python --version 2>&1
    Write-Host $pythonVersion -ForegroundColor White
    Write-Success "Python is installed"
}
catch {
    Write-Error "Python not found"
    Write-Host "Download from: https://python.org/downloads" -ForegroundColor Yellow
    exit 1
}

# Check pip
Write-Host ""
Write-Step "Checking pip..."
try {
    $pipVersion = pip --version 2>&1
    Write-Host $pipVersion -ForegroundColor White
    Write-Success "pip is available"
}
catch {
    Write-Error "pip not found"
    Write-Host "Try: python -m ensurepip --upgrade" -ForegroundColor Yellow
    exit 1
}

# Check Azure CLI
Write-Host ""
Write-Step "Checking Azure CLI..."
try {
    $azVersion = az --version 2>&1 | Select-String "azure-cli"
    Write-Host $azVersion -ForegroundColor White
    Write-Success "Azure CLI is installed"
}
catch {
    Write-Error "Azure CLI not found"
    Write-Host "Download from: https://aka.ms/installazurecliwindows" -ForegroundColor Yellow
    exit 1
}

# Install Python packages
Write-Host ""
Write-Step "Installing Python packages..."

$packages = @(
    "azure-identity",
    "azure-mgmt-resource",
    "azure-mgmt-compute",
    "azure-mgmt-storage", 
    "azure-mgmt-sql",
    "azure-mgmt-web",
    "requests"
)

foreach ($package in $packages) {
    Write-Host ""
    Write-Host "Installing: $package" -ForegroundColor Yellow
    try {
        pip install $package --user --upgrade 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "$package installed"
        } else {
            Write-Error "$package failed to install"
        }
    }
    catch {
        Write-Error "$package installation failed: $_"
    }
}

# Test imports
Write-Host ""
Write-Step "Testing imports..."

$imports = @{
    "azure.identity" = "azure-identity"
    "azure.mgmt.resource" = "azure-mgmt-resource"
    "azure.mgmt.compute" = "azure-mgmt-compute"
    "azure.mgmt.storage" = "azure-mgmt-storage"
    "azure.mgmt.sql" = "azure-mgmt-sql"
    "azure.mgmt.web" = "azure-mgmt-web"
    "requests" = "requests"
}

foreach ($import in $imports.GetEnumerator()) {
    try {
        $result = python -c "import $($import.Key); print('works')" 2>&1
        if ($result -eq "works") {
            Write-Success "$($import.Value) works"
        } else {
            Write-Error "$($import.Value) failed"
        }
    }
    catch {
        Write-Error "$($import.Value) failed to import"
    }
}

Write-Host ""
Write-Host "🎯 Dependency check complete!" -ForegroundColor Cyan
Write-Host ""
Write-Host "If all packages show ✅, you can now run:" -ForegroundColor Green
Write-Host "  analyze.bat   (for Command Prompt)" -ForegroundColor White
Write-Host "  analyze.ps1   (for PowerShell)" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to exit"