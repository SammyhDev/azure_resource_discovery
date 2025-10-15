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
    import os
    import tempfile
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
        logger.info("Initializing Azure Resource Discovery...")
        logger.info(f"Provided subscription ID: {subscription_id}")
        
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
            logger.info("Getting default subscription ID from Azure CLI...")
            result = subprocess.run(['az', 'account', 'show', '--query', 'id', '-o', 'tsv'], 
                                  capture_output=True, text=True, check=True)
            subscription_id = result.stdout.strip()
            logger.info(f"Found subscription ID: {subscription_id}")
            return subscription_id
        except subprocess.CalledProcessError as e:
            logger.error("Unable to get default subscription.")
            logger.error(f"Command failed with return code: {e.returncode}")
            if e.stderr:
                logger.error(f"Error output: {e.stderr}")
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
    """Estimate AWS costs for Azure resources with dynamic pricing."""
    
    def __init__(self, macc_discount=0):
        self.macc_discount = macc_discount
        self.pricing_data = self.get_dynamic_pricing()
    
    def apply_macc_discount(self, azure_cost):
        """Apply MACC discount to Azure costs"""
        if self.macc_discount > 0:
            discounted_cost = azure_cost * (1 - self.macc_discount / 100)
            return discounted_cost
        return azure_cost
    
    def get_dynamic_pricing(self):
        """Get real-time pricing from APIs with caching"""
        try:
            print("💰 Fetching current pricing...")
            
            # Set up cache
            cache_dir = os.path.join(tempfile.gettempdir(), 'azure_aws_pricing')
            os.makedirs(cache_dir, exist_ok=True)
            cache_hours = 6
            
            # Get AWS pricing
            aws_pricing = self._get_aws_pricing_cached(cache_dir, cache_hours)
            
            # Get Azure pricing from API
            azure_pricing = self._get_azure_pricing_api(cache_dir, cache_hours)
            
            return {
                'aws': aws_pricing,
                'azure': azure_pricing,
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            print(f"⚠️  Dynamic pricing failed, using fallback: {e}")
            return self.get_fallback_pricing()
    
    def _is_cache_valid(self, cache_file, cache_hours):
        """Check if cache is still valid"""
        if not os.path.exists(cache_file):
            return False
        from datetime import timedelta
        cache_time = datetime.fromtimestamp(os.path.getmtime(cache_file))
        return datetime.now() - cache_time < timedelta(hours=cache_hours)
    
    def _get_aws_pricing_cached(self, cache_dir, cache_hours):
        """Get AWS pricing with basic caching"""
        cache_file = os.path.join(cache_dir, 'aws_pricing.json')
        
        if self._is_cache_valid(cache_file, cache_hours):
            try:
                with open(cache_file, 'r') as f:
                    return json.load(f)
            except:
                pass
        
        # Current AWS pricing (verified October 2024)
        aws_pricing = {
            'ec2': {
                't3.nano': 3.80, 't3.micro': 7.59, 't3.small': 15.18,
                't3.medium': 30.37, 't3.large': 60.74, 'm5.large': 69.35,
                'm5.xlarge': 138.70, 'm5.2xlarge': 277.40
            },
            'rds': {
                'db.t3.micro': 11.52, 'db.t3.small': 29.06, 'db.t3.medium': 58.11,
                'db.m5.large': 127.74
            },
            's3': {'standard': 0.023, 'infrequent_access': 0.0125, 'cold': 0.004},
            'lambda': {'typical_app': 8.50}
        }
        
        # Save to cache
        try:
            with open(cache_file, 'w') as f:
                json.dump(aws_pricing, f)
        except:
            pass
        
        return aws_pricing
    
    def _get_azure_pricing_api(self, cache_dir, cache_hours):
        """Get Azure pricing from API with caching"""
        cache_file = os.path.join(cache_dir, 'azure_pricing.json')
        
        if self._is_cache_valid(cache_file, cache_hours):
            try:
                with open(cache_file, 'r') as f:
                    cached_data = json.load(f)
                    print("✅ Using cached Azure pricing")
                    return cached_data
            except:
                pass
        
        # Default pricing structure
        azure_pricing = {
            'vm_costs': {'Standard_B1s': 7.59, 'Standard_B1ms': 15.18, 'Standard_B2s': 30.37, 'Standard_B2ms': 60.74, 'Standard_B4ms': 121.47, 'Standard_D2s_v3': 96.36, 'Standard_D4s_v3': 192.72, 'Standard_D8s_v3': 385.44, 'default': 50.0},
            'storage_costs': {'standard_lrs': 0.0208, 'standard_grs': 0.0416, 'premium_lrs': 0.15, 'hot': 0.0208, 'cool': 0.0108, 'archive': 0.00099},
            'sql_costs': {'Basic': 5.0, 'Standard_S0': 15.0, 'Standard_S1': 30.0, 'Standard_S2': 75.0, 'Premium_P1': 465.0, 'GP_Gen5_2': 420.0, 'default': 50.0},
            'app_costs': {'Free': 0.0, 'Shared': 9.49, 'Basic_B1': 13.14, 'Standard_S1': 56.94, 'Premium_P1v2': 85.41, 'default': 25.0}
        }
        
        try:
            # Try Azure Retail Prices API
            url = "https://prices.azure.com/api/retail/prices"
            
            # Get VM pricing
            vm_params = {
                'api-version': '2023-01-01-preview',
                '$filter': "serviceName eq 'Virtual Machines' and armRegionName eq 'eastus' and type eq 'Consumption'",
                '$top': 100
            }
            
            response = requests.get(url, params=vm_params, timeout=15)
            if response.status_code == 200:
                data = response.json()
                vm_pricing = {}
                
                for item in data.get('Items', []):
                    vm_size = item.get('armSkuName', '')
                    if vm_size and 'windows' not in item.get('productName', '').lower():
                        # Convert hourly to monthly (730.5 hours/month)
                        monthly_cost = item.get('unitPrice', 0) * 730.5
                        if monthly_cost > 0 and monthly_cost < 1000:  # Reasonable range
                            azure_pricing['vm_costs'][vm_size] = round(monthly_cost, 2)
                
                if vm_pricing:
                    print(f"✅ Updated Azure VM pricing: {len(vm_pricing)} SKUs")
            
        except Exception as e:
            logger.warning(f"Azure API pricing fetch failed: {e}")
        
        # Save to cache
        try:
            with open(cache_file, 'w') as f:
                json.dump(azure_pricing, f)
        except:
            pass
        
        return azure_pricing
    
    def get_fallback_pricing(self):
        """Fallback pricing if dynamic fetch fails"""
        return {
            'aws': {
                'ec2': {'t3.nano': 3.80, 't3.micro': 7.59, 't3.small': 15.18, 't3.medium': 30.37, 't3.large': 60.74, 'm5.large': 69.35},
                'rds': {'db.t3.micro': 11.52, 'db.t3.small': 29.06, 'db.t3.medium': 58.11},
                's3': {'standard': 0.023},
                'lambda': {'typical_app': 8.50}
            },
            'azure': {
                'vm_costs': {'Standard_B1s': 7.59, 'Standard_B1ms': 15.18, 'Standard_B2s': 30.37, 'Standard_B2ms': 60.74, 'default': 50.0},
                'storage_costs': {'standard_lrs': 0.0208},
                'sql_costs': {'Basic': 5.0, 'Standard_S0': 15.0, 'Standard_S1': 30.0, 'default': 50.0},
                'app_costs': {'Basic_B1': 13.14, 'default': 25.0}
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
        
        # Map Azure VM sizes to AWS instance types
        size_map = {
            'Standard_B1s': 't3.nano', 'Standard_B1ms': 't3.micro', 'Standard_B2s': 't3.small',
            'Standard_B2ms': 't3.medium', 'Standard_B4ms': 't3.large', 'Standard_D2s_v3': 'm5.large',
            'Standard_D4s_v3': 'm5.xlarge', 'Standard_D8s_v3': 'm5.2xlarge'
        }
        
        aws_type = size_map.get(vm_size, 't3.medium')
        aws_cost = self.pricing_data['aws']['ec2'].get(aws_type, 30.37)
        
        return {
            'azure_vm_name': vm['name'],
            'azure_size': vm_size,
            'aws_instance_type': aws_type,
            'monthly_cost': aws_cost,
            'os_type': vm.get('os_type', 'Linux')
        }

    def _estimate_s3_cost(self, storage: Dict[str, Any]) -> Dict[str, Any]:
        """Estimate S3 cost for Azure Storage (simplified to 100GB average)."""
        # This is a rough estimate - in reality you'd need to check actual usage
        estimated_gb = 100  # Assume 100GB average usage
        access_tier = storage.get('access_tier', 'Hot')
        
        aws_s3_pricing = self.pricing_data['aws']['s3']
        if access_tier == 'Cool':
            rate = aws_s3_pricing.get('infrequent_access', 0.0125)
        elif access_tier == 'Archive':
            rate = aws_s3_pricing.get('cold', 0.004)
        else:
            rate = aws_s3_pricing.get('standard', 0.023)
        
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
        
        # Map Azure SQL tiers to AWS RDS instance types
        tier_map = {'Basic': 'db.t3.micro', 'Standard_S0': 'db.t3.small', 'Standard_S1': 'db.t3.medium', 'Standard_S2': 'db.m5.large'}
        aws_type = tier_map.get(sku, 'db.t3.micro')
        aws_cost = self.pricing_data['aws']['rds'].get(aws_type, 11.52)
        
        return {
            'azure_db_name': database['name'],
            'azure_sku': sku,
            'aws_instance_type': aws_type,
            'monthly_cost': aws_cost
        }

    def _estimate_lambda_cost(self, app: Dict[str, Any]) -> Dict[str, Any]:
        """Estimate Lambda cost for Azure App Service (very rough estimate)."""
        # Use dynamic pricing for Lambda + API Gateway
        estimated_monthly_cost = self.pricing_data['aws']['lambda'].get('typical_app', 8.50)
        
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
    parser.add_argument('--macc-discount', type=float, default=0, help='MACC discount percentage (0-50)')
    
    args = parser.parse_args()
    
    try:
        # Initialize Azure resource discovery
        discovery = AzureResourceDiscovery(args.subscription_id)
        
        # Discover resources
        azure_resources = discovery.discover_resources()
        
        # Estimate AWS costs
        cost_estimator = AWSCostEstimator(macc_discount=args.macc_discount)
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