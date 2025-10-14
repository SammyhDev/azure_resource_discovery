# Azure Resource Discovery

A Python script to discover and report on Azure resources in a subscription or landing zone. This tool generates comprehensive reports including cost data, resource inventory, and performance metrics.

## Features

- **Cost & Consumption Analysis**: Retrieve billing data for the last 30 days
- **Complete Resource Inventory**: List all resources with details (type, location, tags, etc.)
- **Performance Metrics**: Collect performance metrics for monitored resources
- **Excel Reports**: Consolidated report with multiple sheets for easy analysis
- **ZIP Archive**: All reports packaged in a single compressed file

## Generated Reports

The script generates the following files with timestamps:

| File | Description |
|------|-------------|
| `Consumption_ResourcesReport_YYYYMMDD_HHMMSS.json` | Cost and billing data for the last 30 days |
| `Inventory_ResourcesReport_YYYYMMDD_HHMMSS.json` | Complete resource inventory with all details |
| `Metrics_ResourcesReport_YYYYMMDD_HHMMSS.json` | Performance metrics data for monitored resources |
| `ResourcesReport_YYYYMMDD_HHMMSS.xlsx` | Consolidated Excel report with all data in separate sheets |
| `ResourcesReport_YYYYMMDD_HHMMSS.zip` | ZIP archive containing all the above files |

## Prerequisites

- Python 3.7 or higher
- Azure subscription
- Appropriate Azure permissions to read resources, costs, and metrics

## Installation

1. Clone this repository:
```bash
git clone https://github.com/SammyhDev/azure_resource_discovery.git
cd azure_resource_discovery
```

2. Install required dependencies:
```bash
pip install -r requirements.txt
```

## Authentication

The script uses Azure's `DefaultAzureCredential`, which supports multiple authentication methods:

### Option 1: Azure CLI (Recommended for local use)
```bash
az login
```

### Option 2: Service Principal (Recommended for automation)
Set the following environment variables:
```bash
export AZURE_CLIENT_ID="your-client-id"
export AZURE_TENANT_ID="your-tenant-id"
export AZURE_CLIENT_SECRET="your-client-secret"
```

### Option 3: Managed Identity
Automatically works when running in Azure (VM, App Service, Function, etc.)

## Usage

### Basic Usage

Generate reports for a specific subscription:
```bash
python azure_resource_discovery.py --subscription-id YOUR_SUBSCRIPTION_ID
```

### Custom Output Directory

Specify a custom directory for the generated reports:
```bash
python azure_resource_discovery.py --subscription-id YOUR_SUBSCRIPTION_ID --output-dir ./reports
```

### Complete Example

```bash
# Authenticate with Azure
az login

# Run the script
python azure_resource_discovery.py --subscription-id 12345678-1234-1234-1234-123456789abc --output-dir ./azure-reports

# Output files will be created in ./azure-reports/
```

## Required Azure Permissions

The account or service principal needs the following permissions:

- **Reader** role on the subscription (for resource inventory)
- **Cost Management Reader** role (for cost data)
- **Monitoring Reader** role (for metrics data)

You can assign these roles using Azure CLI:
```bash
az role assignment create --assignee USER_OR_SP_ID --role "Reader" --scope /subscriptions/SUBSCRIPTION_ID
az role assignment create --assignee USER_OR_SP_ID --role "Cost Management Reader" --scope /subscriptions/SUBSCRIPTION_ID
az role assignment create --assignee USER_OR_SP_ID --role "Monitoring Reader" --scope /subscriptions/SUBSCRIPTION_ID
```

## Output Examples

### Console Output
```
============================================================
Azure Resource Discovery - Report Generation
============================================================
✓ Successfully authenticated with Azure
✓ Using subscription: 12345678-1234-1234-1234-123456789abc

📊 Collecting consumption and cost data...
  ✓ Collected 45 cost entries
  ✓ Total cost: $1,234.56

📦 Collecting resource inventory...
  ✓ Found 127 resources
  ✓ 23 unique resource types

📈 Collecting performance metrics...
  ✓ Collected 89 metric data points
  ✓ Monitored 10 resources

✓ Saved: Consumption_ResourcesReport_20250114_120000.json
✓ Saved: Inventory_ResourcesReport_20250114_120000.json
✓ Saved: Metrics_ResourcesReport_20250114_120000.json

📝 Creating consolidated Excel report...
  ✓ Excel report created: ResourcesReport_20250114_120000.xlsx

📦 Creating ZIP archive...
  ✓ Added: Consumption_ResourcesReport_20250114_120000.json
  ✓ Added: Inventory_ResourcesReport_20250114_120000.json
  ✓ Added: Metrics_ResourcesReport_20250114_120000.json
  ✓ Added: ResourcesReport_20250114_120000.xlsx
  ✓ ZIP archive created: ResourcesReport_20250114_120000.zip

============================================================
✓ Report generation completed successfully!
============================================================

Generated files:
  • Consumption_ResourcesReport_20250114_120000.json (45.2 KB)
  • Inventory_ResourcesReport_20250114_120000.json (89.7 KB)
  • Metrics_ResourcesReport_20250114_120000.json (23.1 KB)
  • ResourcesReport_20250114_120000.xlsx (67.4 KB)
  • ResourcesReport_20250114_120000.zip (134.8 KB)
```

### JSON Report Structure

**Consumption Report:**
```json
{
  "timestamp": "2025-01-14T12:00:00",
  "subscription_id": "12345678-1234-1234-1234-123456789abc",
  "costs": [
    {
      "cost": 45.67,
      "date": "2025-01-14",
      "resource_type": "Microsoft.Compute/virtualMachines",
      "currency": "USD"
    }
  ],
  "summary": {
    "total_cost": 1234.56,
    "period_start": "2024-12-15T00:00:00",
    "period_end": "2025-01-14T23:59:59",
    "currency": "USD"
  }
}
```

**Inventory Report:**
```json
{
  "timestamp": "2025-01-14T12:00:00",
  "subscription_id": "12345678-1234-1234-1234-123456789abc",
  "resources": [
    {
      "id": "/subscriptions/.../resourceGroups/rg-prod/providers/Microsoft.Compute/virtualMachines/vm-web-01",
      "name": "vm-web-01",
      "type": "Microsoft.Compute/virtualMachines",
      "location": "eastus",
      "resource_group": "rg-prod",
      "tags": {"environment": "production"},
      "provisioning_state": "Succeeded"
    }
  ],
  "summary": {
    "total_resources": 127,
    "unique_resource_types": 23
  }
}
```

## Troubleshooting

### Authentication Issues
- Ensure you're logged in: `az login`
- Verify subscription access: `az account show`
- Check permissions: `az role assignment list --assignee YOUR_EMAIL`

### Missing Cost Data
- Verify the subscription has cost data for the last 30 days
- Ensure you have "Cost Management Reader" role
- Some subscription types may not have cost data available

### No Metrics Collected
- Metrics are only collected for resources that support Azure Monitor
- The script samples up to 10 resources to avoid rate limiting
- Some resource types may not have metrics enabled

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Sammy Harris

## Support

For issues and questions, please open an issue on GitHub.