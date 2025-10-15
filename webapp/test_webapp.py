#!/usr/bin/env python3
"""
Test script for the Azure Resource Discovery Web App
Run this to test the web app locally before deployment
"""

import sys
import os
import subprocess

def test_imports():
    """Test if all required packages can be imported"""
    print("🔷 Testing Python package imports...")
    
    try:
        from flask import Flask
        print("✅ Flask imported successfully")
        
        from azure.identity import DefaultAzureCredential
        print("✅ Azure Identity imported successfully")
        
        from azure.mgmt.resource import ResourceManagementClient
        print("✅ Azure Resource Management imported successfully")
        
        import requests
        print("✅ Requests imported successfully")
        
        return True
    except ImportError as e:
        print(f"❌ Import error: {e}")
        return False

def test_azure_connection():
    """Test Azure CLI connection"""
    print("\n🔷 Testing Azure CLI connection...")
    
    try:
        # Test if Azure CLI is logged in
        result = subprocess.run(['az', 'account', 'show'], 
                              capture_output=True, text=True, check=True)
        print("✅ Azure CLI is logged in")
        
        # Get subscription info
        import json
        account_info = json.loads(result.stdout)
        print(f"   Subscription: {account_info.get('name', 'Unknown')}")
        print(f"   User: {account_info.get('user', {}).get('name', 'Unknown')}")
        
        return True
    except subprocess.CalledProcessError:
        print("❌ Azure CLI not logged in or not available")
        print("   Please run: az login")
        return False
    except FileNotFoundError:
        print("❌ Azure CLI not found")
        print("   Please install Azure CLI")
        return False

def test_web_app():
    """Test basic web app functionality"""
    print("\n🔷 Testing web app initialization...")
    
    try:
        # Add webapp directory to path
        webapp_dir = os.path.join(os.path.dirname(__file__))
        sys.path.insert(0, webapp_dir)
        
        # Import the web app
        from app import app, WebAnalyzer
        print("✅ Web app imported successfully")
        
        # Test analyzer initialization
        analyzer = WebAnalyzer()
        print("✅ Web analyzer initialized")
        
        # Test Flask app
        with app.test_client() as client:
            response = client.get('/')
            if response.status_code == 200:
                print("✅ Home page renders successfully")
            else:
                print(f"❌ Home page failed: {response.status_code}")
                return False
            
            # Test health endpoint
            response = client.get('/health')
            if response.status_code == 200:
                print("✅ Health check endpoint working")
            else:
                print(f"❌ Health check failed: {response.status_code}")
                return False
        
        return True
    except Exception as e:
        print(f"❌ Web app test failed: {e}")
        return False

def main():
    """Run all tests"""
    print("🚀 Azure Resource Discovery Web App - Test Suite")
    print("=" * 50)
    
    all_passed = True
    
    # Test 1: Package imports
    if not test_imports():
        all_passed = False
        print("\n💡 To fix: pip install -r requirements.txt")
    
    # Test 2: Azure connection
    if not test_azure_connection():
        all_passed = False
        print("\n💡 To fix: az login")
    
    # Test 3: Web app functionality
    if not test_web_app():
        all_passed = False
    
    print("\n" + "=" * 50)
    if all_passed:
        print("🎉 All tests passed! Web app is ready for deployment.")
        print("\n🚀 Next steps:")
        print("   1. Run locally: python app.py")
        print("   2. Deploy to Azure: ./deploy/deploy.sh")
        print("   3. Access web interface and start analyzing!")
    else:
        print("❌ Some tests failed. Please fix the issues above.")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())