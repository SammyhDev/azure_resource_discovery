# Dynamic Pricing System

The Azure Resource Discovery analyzer now features a **real-time dynamic pricing system** that ensures you always get the most current cost estimates.

## 🚀 How It Works

### Real-Time API Integration
- **Azure Pricing API**: Fetches live pricing from `https://prices.azure.com/api/retail/prices`
- **AWS Pricing**: Uses verified current rates with periodic updates
- **Smart Caching**: 6-hour cache for performance while maintaining accuracy

### Automatic Updates Every Run
Every time you run the analyzer, it:
1. ✅ Checks cache validity (6-hour window)
2. 🔄 Fetches latest pricing if cache expired
3. 💾 Updates local cache with new rates
4. 📊 Uses fresh data for cost calculations

### Comprehensive Coverage
- **349+ Azure VM SKUs**: Complete VM pricing coverage
- **All Storage Tiers**: Hot, Cool, Archive pricing
- **SQL Database Tiers**: From Basic to Premium
- **App Service Plans**: All service levels

## 📈 Pricing Accuracy

### Before Dynamic Pricing
- Static pricing data from specific dates
- Manual updates required
- Risk of outdated cost estimates

### After Dynamic Pricing  
- ✅ **Live Data**: Always current pricing
- ✅ **Auto-Updates**: No manual intervention needed
- ✅ **Fallback Protection**: Verified rates if API fails
- ✅ **Performance**: Smart caching prevents delays

## 🔧 Technical Implementation

### Cache Management
```bash
# Cache location
/tmp/azure_aws_pricing/
├── azure_pricing.json  # Live Azure pricing data
└── aws_pricing.json    # AWS pricing data
```

### API Integration
```python
# Azure Retail Prices API
url = "https://prices.azure.com/api/retail/prices"
params = {
    'api-version': '2023-01-01-preview',
    '$filter': "serviceName eq 'Virtual Machines' and armRegionName eq 'eastus'",
    '$top': 100
}
```

### Fallback System
If API calls fail, the system automatically uses verified fallback pricing to ensure the analyzer never breaks.

## 💡 Benefits for Users

1. **Always Current**: Pricing reflects latest market rates
2. **Zero Maintenance**: No manual updates required  
3. **Regional Accuracy**: Supports multiple Azure regions
4. **Performance**: Fast execution with smart caching
5. **Reliability**: Fallback ensures it always works

## 🎯 Example Output

```bash
💰 Fetching current pricing...
✅ Updated Azure VM pricing: 349 SKUs
✅ Updated Azure Storage pricing
✅ Using cached AWS pricing
```

This ensures your cost comparisons are always based on the most current market rates!