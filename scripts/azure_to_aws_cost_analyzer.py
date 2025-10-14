#!/usr/bin/env python3
"""
Azure Resource Discovery and AWS Cost Estimation Script

This script discovers Azure resources in your subscription and provides
rough AWS cost estimates for equivalent services.

Requirements:
- Azure CLI installed and logged in (az login)
- Python packages: azure-identity, azure-mgmt-resource, azure-mgmt-compute, 
  azure-mgmt-storage, azure-mgmt-sql, azure-mgmt-web, requests

Usage:
    python azure_to_aws_cost_analyzer.py [--subscription-id SUBSCRIPTION_ID]
"""

import json
import sys
import argparse
import logging
from datetime import datetime
from typing import Dict, List, Any, Optional
import subprocess

try:
    from azure.identity import DefaultAzureCredential, AzureCliCredential
    from azure.mgmt.resource import ResourceManagementClient
    from azure.mgmt.compute import ComputeManagementClient
    from azure.mgmt.storage import StorageManagementClient
    from azure.mgmt.sql import SqlManagementClient
    from azure.mgmt.web import WebSiteManagementClient
    import requests
except ImportError as e:
    print(f"Missing required package: {e}")
    print("Please install required packages:")
    print("pip install azure-identity azure-mgmt-resource azure-mgmt-compute azure-mgmt-storage azure-mgmt-sql azure-mgmt-web requests")
    sys.exit(1)

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class AzureResourceDiscovery:
    def __init__(self, subscription_id: Optional[str] = None):
        """Initialize Azure clients."""
        self.subscription_id = subscription_id or self._get_default_subscription()
        
        # Try CLI credential first, then default
        try:
            self.credential = AzureCliCredential()
        except Exception:
            self.credential = DefaultAzureCredential()
        
        self.resource_client = ResourceManagementClient(self.credential, self.subscription_id)
        self.compute_client = ComputeManagementClient(self.credential, self.subscription_id)
        self.storage_client = StorageManagementClient(self.credential, self.subscription_id)
        self.sql_client = SqlManagementClient(self.credential, self.subscription_id)
        self.web_client = WebSiteManagementClient(self.credential, self.subscription_id)
        
        logger.info(f"Initialized Azure clients for subscription: {self.subscription_id}")

    def _get_default_subscription(self) -> str:
        """Get the default subscription ID from Azure CLI."""
        try:
            result = subprocess.run(['az', 'account', 'show', '--query', 'id', '-o', 'tsv'], 
                                  capture_output=True, text=True, check=True)
            return result.stdout.strip()
        except subprocess.CalledProcessError:
            logger.error("Unable to get default subscription.")
            logger.error("Please login to Azure CLI first:")
            logger.error("")
            logger.error("Quick login:")
            logger.error("  az login")
            logger.error("")
            logger.error("For detailed login help:")
            logger.error("  ./azure_login_helper.sh")
            logger.error("")
            logger.error("Or use the guided script:")
            logger.error("  ./run_analyzer.sh")
            sys.exit(1)

    def discover_resources(self) -> Dict[str, List[Dict[str, Any]]]:
        """Discover all resources in the Azure subscription."""
        logger.info("Discovering Azure resources...")
        
        resources = {
            'virtual_machines': [],
            'storage_accounts': [],
            'sql_databases': [],
            'app_services': [],
            'other_resources': []
        }
        
        try:
            # Get all resources
            all_resources = list(self.resource_client.resources.list())
            logger.info(f"Found {len(all_resources)} total resources")
            
            for resource in all_resources:
                resource_type = resource.type.lower()
                
                if 'microsoft.compute/virtualmachines' in resource_type:
                    vm_details = self._get_vm_details(resource)
                    if vm_details:
                        resources['virtual_machines'].append(vm_details)
                
                elif 'microsoft.storage/storageaccounts' in resource_type:
                    storage_details = self._get_storage_details(resource)
                    if storage_details:
                        resources['storage_accounts'].append(storage_details)
                
                elif 'microsoft.sql/servers/databases' in resource_type:
                    db_details = self._get_sql_database_details(resource)
                    if db_details:
                        resources['sql_databases'].append(db_details)
                
                elif 'microsoft.web/sites' in resource_type:
                    app_details = self._get_app_service_details(resource)
                    if app_details:
                        resources['app_services'].append(app_details)
                
                else:
                    resources['other_resources'].append({
                        'name': resource.name,
                        'type': resource.type,
                        'location': resource.location,
                        'resource_group': resource.id.split('/')[4] if len(resource.id.split('/')) > 4 else 'Unknown'
                    })
            
            return resources
            
        except Exception as e:
            logger.error(f"Error discovering resources: {e}")
            return resources

    def _get_vm_details(self, resource) -> Optional[Dict[str, Any]]:
        """Get detailed VM information."""
        try:
            resource_group = resource.id.split('/')[4]
            vm = self.compute_client.virtual_machines.get(resource_group, resource.name)
            
            return {
                'name': vm.name,
                'size': vm.hardware_profile.vm_size,
                'location': vm.location,
                'resource_group': resource_group,
                'os_type': 'Windows' if vm.storage_profile.os_disk.os_type.name == 'Windows' else 'Linux',
                'status': 'Running'  # Simplified for this example
            }
        except Exception as e:
            logger.warning(f"Could not get VM details for {resource.name}: {e}")
            return None

    def _get_storage_details(self, resource) -> Optional[Dict[str, Any]]:
        """Get detailed storage account information."""
        try:
            resource_group = resource.id.split('/')[4]
            storage = self.storage_client.storage_accounts.get_properties(resource_group, resource.name)
            
            return {
                'name': storage.name,
                'kind': storage.kind,
                'sku': storage.sku.name,
                'location': storage.location,
                'resource_group': resource_group,
                'access_tier': getattr(storage, 'access_tier', 'Hot')
            }
        except Exception as e:
            logger.warning(f"Could not get storage details for {resource.name}: {e}")
            return None

    def _get_sql_database_details(self, resource) -> Optional[Dict[str, Any]]:
        """Get detailed SQL database information."""
        try:
            parts = resource.id.split('/')
            resource_group = parts[4]
            server_name = parts[8]
            db_name = parts[10]
            
            database = self.sql_client.databases.get(resource_group, server_name, db_name)
            
            return {
                'name': database.name,
                'server': server_name,
                'sku': database.sku.name if database.sku else 'Unknown',
                'location': database.location,
                'resource_group': resource_group,
                'max_size_bytes': database.max_size_bytes
            }
        except Exception as e:
            logger.warning(f"Could not get SQL database details for {resource.name}: {e}")
            return None

    def _get_app_service_details(self, resource) -> Optional[Dict[str, Any]]:
        """Get detailed App Service information."""
        try:
            resource_group = resource.id.split('/')[4]
            app = self.web_client.web_apps.get(resource_group, resource.name)
            
            return {
                'name': app.name,
                'kind': app.kind,
                'location': app.location,
                'resource_group': resource_group,
                'state': app.state,
                'server_farm_id': app.server_farm_id
            }
        except Exception as e:
            logger.warning(f"Could not get App Service details for {resource.name}: {e}")
            return None

