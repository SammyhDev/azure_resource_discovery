#!/bin/bash

# First Time Setup Guide
# Run this after cloning the repository to see your options

clear
echo "🚀 Azure Resource Discovery - First Time Setup"
echo "=============================================="
echo
echo "Welcome! You've successfully cloned the repository."
echo "Now choose how you'd like to use the Azure Resource Discovery tool:"
echo
echo "📋 OPTION 1: Command Line Analysis (Individual Use)"
echo "   ✅ Quick and simple"
echo "   ✅ Runs on your local machine"
echo "   ✅ Perfect for personal use"
echo "   ✅ Zero cost (uses your compute)"
echo
echo "   To start: ./analyze.sh (Linux/macOS) or analyze.bat (Windows)"
echo
echo "📋 OPTION 2: Web Application (Team/Enterprise Use)"
echo "   ✅ Professional web interface"
echo "   ✅ Team collaboration features"
echo "   ✅ Real-time progress tracking"
echo "   ✅ Accessible from anywhere"
echo "   ✅ Enterprise security (managed identity)"
echo "   💰 Cost: ~$13/month (Azure App Service Basic)"
echo
echo "   To deploy: cd webapp/deploy && ./deploy.sh"
echo
echo "📋 WHAT BOTH OPTIONS PROVIDE:"
echo "   • Discover all Azure resources in your subscription"
echo "   • Get AWS cost estimates for equivalent services"
echo "   • Apply MACC enterprise discounts"
echo "   • Generate detailed cost comparison reports"
echo "   • Identify potential cloud cost savings"
echo
echo "🎯 RECOMMENDATION:"
echo "   • Individual use → Command Line (Option 1)"
echo "   • Team/Enterprise → Web Application (Option 2)"
echo
echo "📚 GETTING HELP:"
echo "   • Quick Start Guide: docs/QUICK_START.md"
echo "   • Web App Guide: docs/WEB_APP_DEPLOYMENT.md"
echo "   • Windows Help: docs/WINDOWS_SETUP.md"
echo "   • Troubleshooting: troubleshoot-windows.bat (Windows only)"
echo
echo "⚡ QUICK START COMMANDS:"
echo
echo "   # Command Line Version:"
echo "   ./analyze.sh"
echo
echo "   # Web Application Version:"
echo "   cd webapp/deploy && ./deploy.sh"
echo
echo "🎉 Ready to analyze your Azure costs and find AWS savings!"
echo "   Choose your option above and get started!"
echo