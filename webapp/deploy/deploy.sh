#!/bin/bash

# Azure App Service Deployment Script
# This script deploys the Azure Resource Discovery web app to Azure App Service

set -e

echo "🚀 Azure Resource Discovery - App Service Deployment"
echo "=================================================="

# Configuration
RESOURCE_GROUP="azure-resource-discovery-rg"
LOCATION="East US"
APP_NAME="azure-cost-analyzer"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "📋 Deployment Configuration:"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Location: $LOCATION"
echo "   App Name: $APP_NAME"
echo "   Subscription: $SUBSCRIPTION_ID"
echo

# Create resource group if it doesn't exist
echo "🔷 Creating resource group..."
az group create --name $RESOURCE_GROUP --location "$LOCATION" --output none
echo "✅ Resource group ready"

# Deploy ARM template
echo "🔷 Deploying App Service..."
echo "ℹ️  Using Free (F1) tier to avoid quota issues..."

DEPLOYMENT_OUTPUT=$(az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file azure-template.json \
    --parameters webAppName=$APP_NAME \
    --parameters location="$LOCATION" \
    --parameters sku="F1" \
    --output json)

if [ $? -ne 0 ]; then
    echo "❌ Deployment failed. Common causes:"
    echo ""
    echo "🔹 QUOTA LIMITATIONS:"
    echo "   Your subscription may not have App Service quota available"
    echo "   Solution: Request quota increase in Azure portal"
    echo "   Go to: Subscriptions → Usage + quotas → Request increase"
    echo ""
    echo "🔹 SUBSCRIPTION TYPE:"
    echo "   Some subscription types (Student, Trial) have limitations"
    echo "   Solution: Upgrade to Pay-As-You-Go or other subscription type"
    echo ""
    echo "🔹 REGIONAL AVAILABILITY:"
    echo "   Try a different Azure region (currently using: $LOCATION)"
    echo "   Popular alternatives: West US 2, West Europe, Southeast Asia"
    echo ""
    echo "💡 RECOMMENDED ACTIONS:"
    echo "   1. Check your subscription quota in Azure portal"
    echo "   2. Try a different region by editing this script"
    echo "   3. Use the command-line version: cd ../../ && ./analyze.sh"
    echo ""
    exit 1
fi

WEB_APP_NAME=$(echo $DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.webAppName.value')
WEB_APP_URL=$(echo $DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.webAppUrl.value')
PRINCIPAL_ID=$(echo $DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.managedIdentityPrincipalId.value')

echo "✅ App Service deployed"
echo "   App Name: $WEB_APP_NAME"
echo "   URL: $WEB_APP_URL"
echo "   Managed Identity: $PRINCIPAL_ID"

# Assign Reader role to the managed identity for the subscription
echo "🔷 Configuring permissions..."
az role assignment create \
    --assignee $PRINCIPAL_ID \
    --role "Reader" \
    --scope "/subscriptions/$SUBSCRIPTION_ID" \
    --output none

echo "✅ Permissions configured (Reader access to subscription)"

# Deploy the application code
echo "🔷 Deploying application code..."
cd ../..
zip -r webapp.zip webapp/ --exclude="webapp/__pycache__/*" "webapp/*.pyc" "webapp/deploy/*"

az webapp deploy \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME \
    --src-path webapp.zip \
    --type zip \
    --output none

rm webapp.zip
cd webapp/deploy
echo "✅ Application code deployed"

# Configure app settings
echo "🔷 Configuring application settings..."
az webapp config appsettings set \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME \
    --settings \
        AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID \
        FLASK_ENV=production \
        PYTHONPATH=/home/site/wwwroot \
    --output none

echo "✅ Application settings configured"

# Restart the app
echo "🔷 Restarting application..."
az webapp restart \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME \
    --output none

echo "✅ Application restarted"

echo
echo "🎉 Deployment Complete!"
echo "=================================================="
echo "✅ Your Azure Resource Discovery web app is ready!"
echo
echo "🌐 Access your app at: $WEB_APP_URL"
echo "📊 Use the web interface to analyze your Azure resources"
echo "🔐 The app uses Managed Identity for secure Azure access"
echo
echo "💡 Next steps:"
echo "   1. Visit $WEB_APP_URL"
echo "   2. Start a new analysis"
echo "   3. View your Azure resources and AWS cost estimates"
echo
echo "🛠️  Management commands:"
echo "   View logs: az webapp log tail --resource-group $RESOURCE_GROUP --name $WEB_APP_NAME"
echo "   Scale up:  az appservice plan update --resource-group $RESOURCE_GROUP --name ${WEB_APP_NAME}-plan --sku B2"
echo "   Delete:    az group delete --name $RESOURCE_GROUP --yes"
echo