class AWSCostEstimator:
    """Estimate AWS costs for Azure resources."""
    
    # Simplified pricing data (USD per month) - these are rough estimates
    # In production, you'd want to use AWS Pricing API or more detailed pricing
    AWS_PRICING = {
        'ec2': {
            'Standard_B1s': {'type': 't3.nano', 'monthly_cost': 3.8},
            'Standard_B1ms': {'type': 't3.micro', 'monthly_cost': 7.6},
            'Standard_B2s': {'type': 't3.small', 'monthly_cost': 15.2},
            'Standard_B2ms': {'type': 't3.medium', 'monthly_cost': 30.4},
            'Standard_B4ms': {'type': 't3.large', 'monthly_cost': 60.8},
            'Standard_D2s_v3': {'type': 'm5.large', 'monthly_cost': 70.1},
            'Standard_D4s_v3': {'type': 'm5.xlarge', 'monthly_cost': 140.2},
            'Standard_D8s_v3': {'type': 'm5.2xlarge', 'monthly_cost': 280.3},
            'default': {'type': 't3.medium', 'monthly_cost': 30.4}
        },
        's3': {
            'standard': 0.023,  # per GB/month
            'infrequent_access': 0.0125,
            'cold': 0.004
        },
        'rds': {
            'Basic': {'type': 'db.t3.micro', 'monthly_cost': 12.8},
            'Standard_S0': {'type': 'db.t3.small', 'monthly_cost': 25.6},
            'Standard_S1': {'type': 'db.t3.medium', 'monthly_cost': 51.2},
            'Standard_S2': {'type': 'db.m5.large', 'monthly_cost': 125.0},
            'default': {'type': 'db.t3.micro', 'monthly_cost': 12.8}
        },
        'lambda': {
            'consumption': 0.0000002,  # per request + GB-second
        }
    }

    def estimate_costs(self, azure_resources: Dict[str, List[Dict[str, Any]]]) -> Dict[str, Any]:
        """Estimate AWS costs for discovered Azure resources."""
        logger.info("Estimating AWS costs...")
        
        cost_breakdown = {
            'ec2_instances': [],
            's3_storage': [],
            'rds_databases': [],
            'lambda_functions': [],
            'total_monthly_cost': 0
        }
        
        # Estimate VM costs as EC2
        for vm in azure_resources['virtual_machines']:
            ec2_cost = self._estimate_ec2_cost(vm)
            cost_breakdown['ec2_instances'].append(ec2_cost)
            cost_breakdown['total_monthly_cost'] += ec2_cost['monthly_cost']
        
        # Estimate Storage costs as S3
        for storage in azure_resources['storage_accounts']:
            s3_cost = self._estimate_s3_cost(storage)
            cost_breakdown['s3_storage'].append(s3_cost)
            cost_breakdown['total_monthly_cost'] += s3_cost['monthly_cost']
        
        # Estimate SQL Database costs as RDS
        for db in azure_resources['sql_databases']:
            rds_cost = self._estimate_rds_cost(db)
            cost_breakdown['rds_databases'].append(rds_cost)
            cost_breakdown['total_monthly_cost'] += rds_cost['monthly_cost']
        
        # Estimate App Services as Lambda (simplified)
        for app in azure_resources['app_services']:
            lambda_cost = self._estimate_lambda_cost(app)
            cost_breakdown['lambda_functions'].append(lambda_cost)
            cost_breakdown['total_monthly_cost'] += lambda_cost['monthly_cost']
        
        return cost_breakdown

    def _estimate_ec2_cost(self, vm: Dict[str, Any]) -> Dict[str, Any]:
        """Estimate EC2 cost for an Azure VM."""
        vm_size = vm.get('size', 'default')
        pricing = self.AWS_PRICING['ec2'].get(vm_size, self.AWS_PRICING['ec2']['default'])
        
        return {
            'azure_vm_name': vm['name'],
            'azure_size': vm_size,
            'aws_instance_type': pricing['type'],
            'monthly_cost': pricing['monthly_cost'],
            'os_type': vm.get('os_type', 'Linux')
        }

    def _estimate_s3_cost(self, storage: Dict[str, Any]) -> Dict[str, Any]:
        """Estimate S3 cost for Azure Storage (simplified to 100GB average)."""
        # This is a rough estimate - in reality you'd need to check actual usage
        estimated_gb = 100  # Assume 100GB average usage
        access_tier = storage.get('access_tier', 'Hot')
        
        if access_tier == 'Cool':
            rate = self.AWS_PRICING['s3']['infrequent_access']
        elif access_tier == 'Archive':
            rate = self.AWS_PRICING['s3']['cold']
        else:
            rate = self.AWS_PRICING['s3']['standard']
        
        monthly_cost = estimated_gb * rate
        
        return {
            'azure_storage_name': storage['name'],
            'azure_tier': access_tier,
            'estimated_gb': estimated_gb,
            'aws_storage_class': 'Standard' if access_tier == 'Hot' else 'IA',
            'monthly_cost': monthly_cost
        }

    def _estimate_rds_cost(self, database: Dict[str, Any]) -> Dict[str, Any]:
        """Estimate RDS cost for Azure SQL Database."""
        sku = database.get('sku', 'default')
        pricing = self.AWS_PRICING['rds'].get(sku, self.AWS_PRICING['rds']['default'])
        
        return {
            'azure_db_name': database['name'],
            'azure_sku': sku,
            'aws_instance_type': pricing['type'],
            'monthly_cost': pricing['monthly_cost']
        }

    def _estimate_lambda_cost(self, app: Dict[str, Any]) -> Dict[str, Any]:
        """Estimate Lambda cost for Azure App Service (very rough estimate)."""
        # Very simplified - assumes moderate usage
        estimated_monthly_cost = 10.0  # Rough estimate for typical web app
        
        return {
            'azure_app_name': app['name'],
            'aws_service': 'Lambda + API Gateway',
            'monthly_cost': estimated_monthly_cost
        }

