#!/usr/bin/env python3
"""
Basic structure validation test for azure_resource_discovery.py
This test validates the script structure without requiring Azure credentials.
"""

import ast
import sys
import os


def test_script_structure():
    """Test that the script has the required structure."""
    print("Testing script structure...")
    
    script_path = os.path.join(os.path.dirname(__file__), 'azure_resource_discovery.py')
    
    with open(script_path, 'r') as f:
        content = f.read()
    
    # Parse the Python AST
    try:
        tree = ast.parse(content)
        print("✓ Script has valid Python syntax")
    except SyntaxError as e:
        print(f"✗ Syntax error: {e}")
        return False
    
    # Check for required classes
    classes = [node.name for node in ast.walk(tree) if isinstance(node, ast.ClassDef)]
    if 'AzureResourceDiscovery' not in classes:
        print("✗ Missing AzureResourceDiscovery class")
        return False
    print("✓ AzureResourceDiscovery class found")
    
    # Check for required methods
    required_methods = [
        'collect_consumption_data',
        'collect_inventory_data',
        'collect_metrics_data',
        'create_excel_report',
        'create_zip_archive',
        'generate_reports'
    ]
    
    class_node = None
    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef) and node.name == 'AzureResourceDiscovery':
            class_node = node
            break
    
    if class_node:
        methods = [n.name for n in class_node.body if isinstance(n, ast.FunctionDef)]
        for required_method in required_methods:
            if required_method in methods:
                print(f"✓ Method '{required_method}' found")
            else:
                print(f"✗ Missing method '{required_method}'")
                return False
    
    # Check for main function
    functions = [node.name for node in ast.walk(tree) if isinstance(node, ast.FunctionDef)]
    if 'main' not in functions:
        print("✗ Missing main function")
        return False
    print("✓ main() function found")
    
    # Check for proper imports (in the try block)
    imports_found = False
    for node in ast.walk(tree):
        if isinstance(node, ast.Try):
            for handler in node.handlers:
                if any(isinstance(n, ast.ImportFrom) for n in node.body):
                    imports_found = True
                    break
    
    if imports_found or any(isinstance(node, ast.ImportFrom) for node in ast.walk(tree)):
        print("✓ Import statements found")
    
    # Check for argparse usage
    argparse_used = 'argparse' in content
    if argparse_used:
        print("✓ argparse module used for CLI arguments")
    else:
        print("✗ argparse not found")
        return False
    
    # Check for output file patterns
    required_patterns = [
        'Consumption_ResourcesReport_',
        'Inventory_ResourcesReport_',
        'Metrics_ResourcesReport_',
        'ResourcesReport_'
    ]
    
    for pattern in required_patterns:
        if pattern in content:
            print(f"✓ Output file pattern '{pattern}' found")
        else:
            print(f"✗ Missing output file pattern '{pattern}'")
            return False
    
    print("\n✓ All structure tests passed!")
    return True


def test_requirements():
    """Test that requirements.txt has the necessary dependencies."""
    print("\nTesting requirements.txt...")
    
    req_path = os.path.join(os.path.dirname(__file__), 'requirements.txt')
    
    with open(req_path, 'r') as f:
        requirements = f.read()
    
    required_packages = [
        'azure-identity',
        'azure-mgmt-resource',
        'azure-mgmt-costmanagement',
        'azure-mgmt-monitor',
        'openpyxl',
        'pandas'
    ]
    
    for package in required_packages:
        if package in requirements:
            print(f"✓ Package '{package}' found in requirements.txt")
        else:
            print(f"✗ Missing package '{package}' in requirements.txt")
            return False
    
    print("\n✓ All requirements tests passed!")
    return True


def test_readme():
    """Test that README has been updated."""
    print("\nTesting README.md...")
    
    readme_path = os.path.join(os.path.dirname(__file__), 'README.md')
    
    with open(readme_path, 'r') as f:
        readme = f.read()
    
    if len(readme) < 100:
        print("✗ README appears to be too short")
        return False
    
    required_sections = [
        'Installation',
        'Usage',
        'Authentication',
        'Prerequisites'
    ]
    
    for section in required_sections:
        if section.lower() in readme.lower():
            print(f"✓ Section '{section}' found in README")
        else:
            print(f"⚠ Section '{section}' not found in README (optional)")
    
    # Check for file descriptions
    file_descriptions = [
        'Consumption_ResourcesReport_',
        'Inventory_ResourcesReport_',
        'Metrics_ResourcesReport_',
        'ResourcesReport_'
    ]
    
    for file_desc in file_descriptions:
        if file_desc in readme:
            print(f"✓ File description for '{file_desc}' found")
    
    print("\n✓ README validation passed!")
    return True


if __name__ == '__main__':
    print("="*60)
    print("Azure Resource Discovery - Structure Validation")
    print("="*60)
    print()
    
    all_passed = True
    
    all_passed = test_script_structure() and all_passed
    all_passed = test_requirements() and all_passed
    all_passed = test_readme() and all_passed
    
    print("\n" + "="*60)
    if all_passed:
        print("✓ ALL TESTS PASSED")
        print("="*60)
        sys.exit(0)
    else:
        print("✗ SOME TESTS FAILED")
        print("="*60)
        sys.exit(1)
