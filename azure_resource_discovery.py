#!/usr/bin/env python3
"""
Azure Resource Discovery Script

This script collects information about Azure resources including:
- Consumption and cost data
- Resource inventory
- Performance metrics

The script generates JSON reports and a consolidated Excel file, all packaged in a ZIP file.
"""

import argparse
import json
import os
import sys
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import zipfile

try:
    from azure.identity import DefaultAzureCredential
    from azure.mgmt.resource import ResourceManagementClient
    from azure.mgmt.costmanagement import CostManagementClient
    from azure.mgmt.monitor import MonitorManagementClient
    import pandas as pd
except ImportError as e:
    print(f"Error: Missing required dependencies. Please run: pip install -r requirements.txt")
    print(f"Details: {e}")
    sys.exit(1)


class AzureResourceDiscovery:
    """Main class for Azure resource discovery and reporting."""
    
    def __init__(self, subscription_id: str, output_dir: str = "."):
        """
        Initialize the Azure Resource Discovery client.
        
        Args:
            subscription_id: Azure subscription ID
            output_dir: Directory where reports will be saved
        """
        self.subscription_id = subscription_id
        self.output_dir = output_dir
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        try:
            # Initialize Azure credential
            self.credential = DefaultAzureCredential()
            
            # Initialize Azure clients
            self.resource_client = ResourceManagementClient(self.credential, subscription_id)
            self.cost_client = CostManagementClient(self.credential)
            self.monitor_client = MonitorManagementClient(self.credential, subscription_id)
            
            print(f"✓ Successfully authenticated with Azure")
            print(f"✓ Using subscription: {subscription_id}")
        except Exception as e:
            print(f"Error: Failed to authenticate with Azure: {e}")
            print("\nPlease ensure you are authenticated. You can authenticate using:")
            print("  - Azure CLI: az login")
            print("  - Environment variables (AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_CLIENT_SECRET)")
            print("  - Managed Identity (when running in Azure)")
            sys.exit(1)
    
    def collect_consumption_data(self) -> Dict:
        """
        Collect cost and billing data from Azure Cost Management.
        
        Returns:
            Dictionary containing consumption and cost data
        """
        print("\n📊 Collecting consumption and cost data...")
        
        consumption_data = {
            "timestamp": datetime.now().isoformat(),
            "subscription_id": self.subscription_id,
            "costs": [],
            "summary": {}
        }
        
        try:
            # Define time scope for the last 30 days
            end_date = datetime.now()
            start_date = end_date - timedelta(days=30)
            
            scope = f"/subscriptions/{self.subscription_id}"
            
            # Query parameters for cost data
            query_definition = {
                "type": "Usage",
                "timeframe": "Custom",
                "time_period": {
                    "from": start_date.strftime("%Y-%m-%dT00:00:00Z"),
                    "to": end_date.strftime("%Y-%m-%dT23:59:59Z")
                },
                "dataset": {
                    "granularity": "Daily",
                    "aggregation": {
                        "totalCost": {
                            "name": "Cost",
                            "function": "Sum"
                        }
                    },
                    "grouping": [
                        {
                            "type": "Dimension",
                            "name": "ResourceType"
                        }
                    ]
                }
            }
            
            # Execute query
            result = self.cost_client.query.usage(scope, query_definition)
            
            # Process results
            if hasattr(result, 'rows') and result.rows:
                total_cost = 0
                for row in result.rows:
                    cost_entry = {
                        "cost": row[0] if len(row) > 0 else 0,
                        "date": row[1].isoformat() if len(row) > 1 and hasattr(row[1], 'isoformat') else str(row[1]) if len(row) > 1 else "",
                        "resource_type": row[2] if len(row) > 2 else "Unknown",
                        "currency": result.columns[0].name if hasattr(result, 'columns') and result.columns else "USD"
                    }
                    consumption_data["costs"].append(cost_entry)
                    total_cost += cost_entry["cost"]
                
                consumption_data["summary"] = {
                    "total_cost": total_cost,
                    "period_start": start_date.isoformat(),
                    "period_end": end_date.isoformat(),
                    "currency": "USD",
                    "number_of_entries": len(consumption_data["costs"])
                }
                print(f"  ✓ Collected {len(consumption_data['costs'])} cost entries")
                print(f"  ✓ Total cost: ${total_cost:.2f}")
            else:
                print("  ⚠ No cost data available for the specified period")
                consumption_data["summary"] = {
                    "message": "No cost data available",
                    "period_start": start_date.isoformat(),
                    "period_end": end_date.isoformat()
                }
                
        except Exception as e:
            print(f"  ⚠ Warning: Could not retrieve cost data: {e}")
            consumption_data["error"] = str(e)
            consumption_data["summary"] = {"message": "Error retrieving cost data"}
        
        return consumption_data
    
    def collect_inventory_data(self) -> Dict:
        """
        Collect complete resource inventory from Azure.
        
        Returns:
            Dictionary containing all resources in the subscription
        """
        print("\n📦 Collecting resource inventory...")
        
        inventory_data = {
            "timestamp": datetime.now().isoformat(),
            "subscription_id": self.subscription_id,
            "resources": [],
            "summary": {}
        }
        
        try:
            # Get all resources in the subscription
            resources = list(self.resource_client.resources.list())
            
            resource_types = {}
            for resource in resources:
                resource_info = {
                    "id": resource.id,
                    "name": resource.name,
                    "type": resource.type,
                    "location": resource.location,
                    "resource_group": resource.id.split('/')[4] if len(resource.id.split('/')) > 4 else "Unknown",
                    "tags": resource.tags if resource.tags else {},
                    "provisioning_state": getattr(resource, 'provisioning_state', 'Unknown')
                }
                inventory_data["resources"].append(resource_info)
                
                # Count by resource type
                resource_types[resource.type] = resource_types.get(resource.type, 0) + 1
            
            inventory_data["summary"] = {
                "total_resources": len(resources),
                "resource_types": resource_types,
                "unique_resource_types": len(resource_types)
            }
            
            print(f"  ✓ Found {len(resources)} resources")
            print(f"  ✓ {len(resource_types)} unique resource types")
            
        except Exception as e:
            print(f"  ✗ Error collecting inventory: {e}")
            inventory_data["error"] = str(e)
            inventory_data["summary"] = {"message": "Error collecting inventory"}
        
        return inventory_data
    
    def collect_metrics_data(self, inventory_data: Dict) -> Dict:
        """
        Collect performance metrics for resources.
        
        Args:
            inventory_data: Previously collected inventory data
            
        Returns:
            Dictionary containing metrics data
        """
        print("\n📈 Collecting performance metrics...")
        
        metrics_data = {
            "timestamp": datetime.now().isoformat(),
            "subscription_id": self.subscription_id,
            "metrics": [],
            "summary": {}
        }
        
        try:
            # Sample a subset of resources for metrics (to avoid rate limiting)
            resources_to_monitor = inventory_data.get("resources", [])[:10]  # Limit to 10 resources
            
            metrics_collected = 0
            for resource in resources_to_monitor:
                try:
                    resource_id = resource.get("id")
                    resource_type = resource.get("type", "").lower()
                    
                    # Define common metrics based on resource type
                    metric_names = []
                    if "microsoft.compute/virtualmachines" in resource_type:
                        metric_names = ["Percentage CPU", "Network In Total", "Network Out Total"]
                    elif "microsoft.storage/storageaccounts" in resource_type:
                        metric_names = ["UsedCapacity", "Transactions", "Availability"]
                    elif "microsoft.sql/servers/databases" in resource_type:
                        metric_names = ["cpu_percent", "storage_percent", "dtu_consumption_percent"]
                    
                    if metric_names and resource_id:
                        # Get metrics for the last hour
                        end_time = datetime.utcnow()
                        start_time = end_time - timedelta(hours=1)
                        
                        for metric_name in metric_names:
                            try:
                                metrics = self.monitor_client.metrics.list(
                                    resource_id,
                                    timespan=f"{start_time.isoformat()}/{end_time.isoformat()}",
                                    interval='PT5M',
                                    metricnames=metric_name,
                                    aggregation='Average'
                                )
                                
                                for metric in metrics.value:
                                    for timeseries in metric.timeseries:
                                        for data in timeseries.data:
                                            if data.average is not None:
                                                metrics_data["metrics"].append({
                                                    "resource_id": resource_id,
                                                    "resource_name": resource.get("name"),
                                                    "metric_name": metric_name,
                                                    "value": data.average,
                                                    "unit": metric.unit,
                                                    "timestamp": data.time_stamp.isoformat()
                                                })
                                                metrics_collected += 1
                            except Exception:
                                # Skip metrics that are not available for this resource
                                continue
                                
                except Exception:
                    # Skip resources that don't support metrics
                    continue
            
            metrics_data["summary"] = {
                "total_metrics": metrics_collected,
                "resources_monitored": len(resources_to_monitor)
            }
            
            print(f"  ✓ Collected {metrics_collected} metric data points")
            print(f"  ✓ Monitored {len(resources_to_monitor)} resources")
            
        except Exception as e:
            print(f"  ⚠ Warning: Error collecting metrics: {e}")
            metrics_data["error"] = str(e)
            metrics_data["summary"] = {"message": "Error collecting metrics"}
        
        return metrics_data
    
    def create_excel_report(self, consumption_data: Dict, inventory_data: Dict, metrics_data: Dict) -> str:
        """
        Create a consolidated Excel report from all collected data.
        
        Args:
            consumption_data: Cost and consumption data
            inventory_data: Resource inventory data
            metrics_data: Performance metrics data
            
        Returns:
            Path to the created Excel file
        """
        print("\n📝 Creating consolidated Excel report...")
        
        excel_filename = os.path.join(self.output_dir, f"ResourcesReport_{self.timestamp}.xlsx")
        
        try:
            with pd.ExcelWriter(excel_filename, engine='openpyxl') as writer:
                # Summary sheet
                summary_data = {
                    "Category": ["Subscription ID", "Report Date", "Total Resources", "Total Cost (Last 30 Days)", "Metrics Collected"],
                    "Value": [
                        self.subscription_id,
                        datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                        inventory_data.get("summary", {}).get("total_resources", 0),
                        f"${consumption_data.get('summary', {}).get('total_cost', 0):.2f}",
                        metrics_data.get("summary", {}).get("total_metrics", 0)
                    ]
                }
                df_summary = pd.DataFrame(summary_data)
                df_summary.to_excel(writer, sheet_name='Summary', index=False)
                
                # Consumption sheet
                if consumption_data.get("costs"):
                    df_consumption = pd.DataFrame(consumption_data["costs"])
                    df_consumption.to_excel(writer, sheet_name='Consumption', index=False)
                
                # Inventory sheet
                if inventory_data.get("resources"):
                    df_inventory = pd.DataFrame(inventory_data["resources"])
                    df_inventory.to_excel(writer, sheet_name='Inventory', index=False)
                
                # Metrics sheet
                if metrics_data.get("metrics"):
                    df_metrics = pd.DataFrame(metrics_data["metrics"])
                    df_metrics.to_excel(writer, sheet_name='Metrics', index=False)
            
            print(f"  ✓ Excel report created: {excel_filename}")
            return excel_filename
            
        except Exception as e:
            print(f"  ✗ Error creating Excel report: {e}")
            return None
    
    def create_zip_archive(self, files_to_zip: List[str]) -> str:
        """
        Create a ZIP archive containing all report files.
        
        Args:
            files_to_zip: List of file paths to include in the archive
            
        Returns:
            Path to the created ZIP file
        """
        print("\n📦 Creating ZIP archive...")
        
        zip_filename = os.path.join(self.output_dir, f"ResourcesReport_{self.timestamp}.zip")
        
        try:
            with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
                for file_path in files_to_zip:
                    if file_path and os.path.exists(file_path):
                        arcname = os.path.basename(file_path)
                        zipf.write(file_path, arcname)
                        print(f"  ✓ Added: {arcname}")
            
            print(f"  ✓ ZIP archive created: {zip_filename}")
            return zip_filename
            
        except Exception as e:
            print(f"  ✗ Error creating ZIP archive: {e}")
            return None
    
    def generate_reports(self) -> bool:
        """
        Main method to generate all reports.
        
        Returns:
            True if successful, False otherwise
        """
        print("\n" + "="*60)
        print("Azure Resource Discovery - Report Generation")
        print("="*60)
        
        try:
            # Ensure output directory exists
            os.makedirs(self.output_dir, exist_ok=True)
            
            # Collect data
            consumption_data = self.collect_consumption_data()
            inventory_data = self.collect_inventory_data()
            metrics_data = self.collect_metrics_data(inventory_data)
            
            # Save JSON files
            json_files = []
            
            consumption_file = os.path.join(self.output_dir, f"Consumption_ResourcesReport_{self.timestamp}.json")
            with open(consumption_file, 'w') as f:
                json.dump(consumption_data, f, indent=2)
            print(f"\n✓ Saved: {consumption_file}")
            json_files.append(consumption_file)
            
            inventory_file = os.path.join(self.output_dir, f"Inventory_ResourcesReport_{self.timestamp}.json")
            with open(inventory_file, 'w') as f:
                json.dump(inventory_data, f, indent=2)
            print(f"✓ Saved: {inventory_file}")
            json_files.append(inventory_file)
            
            metrics_file = os.path.join(self.output_dir, f"Metrics_ResourcesReport_{self.timestamp}.json")
            with open(metrics_file, 'w') as f:
                json.dump(metrics_data, f, indent=2)
            print(f"✓ Saved: {metrics_file}")
            json_files.append(metrics_file)
            
            # Create Excel report
            excel_file = self.create_excel_report(consumption_data, inventory_data, metrics_data)
            if excel_file:
                json_files.append(excel_file)
            
            # Create ZIP archive
            zip_file = self.create_zip_archive(json_files)
            
            # Print summary
            print("\n" + "="*60)
            print("✓ Report generation completed successfully!")
            print("="*60)
            print("\nGenerated files:")
            for file_path in json_files:
                if os.path.exists(file_path):
                    size = os.path.getsize(file_path) / 1024  # KB
                    print(f"  • {os.path.basename(file_path)} ({size:.1f} KB)")
            if zip_file and os.path.exists(zip_file):
                size = os.path.getsize(zip_file) / 1024  # KB
                print(f"  • {os.path.basename(zip_file)} ({size:.1f} KB)")
            print()
            
            return True
            
        except Exception as e:
            print(f"\n✗ Error generating reports: {e}")
            import traceback
            traceback.print_exc()
            return False


def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description="Azure Resource Discovery - Generate comprehensive reports about your Azure resources",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate reports for a specific subscription
  python azure_resource_discovery.py --subscription-id YOUR_SUBSCRIPTION_ID
  
  # Generate reports with custom output directory
  python azure_resource_discovery.py --subscription-id YOUR_SUBSCRIPTION_ID --output-dir ./reports
  
Authentication:
  This script uses DefaultAzureCredential which supports multiple authentication methods:
  - Azure CLI: Run 'az login' before executing the script
  - Environment variables: Set AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_CLIENT_SECRET
  - Managed Identity: Automatically works when running in Azure
        """
    )
    
    parser.add_argument(
        '--subscription-id',
        required=True,
        help='Azure subscription ID to scan'
    )
    
    parser.add_argument(
        '--output-dir',
        default='.',
        help='Output directory for generated reports (default: current directory)'
    )
    
    args = parser.parse_args()
    
    # Create discovery instance and generate reports
    discovery = AzureResourceDiscovery(args.subscription_id, args.output_dir)
    success = discovery.generate_reports()
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
