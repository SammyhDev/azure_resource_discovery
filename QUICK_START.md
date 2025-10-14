# Quick Start Guide

Get started with Azure Resource Discovery in 3 simple steps!

## Step 1: Install Dependencies

```bash
pip install -r requirements.txt
```

## Step 2: Authenticate with Azure

Choose one of these methods:

### Using Azure CLI (Easiest)
```bash
az login
```

### Using Service Principal
```bash
export AZURE_CLIENT_ID="your-client-id"
export AZURE_TENANT_ID="your-tenant-id"
export AZURE_CLIENT_SECRET="your-client-secret"
```

## Step 3: Run the Script

```bash
python azure_resource_discovery.py --subscription-id YOUR_SUBSCRIPTION_ID
```

Or use the example script:

```bash
./example_usage.sh YOUR_SUBSCRIPTION_ID
```

## What You Get

After running the script, you'll have:

- ✅ **Consumption_ResourcesReport_TIMESTAMP.json** - Cost data
- ✅ **Inventory_ResourcesReport_TIMESTAMP.json** - All resources
- ✅ **Metrics_ResourcesReport_TIMESTAMP.json** - Performance metrics  
- ✅ **ResourcesReport_TIMESTAMP.xlsx** - Excel report
- ✅ **ResourcesReport_TIMESTAMP.zip** - Everything zipped

## Common Issues

### "Error: Missing required dependencies"
Run: `pip install -r requirements.txt`

### "Error: Failed to authenticate with Azure"
Make sure you're logged in: `az login`

### "No cost data available"
- Normal for new subscriptions or if there's no usage yet
- Verify you have "Cost Management Reader" role

## Need Help?

See the full [README.md](README.md) for detailed documentation.