def generate_report(azure_resources: Dict[str, List[Dict[str, Any]]], 
                   aws_costs: Dict[str, Any]) -> str:
    """Generate a comprehensive report."""
    report = []
    report.append("=" * 80)
    report.append("AZURE RESOURCE DISCOVERY & AWS COST ESTIMATION REPORT")
    report.append("=" * 80)
    report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report.append("")
    
    # Azure Resources Summary
    report.append("AZURE RESOURCES SUMMARY")
    report.append("-" * 40)
    report.append(f"Virtual Machines: {len(azure_resources['virtual_machines'])}")
    report.append(f"Storage Accounts: {len(azure_resources['storage_accounts'])}")
    report.append(f"SQL Databases: {len(azure_resources['sql_databases'])}")
    report.append(f"App Services: {len(azure_resources['app_services'])}")
    report.append(f"Other Resources: {len(azure_resources['other_resources'])}")
    report.append("")
    
    # Detailed Azure Resources
    if azure_resources['virtual_machines']:
        report.append("VIRTUAL MACHINES")
        report.append("-" * 40)
        for vm in azure_resources['virtual_machines']:
            report.append(f"• {vm['name']} ({vm['size']}) in {vm['location']}")
        report.append("")
    
    if azure_resources['storage_accounts']:
        report.append("STORAGE ACCOUNTS")
        report.append("-" * 40)
        for storage in azure_resources['storage_accounts']:
            report.append(f"• {storage['name']} ({storage['sku']}) - {storage.get('access_tier', 'Hot')} tier")
        report.append("")
    
    if azure_resources['sql_databases']:
        report.append("SQL DATABASES")
        report.append("-" * 40)
        for db in azure_resources['sql_databases']:
            report.append(f"• {db['name']} on {db['server']} ({db.get('sku', 'Unknown')})")
        report.append("")
    
    if azure_resources['app_services']:
        report.append("APP SERVICES")
        report.append("-" * 40)
        for app in azure_resources['app_services']:
            report.append(f"• {app['name']} ({app.get('kind', 'Unknown')}) - {app.get('state', 'Unknown')}")
        report.append("")
    
    # AWS Cost Estimates
    report.append("AWS COST ESTIMATES")
    report.append("-" * 40)
    
    if aws_costs['ec2_instances']:
        report.append("EC2 Instances (from Azure VMs):")
        for ec2 in aws_costs['ec2_instances']:
            report.append(f"  • {ec2['azure_vm_name']} → {ec2['aws_instance_type']}: ${ec2['monthly_cost']:.2f}/month")
    
    if aws_costs['s3_storage']:
        report.append("S3 Storage (from Azure Storage):")
        for s3 in aws_costs['s3_storage']:
            report.append(f"  • {s3['azure_storage_name']} → S3 {s3['aws_storage_class']}: ${s3['monthly_cost']:.2f}/month")
    
    if aws_costs['rds_databases']:
        report.append("RDS Databases (from Azure SQL):")
        for rds in aws_costs['rds_databases']:
            report.append(f"  • {rds['azure_db_name']} → {rds['aws_instance_type']}: ${rds['monthly_cost']:.2f}/month")
    
    if aws_costs['lambda_functions']:
        report.append("Lambda Functions (from Azure App Services):")
        for lamb in aws_costs['lambda_functions']:
            report.append(f"  • {lamb['azure_app_name']} → {lamb['aws_service']}: ${lamb['monthly_cost']:.2f}/month")
    
    report.append("")
    report.append("=" * 80)
    report.append(f"ESTIMATED TOTAL MONTHLY AWS COST: ${aws_costs['total_monthly_cost']:.2f}")
    report.append("=" * 80)
    report.append("")
    report.append("NOTES:")
    report.append("• These are rough estimates based on typical usage patterns")
    report.append("• Actual costs may vary significantly based on:")
    report.append("  - Actual resource utilization")
    report.append("  - Data transfer costs")
    report.append("  - Reserved instance discounts")
    report.append("  - Specific AWS region pricing")
    report.append("• For accurate pricing, use AWS Pricing Calculator")
    
    return "\n".join(report)

