# Azure App Service Deployment Guide

## 🚀 Deploy as Azure App Service Web App

Instead of running the analyzer locally, you can deploy it as a web application to Azure App Service. This provides several benefits:

### ✅ **Benefits of Web App Deployment**
- **No Local Dependencies**: No need to install Python, Azure CLI, or packages locally
- **Web Interface**: Beautiful, user-friendly web interface
- **Always Available**: Access from anywhere with internet
- **Team Sharing**: Share with colleagues and team members
- **Managed Identity**: Secure authentication using Azure managed identity
- **Scalable**: Can handle multiple concurrent analyses
- **Scheduled Analysis**: Potential for automated scheduled runs

### 🎯 **How It Works**
1. **Web Interface**: Users access a clean web interface instead of command line
2. **Background Processing**: Analysis runs in background with progress updates
3. **Real-time Status**: Live progress updates with visual indicators
4. **Professional Reports**: Beautiful HTML reports with charts and summaries
5. **Download Options**: Export results as JSON for further analysis

## 📦 **Deployment Options**

### Option 1: One-Click Deployment (Recommended)
```bash
# Navigate to webapp directory
cd webapp/deploy

# Run the deployment script
./deploy.sh
```

This script will:
- ✅ Create resource group
- ✅ Deploy App Service with managed identity
- ✅ Configure proper permissions (Reader access to subscription)
- ✅ Deploy the web application
- ✅ Configure all settings automatically

### Option 2: Manual Deployment

#### Step 1: Create App Service
```bash
# Set variables
RESOURCE_GROUP="azure-resource-discovery-rg"
APP_NAME="azure-cost-analyzer-$(date +%s)"
LOCATION="East US"

# Create resource group
az group create --name $RESOURCE_GROUP --location "$LOCATION"

# Deploy using ARM template
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file deploy/azure-template.json \
    --parameters webAppName=$APP_NAME location="$LOCATION" sku="B1"
```

#### Step 2: Configure Permissions
```bash
# Get the managed identity principal ID
PRINCIPAL_ID=$(az webapp identity show --resource-group $RESOURCE_GROUP --name $APP_NAME --query principalId -o tsv)

# Assign Reader role to subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
az role assignment create \
    --assignee $PRINCIPAL_ID \
    --role "Reader" \
    --scope "/subscriptions/$SUBSCRIPTION_ID"
```

#### Step 3: Deploy Code
```bash
# Create deployment package
zip -r webapp.zip . --exclude="deploy/*" "__pycache__/*" "*.pyc"

# Deploy to App Service
az webapp deploy \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME \
    --src-path webapp.zip \
    --type zip
```

## 🔧 **Configuration**

### Required App Settings
The following settings are automatically configured by the deployment script:

```bash
AZURE_SUBSCRIPTION_ID=<your-subscription-id>
FLASK_ENV=production
PYTHONPATH=/home/site/wwwroot
```

### Optional Settings
You can add these for additional functionality:

```bash
# Custom secret key for sessions
SECRET_KEY=<your-secret-key>

# Enable debug mode (not recommended for production)
FLASK_DEBUG=false

# Custom port (usually not needed)
PORT=8000
```

## 🌐 **Using the Web App**

### 1. **Access the Interface**
- Visit your App Service URL (provided after deployment)
- You'll see a clean, professional interface

### 2. **Start Analysis**
- Enter your MACC discount percentage (if applicable)
- Click "Analyze My Azure Resources"
- View real-time progress updates

### 3. **View Results**
- Professional report with cost comparisons
- Resource breakdown with visual charts
- Download detailed JSON reports
- Share results with team members

### 4. **Sample Interface Flow**
```
Home Page → Enter MACC % → Start Analysis → Progress Page → Results Page
    ↓              ↓            ↓             ↓            ↓
Beautiful UI → Simple Form → Background Job → Live Updates → Professional Report
```

## 🔐 **Security Features**

### Managed Identity Authentication
- **No Stored Credentials**: Uses Azure managed identity
- **Automatic Token Management**: Handles authentication automatically
- **Least Privilege**: Only requires Reader permissions
- **Secure by Default**: No credentials in code or configuration

### Web Application Security
- **Session Management**: Secure session handling
- **Input Validation**: All inputs validated and sanitized
- **HTTPS Only**: Forces secure connections
- **No Data Persistence**: Analysis results are temporary

## 📊 **Monitoring & Management**

### View Application Logs
```bash
az webapp log tail --resource-group $RESOURCE_GROUP --name $APP_NAME
```

### Scale the Application
```bash
# Scale up to handle more concurrent users
az appservice plan update --resource-group $RESOURCE_GROUP --name ${APP_NAME}-plan --sku B2

# Scale out (add more instances)
az appservice plan update --resource-group $RESOURCE_GROUP --name ${APP_NAME}-plan --number-of-workers 2
```

### Monitor Performance
```bash
# Enable Application Insights
az monitor app-insights component create \
    --app $APP_NAME \
    --location "$LOCATION" \
    --resource-group $RESOURCE_GROUP
```

## 💰 **Cost Considerations**

### App Service Pricing Tiers
- **F1 (Free)**: Good for testing, limited CPU/memory
- **B1 (Basic)**: Recommended for production, $13/month
- **B2 (Basic)**: Better performance, $26/month
- **S1+ (Standard)**: High availability, auto-scaling

### Usage Patterns
- **Light Usage**: F1 or B1 tier sufficient
- **Team Usage**: B2 or S1 recommended
- **Enterprise**: S2+ with auto-scaling

## 🔄 **Updates & Maintenance**

### Deploy Updates
```bash
# Update application code
cd webapp/deploy
./deploy.sh  # Redeploys with latest code
```

### Backup & Restore
```bash
# Backup app settings
az webapp config appsettings list --resource-group $RESOURCE_GROUP --name $APP_NAME > backup-settings.json

# Restore app settings
az webapp config appsettings set --resource-group $RESOURCE_GROUP --name $APP_NAME --settings @backup-settings.json
```

## 🗑️ **Cleanup**

### Remove Everything
```bash
# Delete the entire resource group (includes App Service, App Service Plan, etc.)
az group delete --name $RESOURCE_GROUP --yes
```

## 🆚 **Comparison: Local vs Web App**

| Feature | Local Scripts | Web App |
|---------|---------------|---------|
| **Setup** | Install dependencies | One-click deploy |
| **Interface** | Command line | Professional web UI |
| **Sharing** | Share files/reports | Share URL |
| **Updates** | Manual git pull | Automatic deployment |
| **Authentication** | Local Azure CLI | Managed Identity |
| **Accessibility** | Requires local access | Available anywhere |
| **Team Usage** | Individual only | Multi-user |
| **Cost** | Free (compute cost) | ~$13/month App Service |

## 🎯 **Recommendation**

**For Individual Use**: Local scripts are perfect
**For Team/Enterprise Use**: Web App deployment provides better experience and management

The web app version provides a much more professional and user-friendly experience while maintaining all the same powerful analysis capabilities!