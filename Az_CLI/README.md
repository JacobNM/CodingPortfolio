# Azure VM/VMSS Inventory with Google Sheets Integration

This directory contains scripts for collecting Azure Virtual Machine (VM) and Virtual Machine Scale Set (VMSS) inventory data, including autoscaling configurations, and optionally updating Google Sheets with the collected data.

## Features

- **Comprehensive Data Collection**: Collects VM and VMSS information across all accessible Azure subscriptions
- **Autoscaling Information**: For VMSS resources, retrieves current, minimum, and maximum capacity settings
- **Multiple Output Formats**: Console table display or CSV file output
- **Google Sheets Integration**: Automatically update Google Sheets with collected data
- **Flexible Configuration**: Command-line options or interactive mode

## Prerequisites

- Azure CLI (`az`)
- `jq` (JSON processor)
- Python 3.7+ (for Google Sheets integration)
- Google API credentials (for Google Sheets integration)

## Quick Start

1. **Setup Environment**:
   ```bash
   ./setup.sh
   ```

2. **Login to Azure**:
   ```bash
   az login
   ```

3. **Run Inventory**:
   ```bash
   # Interactive mode (prompts for options)
   ./update_gsheet_with_azure_vm_vmss_inventory.sh
   
   # Console output only
   ./update_gsheet_with_azure_vm_vmss_inventory.sh -c
   
   # Save to CSV file
   ./update_gsheet_with_azure_vm_vmss_inventory.sh -f my_inventory.csv
   
   # Update Google Sheet
   ./update_gsheet_with_azure_vm_vmss_inventory.sh -g "YOUR_SPREADSHEET_ID" -s "Azure Inventory"
   ```

## Data Collected

The script collects the following information for each resource:

### Virtual Machines (VMs)
- Resource Type: `VM`
- Name
- Resource Group
- Subscription
- Location
- SKU (VM Size)
- Power State
- OS Type
- Capacity: N/A (single instance)
- Autoscaling: N/A (not applicable)

### Virtual Machine Scale Sets (VMSS)
- Resource Type: `VMSS`
- Name
- Resource Group
- Subscription
- Location
- SKU (VM Size)
- Current Capacity
- Provisioning State
- Autoscaling Configuration:
  - Enabled/Disabled status
  - Minimum capacity
  - Maximum capacity
  - Default capacity

## Google Sheets Integration

### Initial Setup

1. **Create Google Cloud Project**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing one

2. **Enable Google Sheets API**:
   - Navigate to "APIs & Services" > "Library"
   - Search for "Google Sheets API" and enable it

3. **Create Credentials**:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth 2.0 Client IDs"
   - Choose "Desktop Application"
   - Download the JSON file and save as `credentials.json` in this directory

4. **Prepare Google Sheet**:
   - Create a new Google Sheet or use existing one
   - Note the spreadsheet ID from the URL: 
     `https://docs.google.com/spreadsheets/d/[SPREADSHEET_ID]/edit`

### Usage Examples

```bash
# Update specific Google Sheet
./update_gsheet_with_azure_vm_vmss_inventory.sh \
  -g "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms" \
  -s "Azure VM Inventory"

# Save CSV and update Google Sheet
./update_gsheet_with_azure_vm_vmss_inventory.sh \
  -f "azure_inventory_$(date +%Y%m%d).csv" \
  -g "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms"

# Skip Google Sheets update
./update_gsheet_with_azure_vm_vmss_inventory.sh --no-gsheet -f data.csv
```

## Command Line Options

```
Usage: ./update_gsheet_with_azure_vm_vmss_inventory.sh [OPTIONS]

Options:
  -h, --help              Show help message
  -f, --file FILENAME     Specify output CSV filename
  -c, --console           Output to console only (no CSV file)
  -v, --verbose           Show detailed progress messages
  -g, --gsheet ID         Google Sheets spreadsheet ID
  -s, --sheet NAME        Google Sheets sheet name [Azure Inventory]
  --no-gsheet             Skip Google Sheets update

Examples:
  ./update_gsheet_with_azure_vm_vmss_inventory.sh                    # Interactive mode
  ./update_gsheet_with_azure_vm_vmss_inventory.sh -c                # Console output
  ./update_gsheet_with_azure_vm_vmss_inventory.sh -f inventory.csv  # Save to CSV
  ./update_gsheet_with_azure_vm_vmss_inventory.sh -g ID -s "Sheet"  # Update Google Sheet
```

## Output Format

### CSV Columns
| Column | Description |
|--------|-------------|
| ResourceType | VM or VMSS |
| Name | Resource name |
| ResourceGroup | Azure resource group |
| Subscription | Azure subscription name |
| Location | Azure region |
| SKU | VM size (e.g., Standard_D2s_v3) |
| Capacity | Current instance count (VMSS only) |
| PowerState | VM power state (VMs only) |
| OsType | Operating system type |
| AutoscaleEnabled | Autoscaling enabled (VMSS only) |
| AutoscaleMinCapacity | Minimum instances (VMSS only) |
| AutoscaleMaxCapacity | Maximum instances (VMSS only) |
| AutoscaleDefaultCapacity | Default instances (VMSS only) |

### Sample Output
```
ResourceType,Name,ResourceGroup,Subscription,Location,SKU,Capacity,PowerState,OsType,AutoscaleEnabled,AutoscaleMinCapacity,AutoscaleMaxCapacity,AutoscaleDefaultCapacity
VM,web-server-01,prod-rg,Production,eastus,Standard_D2s_v3,,VM running,Linux,N/A,N/A,N/A,N/A
VMSS,api-scale-set,prod-rg,Production,eastus,Standard_B2s,3,Succeeded,,true,2,10,3
```

## Files

- `update_gsheet_with_azure_vm_vmss_inventory.sh` - Main inventory script with Google Sheets integration
- `update_gsheet.py` - Python script for Google Sheets API operations
- `setup.sh` - Environment setup and dependency installation
- `requirements.txt` - Python dependencies for Google Sheets integration
- `credentials.json` - Google API credentials (user-provided)
- `token.json` - Google API token cache (auto-generated)

## Troubleshooting

### Azure Authentication Issues
```bash
# Re-authenticate with Azure
az login --use-device-code

# Check current subscription
az account show

# List available subscriptions
az account list --output table
```

### Google Sheets Authentication Issues
```bash
# Remove cached token to force re-authentication
rm token.json

# Test Google Sheets connection manually
python3 update_gsheet.py --help
```

### Permission Issues
- Ensure you have at least Reader permissions on Azure subscriptions
- Verify Google Sheets API is enabled in your Google Cloud project
- Check that you have edit permissions on the target Google Sheet

### Common Error Messages

**"No accessible subscriptions found"**
- Run `az login` to authenticate
- Check subscription permissions with `az account list`

**"Google Sheets API quota exceeded"**
- Google Sheets API has rate limits
- Wait and retry, or reduce frequency of updates

**"Spreadsheet not found"**
- Verify the spreadsheet ID is correct
- Ensure the Google Sheet exists and is accessible
- Check sharing permissions on the Google Sheet

## Performance Notes

- The script uses Azure Resource Graph queries for efficient data collection
- Large environments may take several minutes to complete
- Google Sheets API has rate limits (100 requests per 100 seconds per user)
- Consider running during off-peak hours for large inventories

## Security Considerations

- Store `credentials.json` securely and do not commit to version control
- The `token.json` file contains access tokens - treat as sensitive
- Use service accounts for production/automated scenarios
- Consider using Azure Key Vault for credential storage in enterprise environments