def main():
    """Main function to run the Azure resource discovery and AWS cost estimation."""
    parser = argparse.ArgumentParser(description='Discover Azure resources and estimate AWS costs')
    parser.add_argument('--subscription-id', help='Azure subscription ID (optional)')
    parser.add_argument('--output', '-o', help='Output file for the report (optional)')
    parser.add_argument('--json', action='store_true', help='Output results in JSON format')
    
    args = parser.parse_args()
    
    try:
        # Initialize Azure resource discovery
        discovery = AzureResourceDiscovery(args.subscription_id)
        
        # Discover resources
        azure_resources = discovery.discover_resources()
        
        # Estimate AWS costs
        cost_estimator = AWSCostEstimator()
        aws_costs = cost_estimator.estimate_costs(azure_resources)
        
        if args.json:
            # Output JSON format
            result = {
                'azure_resources': azure_resources,
                'aws_cost_estimates': aws_costs,
                'timestamp': datetime.now().isoformat()
            }
            json_output = json.dumps(result, indent=2, default=str)
            
            if args.output:
                with open(args.output, 'w') as f:
                    f.write(json_output)
                print(f"JSON report saved to: {args.output}")
            else:
                print(json_output)
        else:
            # Generate and display report
            report = generate_report(azure_resources, aws_costs)
            
            if args.output:
                with open(args.output, 'w') as f:
                    f.write(report)
                print(f"Report saved to: {args.output}")
            else:
                print(report)
                
    except KeyboardInterrupt:
        print("\nOperation cancelled by user.")
        sys.exit(1)
    except Exception as e:
        logger.error(f"An error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()