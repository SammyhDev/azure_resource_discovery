# Windows Setup Guide

This guide helps Windows users run the Azure Resource Discovery analyzer without issues.

## 🚨 Common Issue: PowerShell Execution Policy Error

If you see this error:
```
copilot-debug : File c:\Users\...\copilot-debug.ps1 cannot be loaded. 
The file is not digitally signed. You cannot run this script on the current system.
```

**This happens because:**
- You're trying to run a bash script (`.sh`) on Windows
- PowerShell has security restrictions on unsigned scripts

## ✅ **Solution: Use Windows-Compatible Scripts**

### Option 1: Command Prompt (Easiest)
```cmd
# Open Command Prompt (cmd) and run:
analyze.bat
```

### Option 2: PowerShell (Recommended)
```powershell
# Open PowerShell and run:
.\analyze.ps1
```

### Option 3: Fix PowerShell Execution Policy
If you prefer PowerShell but get execution policy errors:

```powershell
# Run this command once to allow local scripts:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then run the analyzer:
.\analyze.ps1
```

## 🛠️ **Prerequisites for Windows**

### 1. Install Azure CLI
- **Download**: https://aka.ms/installazurecliwindows
- **Install**: Run the MSI installer
- **Verify**: Open Command Prompt and run `az --version`

### 2. Install Python
- **Download**: https://python.org/downloads
- **Install**: Make sure to check "Add Python to PATH"
- **Verify**: Open Command Prompt and run `python --version`

### 3. Clone or Download the Repository
```cmd
# Using git:
git clone https://github.com/SammyhDev/azure_resource_discovery.git
cd azure_resource_discovery

# Or download ZIP from GitHub and extract
```

## 🚀 **Running the Analyzer**

### Command Prompt Method:
```cmd
cd azure_resource_discovery
analyze.bat
```

### PowerShell Method:
```powershell
cd azure_resource_discovery
.\analyze.ps1
```

### Advanced Python Method:
```cmd
# Direct Python execution:
python scripts/azure_to_aws_cost_analyzer.py

# With MACC discount:
python scripts/azure_to_aws_cost_analyzer.py --macc-discount 15
```

## 🎯 **What Each Script Does**

| Script | Platform | Description |
|--------|----------|-------------|
| `analyze.sh` | Linux/macOS/WSL | Bash script for Unix systems |
| `analyze.bat` | Windows | Command Prompt batch file |  
| `analyze.ps1` | Windows | PowerShell script |
| `azure_to_aws_cost_analyzer.py` | All | Direct Python execution |

## 💡 **Pro Tips for Windows Users**

1. **Use Windows Terminal**: Better experience than old Command Prompt
2. **Install WSL**: Run Linux scripts natively on Windows
3. **Use VS Code**: Great editor with integrated terminal
4. **PowerShell Core**: More features than Windows PowerShell

## 🔧 **Troubleshooting**

### "Failed to install Python dependencies"
If the main scripts fail to install dependencies, use the dedicated setup tools:

```cmd
# Command Prompt version:
setup-dependencies.bat

# PowerShell version:
.\setup-dependencies.ps1
```

These tools will:
- ✅ Check all prerequisites
- ✅ Install packages individually with detailed output
- ✅ Test each import to verify installation
- ✅ Provide specific error messages

### "Azure CLI not found"
- Reinstall Azure CLI with admin privileges
- Restart your terminal after installation
- Check PATH environment variable

### "Python not found" 
- Reinstall Python with "Add to PATH" checked
- Use `py` instead of `python` command
- Restart terminal after installation

### "Permission denied"
- Run terminal as Administrator
- Check Windows execution policies
- Use Command Prompt instead of PowerShell

### "Import errors" 
- Run the dependency setup tools above
- Try installing with `--user` flag: `pip install azure-identity --user`
- Update pip: `python -m pip install --upgrade pip`

This ensures Windows users can run the analyzer without any issues! 🚀