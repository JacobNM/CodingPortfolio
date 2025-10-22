# Resource Type Synchronization Enhancement

## Overview

The Google Sheets updater now automatically **synchronizes Resource Type information** from the Azure CSV data to your Google Sheet. This ensures that your Google Sheet always reflects the current resource types from Azure.

## How It Works

### Column Mapping
- **CSV Source**: `ResourceType` column (first column in CSV)
- **Google Sheet Target**: Looks for columns named:
  - `Resource Type` (preferred)
  - `ResourceType` 
  - `Type`

### Automatic Updates
The script now updates the Resource Type column in the following scenarios:

1. **Existing Resource Updates**: When a resource exists in both CSV and Google Sheet
   - Compares current Resource Type in Google Sheet with CSV data
   - Updates if different or if Google Sheet field is empty

2. **New Resource Addition**: When adding new resources from Azure
   - Automatically populates Resource Type from CSV ResourceType column

## Supported Resource Types

The synchronization works with all supported resource types:

### VM/VMSS Inventory
- `VM` - Virtual Machines
- `VMSS` - Virtual Machine Scale Sets

### Database Inventory  
- `MySQL` - MySQL Flexible Server
- `PostgreSQL` - PostgreSQL Flexible Server
- `CosmosDB` - Cosmos DB
- `Redis` - Azure Cache for Redis
- `SQLDB` - Azure SQL Database

## Example Updates

### Resource Type Update Log
```
Updated prod-database-01 -> Resource Type: 'Database' → 'MySQL'
Updated web-app-vmss -> Resource Type: '' → 'VMSS'  
Updated cache-redis-01 -> Resource Type: 'Cache' → 'Redis'
```

### CSV to Google Sheet Mapping
| CSV ResourceType | Google Sheet Resource Type |
|------------------|----------------------------|
| MySQL | MySQL |
| PostgreSQL | PostgreSQL |
| Redis | Redis |
| VM | VM |
| VMSS | VMSS |
| CosmosDB | CosmosDB |

## Benefits

### 🎯 **Accurate Categorization**
- Ensures Google Sheet resource types match actual Azure resource types
- Prevents manual categorization errors
- Maintains consistency across inventory updates

### 📊 **Better Reporting**
- Accurate resource type filtering in Google Sheets
- Proper pivot table and chart creation based on resource types
- Consistent dashboards and analytics

### 🔄 **Automatic Synchronization**
- No manual intervention required
- Updates happen during regular inventory runs
- Handles resource type changes automatically

### 🏷️ **Standardized Types**
- Uses Azure's official resource type naming
- Consistent terminology across all resources
- Better integration with Azure documentation

## Column Detection

The script uses **flexible column detection** for maximum compatibility:

### Preferred Column Names
1. `Resource Type` (with space - recommended)
2. `ResourceType` (no space)  
3. `Type` (short form)

### Case Insensitive
- `resource type`
- `RESOURCE TYPE`
- `Resource Type`
- `resourcetype`

All variations are automatically detected and used.

## Usage Examples

### VM/VMSS Inventory
```bash
# Resource Type synchronization is automatic
./update_gsheet_azure_vm_vmss_inventory.sh -g YOUR_SHEET_ID -s "VM Inventory"
```

### Database Inventory
```bash  
# Resource Type synchronization is automatic
./update_gsheet_azure_database_inventory.sh -g YOUR_SHEET_ID -s "Database Inventory"
```

## Update Summary

When the script completes, you'll see updates like:
```
=== UPDATE SUMMARY ===
Total changes made: 15
Resources updated: 8
New resources added: 3
Orphaned resources deleted: 1

Detailed changes:
  • Updated prod-mysql-01 -> SKU: 'Standard_D4s' → 'Standard_D8s_v5'
  • Updated prod-mysql-01 -> Resource Type: 'Database' → 'MySQL'
  • Updated web-vmss -> Resource Type: '' → 'VMSS'
  • Added new resource: Redis: cache-prod-01
  • Deleted orphaned resource: old-test-vm
```

## Google Sheet Requirements

### Column Setup
Your Google Sheet should have a column for resource type detection:
- **Recommended**: `Resource Type` column header
- **Alternative**: `ResourceType` or `Type`

### Data Format
- Resource Type values will exactly match CSV ResourceType column
- Empty cells will be populated with appropriate resource types
- Existing values will be updated if they don't match CSV data

## Troubleshooting

### Resource Type Not Updating
1. **Check Column Names**: Ensure your Google Sheet has a column named `Resource Type`, `ResourceType`, or `Type`
2. **Verify Permissions**: Service account needs Editor access to the Google Sheet
3. **Column Order**: Resource Type column can be in any position

### Unexpected Resource Types  
1. **Check CSV Source**: Verify ResourceType column in generated CSV is correct
2. **Azure Resource Types**: Resource types come directly from Azure Resource Manager
3. **Case Sensitivity**: Google Sheet updates preserve exact case from CSV

### Missing Resource Type Column
If no Resource Type column is found in Google Sheet:
- Script will skip Resource Type updates
- Other updates (SKU, Subscription, etc.) will still work
- Consider adding a `Resource Type` column to your Google Sheet

## Integration Notes

### Compatible with Existing Features
- ✅ Works with orphaned resource detection
- ✅ Compatible with selective updates
- ✅ Integrates with new resource addition
- ✅ Works across all supported resource types

### Performance Impact
- ✅ Minimal additional API calls
- ✅ Efficient batch processing
- ✅ No significant performance impact

This enhancement ensures your Google Sheets inventory maintains accurate and up-to-date resource type information automatically! 🎯