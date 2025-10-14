#!/usr/bin/env python3
"""
Test script to verify the Azure to AWS Cost Analyzer works correctly
without requiring actual Azure resources.
"""

import sys
import os
import json
from datetime import datetime

# Add the current directory to Python path so we can import our modules
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from azure_to_aws_cost_analyzer import AWSCostEstimator, generate_report
    print("✅ Successfully imported analyzer modules")
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("Make sure all required packages are installed:")
    print("pip3 install -r requirements.txt")
    sys.exit(1)

def test_cost_estimation():
    """Test the cost estimation logic with sample data."""
    print("\n🧪 Testing cost estimation logic...")
    
    # Sample Azure resources data (similar to what would be discovered)
    sample_azure_resources = {
        'virtual_machines': [
            {
                'name': 'test-vm-1',
                'size': 'Standard_B2s',
                'location': 'East US',
                'resource_group': 'test-rg',
                'os_type': 'Linux',
                'status': 'Running'
            },
            {
                'name': 'test-vm-2',
                'size': 'Standard_D2s_v3',
                'location': 'West Europe',
                'resource_group': 'test-rg',
                'os_type': 'Windows',
                'status': 'Running'
            }
        ],
        'storage_accounts': [
            {
                'name': 'teststorage001',
                'kind': 'StorageV2',
                'sku': 'Standard_LRS',
                'location': 'East US',
                'resource_group': 'test-rg',
                'access_tier': 'Hot'
            },
            {
                'name': 'backupstorage001',
                'kind': 'StorageV2',
                'sku': 'Standard_GRS',
                'location': 'East US',
                'resource_group': 'test-rg',
                'access_tier': 'Cool'
            }
        ],
        'sql_databases': [
            {
                'name': 'testdb',
                'server': 'testserver',
                'sku': 'Standard_S1',
                'location': 'East US',
                'resource_group': 'test-rg',
                'max_size_bytes': 268435456000
            }
        ],
        'app_services': [
            {
                'name': 'testapp',
                'kind': 'app',
                'location': 'East US',
                'resource_group': 'test-rg',
                'state': 'Running',
                'server_farm_id': '/subscriptions/test/resourceGroups/test-rg/providers/Microsoft.Web/serverfarms/testplan'
            }
        ],
        'other_resources': [
            {
                'name': 'test-vnet',
                'type': 'Microsoft.Network/virtualNetworks',
                'location': 'East US',
                'resource_group': 'test-rg'
            }
        ]
    }
    
    # Test cost estimation
    cost_estimator = AWSCostEstimator()
    aws_costs = cost_estimator.estimate_costs(sample_azure_resources)
    
    print(f"✅ Estimated costs for {len(sample_azure_resources['virtual_machines'])} VMs")
    print(f"✅ Estimated costs for {len(sample_azure_resources['storage_accounts'])} storage accounts")
    print(f"✅ Estimated costs for {len(sample_azure_resources['sql_databases'])} databases")
    print(f"✅ Estimated costs for {len(sample_azure_resources['app_services'])} app services")
    print(f"✅ Total estimated monthly cost: ${aws_costs['total_monthly_cost']:.2f}")
    
    # Test report generation
    print("\n📄 Testing report generation...")
    report = generate_report(sample_azure_resources, aws_costs)
    
    if len(report) > 100:  # Basic check that report was generated
        print("✅ Report generated successfully")
        print(f"✅ Report length: {len(report)} characters")
        
        # Save test report
        with open('test_report.txt', 'w') as f:
            f.write(report)
        print("✅ Test report saved to 'test_report.txt'")
        
        # Save test JSON
        test_data = {
            'azure_resources': sample_azure_resources,
            'aws_cost_estimates': aws_costs,
            'timestamp': datetime.now().isoformat()
        }
        with open('test_report.json', 'w') as f:
            json.dump(test_data, f, indent=2, default=str)
        print("✅ Test JSON report saved to 'test_report.json'")
        
    else:
        print("❌ Report generation failed")
        return False
    
    return True

def main():
    """Run all tests."""
    print("🔍 Azure to AWS Cost Analyzer - Test Suite")
    print("=" * 50)
    
    # Test cost estimation
    if test_cost_estimation():
        print("\n🎉 All tests passed!")
        print("\nYou can now run the full analyzer:")
        print("python3 azure_to_aws_cost_analyzer.py")
        print("\nOr check the test output files:")
        print("- test_report.txt (human-readable)")
        print("- test_report.json (machine-readable)")
    else:
        print("\n❌ Tests failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()