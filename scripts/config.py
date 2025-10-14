# Configuration file for Azure to AWS Cost Analyzer
# This is a Python file that can be imported to customize pricing and mappings

# Custom Azure VM to AWS EC2 mappings
# Format: 'azure_vm_size': {'type': 'aws_instance_type', 'monthly_cost': cost_in_usd}
CUSTOM_VM_MAPPINGS = {
    'Standard_A1_v2': {'type': 't3.small', 'monthly_cost': 15.2},
    'Standard_F2s_v2': {'type': 'c5.large', 'monthly_cost': 61.3},
    'Standard_E2s_v3': {'type': 'r5.large', 'monthly_cost': 87.6},
    # Add more mappings as needed
}

# Custom storage tier mappings
CUSTOM_STORAGE_MAPPINGS = {
    'Hot': {'aws_class': 'Standard', 'cost_per_gb': 0.023},
    'Cool': {'aws_class': 'Standard-IA', 'cost_per_gb': 0.0125},
    'Archive': {'aws_class': 'Glacier', 'cost_per_gb': 0.004},
}

# Custom SQL Database mappings
CUSTOM_SQL_MAPPINGS = {
    'GP_Gen5_2': {'type': 'db.r5.large', 'monthly_cost': 140.0},
    'GP_Gen5_4': {'type': 'db.r5.xlarge', 'monthly_cost': 280.0},
    # Add more mappings as needed
}

# AWS regions and their price multipliers (compared to us-east-1)
AWS_REGION_MULTIPLIERS = {
    'us-east-1': 1.0,      # Base pricing
    'us-west-2': 1.0,      # Same as us-east-1
    'eu-west-1': 1.1,      # 10% more expensive
    'ap-southeast-1': 1.15, # 15% more expensive
    'eu-central-1': 1.12,   # 12% more expensive
}

# Default estimated usage patterns (for storage)
DEFAULT_STORAGE_GB = 100  # Assume 100GB average if actual usage unknown

# Cost estimation settings
INCLUDE_DATA_TRANSFER = False  # Set to True to add rough data transfer costs
DATA_TRANSFER_MULTIPLIER = 0.1  # 10% of compute costs as rough estimate

# Reserved Instance discounts (as multipliers)
RESERVED_INSTANCE_DISCOUNT = {
    '1_year': 0.75,   # 25% discount
    '3_year': 0.60,   # 40% discount
}

# Apply reserved instance pricing by default?
USE_RESERVED_PRICING = False
RESERVED_TERM = '1_year'  # '1_year' or '3_year'