# Orphaned Resource Detection Feature

## Overview

The enhanced Azure VM/VMSS inventory script now includes **orphaned resource detection** - a feature that identifies resources in your Google Sheet that no longer exist in your Azure environment and offers to clean them up automatically.

## How It Works

### Resource Matching
- **CSV (Azure Data)**: Uses the `Name` column to identify resources
- **Google Sheet**: Uses the `Group` column to identify resources
- **Comparison**: Case-insensitive exact matching between these columns

### Detection Process
When the script runs, it:

1. **Collects** all resource names from the current Azure CSV export
2. **Compares** them with the `Group` column values in your Google Sheet
3. **Identifies** any Google Sheet rows that don't have matching resources in Azure
4. **Reports** these as "orphaned resources"

### Interactive Cleanup
When orphaned resources are found, the script:

1. **Lists** all orphaned resources with details (name, type, subscription)
2. **Explains** possible reasons (deleted, moved, renamed, access revoked)
3. **Prompts** for user confirmation before deletion
4. **Provides** options: `y` (delete), `n` (skip), or `list` (show details)

## Example Output

```
ORPHANED RESOURCES DETECTED
============================================================
Found 3 resources in your Google Sheet that no longer exist in Azure:

 1. Name: old-test-vm
    Type: VM
    Subscription: Vantage-Production

 2. Name: deprecated-vmss
    Type: VMSS
    Subscription: Vantage-Staging

 3. Name: temp-database
    Type: Unknown
    Subscription: Unknown

These resources are no longer found in your Azure environment.
This could mean they were:
  - Deleted from Azure
  - Moved to a different subscription
  - Renamed
  - Access was revoked

Do you want to DELETE these rows from the Google Sheet? (y/n/list):
```

## Benefits

### 🧹 **Automatic Cleanup**
- Keeps your inventory sheet clean and current
- Removes stale data without manual intervention
- Prevents confusion from outdated resource listings

### 🔍 **Data Integrity**
- Ensures your Google Sheet reflects actual Azure state
- Helps identify resources that may have been accidentally deleted
- Maintains accurate capacity planning data

### 🛡️ **Safe Operation**
- Always prompts before deletion
- Shows exactly what will be removed
- Provides detailed logging of all actions

### 📊 **Better Reporting**
- More accurate resource counts
- Cleaner dashboard views
- Improved cost analysis accuracy

## Usage

The feature is **automatically enabled** when using the service account method:

```bash
# Standard usage - will detect and offer to clean up orphaned resources
./update_gsheet_azure_vm_vmss_inventory.sh

# With specific Google Sheet
./update_gsheet_azure_vm_vmss_inventory.sh -g YOUR_SHEET_ID -s "Azure Inventory"
```

### User Interaction Options

- **`y` or `yes`**: Delete all orphaned resources
- **`n` or `no`**: Skip deletion, keep orphaned resources
- **`list` or `l`**: Show detailed information about each orphaned resource

## Prerequisites

- Uses the **service account authentication method** (`update_gsheet_service_account.py`)
- Requires proper Google Sheets permissions (Editor access)
- Your Google Sheet must have a `Group` column for resource identification

## Column Mapping

| Purpose | CSV Column | Google Sheet Column |
|---------|------------|-------------------|
| Resource Identification | `Name` | `Group` |
| Resource Type | `ResourceType` | `Resource Type` |
| Subscription | `Subscription` | `Subscription` |

## Safety Features

1. **Confirmation Required**: Never deletes without explicit user consent
2. **Detailed Logging**: All actions are logged with timestamps
3. **Error Handling**: Graceful handling of API errors or permission issues
4. **Rollback Safe**: Deletions are performed one at a time
5. **Dry Run Option**: `list` command shows what would be deleted without action

## Common Scenarios

### Scenario 1: Planned Resource Cleanup
- You've deleted VMs/VMSS from Azure
- Script detects them as orphaned
- Confirm deletion to keep sheet current

### Scenario 2: Resource Migration
- Resources moved to different subscription
- Script shows them as orphaned
- Choose `n` if they should remain for tracking

### Scenario 3: Access Changes
- Lost access to certain subscriptions
- Resources appear orphaned but still exist
- Choose `n` to preserve data

### Scenario 4: Renamed Resources
- Resources renamed in Azure
- Old names show as orphaned, new names added
- Confirm deletion of old entries

## Troubleshooting

### "Permission denied" errors
- Ensure service account has Editor access to the Google Sheet
- Check that the sheet is properly shared

### "Sheet not found" errors  
- Verify the sheet name parameter
- Check that the sheet exists in the specified spreadsheet

### No orphaned resources detected when expected
- Verify column mapping (CSV `Name` → GSheet `Group`)
- Check for case sensitivity issues
- Ensure resources exist in both locations

## Migration Note

This feature is available in the **service account version** (`update_gsheet_service_account.py`). 

If you're using the OAuth version (`update_gsheet.py`), consider migrating to the service account method for:
- This orphaned resource detection feature
- Better selective updates (only changes differing values)
- No browser interaction required
- More reliable automation

See `QUICK_SETUP.md` for service account setup instructions.