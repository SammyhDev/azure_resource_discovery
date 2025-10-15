# MACC Discount Support

The Azure Resource Discovery analyzer now supports **Microsoft Azure Consumption Commitment (MACC)** discounts for more accurate cost comparisons.

## 🎯 What is MACC?

MACC (Microsoft Azure Consumption Commitment) is a volume-based discount program where organizations commit to spending a certain amount on Azure services in exchange for percentage discounts on their consumption.

### Common MACC Scenarios:
- **Enterprise Agreements**: Negotiated volume discounts (5-30%)
- **Partner Programs**: Channel partner discounts
- **Consumption Commitments**: Annual spending commitments with tiered discounts
- **Volume Licensing**: Enterprise-wide Microsoft agreements

## 🚀 How It Works

### Interactive Setup
When you run the analyzer, you'll be asked:

```bash
💰 Microsoft Azure Consumption Commitment (MACC) Discount
=========================================================

Do you have a MACC (Microsoft Azure Consumption Commitment) agreement
that provides volume discounts on your Azure consumption?

Examples:
• Enterprise agreements with negotiated discounts  
• Volume commitment discounts (5%, 10%, 15%, etc.)
• Partner program discounts

Do you have a MACC discount? (y/n): y

📊 What percentage discount do you receive on Azure services?
   (Enter just the number, e.g., '10' for 10% discount)

Enter your MACC discount percentage (0-50): 15
```

### Automatic Application
- ✅ **Applied to All Azure Costs**: VMs, Storage, SQL, App Services
- ✅ **Transparent Calculation**: Shows both list price and discounted price
- ✅ **Accurate Comparisons**: Compares your actual Azure costs vs AWS

## 📊 Enhanced Cost Comparison

### Before MACC Support
```bash
Azure (Current):     $100.00/month
AWS (Equivalent):    $85.00/month
💰 Potential AWS Savings: $15.00/month (15.0%)
```

### After MACC Support (15% discount)
```bash
Azure (List Price):  $100.00/month
MACC Discount (15%): -$15.00/month
Azure (Your Cost):   $85.00/month
AWS (Equivalent):    $85.00/month
⚖️ Costs are very similar between Azure and AWS
```

## 🎯 Accurate Migration Decisions

### Key Benefits:
1. **Real Cost Comparison**: Uses your actual discounted Azure pricing
2. **Informed Decisions**: See true cost implications of migration
3. **ROI Analysis**: Understand if migration savings justify the effort
4. **Enterprise Planning**: Factor in existing volume commitments

### Use Cases:
- **Migration Planning**: Should you migrate with existing MACC discounts?
- **Contract Negotiation**: Compare MACC discounts vs AWS pricing
- **Hybrid Strategy**: Determine optimal cloud mix based on actual costs
- **Budget Forecasting**: Plan with accurate cost projections

## 🛠️ Command Line Usage

### Simple Analyzer
```bash
# Interactive mode (asks about MACC)
./analyze.sh

# The script will prompt for MACC discount automatically
```

### Advanced Analyzer
```bash
# Specify MACC discount directly
python3 scripts/azure_to_aws_cost_analyzer.py --macc-discount 15

# Combined with other options
python3 scripts/azure_to_aws_cost_analyzer.py --macc-discount 10 --json --output report.json
```

## 💡 Pro Tips

### Determining Your MACC Discount:
1. **Check your EA Portal**: Look for volume discount rates
2. **Review invoices**: Compare list vs actual prices
3. **Ask your account team**: Microsoft can provide discount details
4. **Partner discounts**: Check with your Microsoft partner

### When to Use MACC:
- ✅ **Enterprise customers** with volume agreements
- ✅ **Partners** with program discounts  
- ✅ **Large organizations** with consumption commitments
- ❌ **Pay-as-you-go** customers (typically no MACC discounts)

This feature ensures your cost comparisons reflect your actual Azure pricing, not just list prices!