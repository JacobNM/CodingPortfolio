# Azure Database Inventory Script

This script collects comprehensive database information across all your accessible Azure subscriptions and can optionally update a Google Sheet with the data.

## Supported Database Types

- **MySQL Flexible Server** - Storage, backup retention, high availability, replication status
- **PostgreSQL Flexible Server** - Storage, backup retention, high availability, replication status  
- **Cosmos DB** - Consistency level, backup policy, multi-region write status
- **Azure SQL Database** - Edition, storage size, backup information
- **Redis Cache** - Version, connection details

## Features

- **Multi-subscription support** - Automatically discovers and processes all accessible subscriptions
- **Flexible output options** - Console table or CSV file
- **Google Sheets integration** - Direct upload to Google Sheets with selective updates
- **Comprehensive data** - Connection strings, tags, configuration details
- **Progress tracking** - Visual progress indicators and detailed logging
- **Error handling** - Graceful handling of permissions and API issues

## Quick Start

### Interactive Mode
```bash
./update_gsheet_azure_database_inventory.sh
```

### Save to CSV File
```bash
./update_gsheet_azure_database_inventory.sh -f my_database_inventory.csv
```

### Console Output Only
```bash
./update_gsheet_azure_database_inventory.sh -c
```

### Update Google Sheet Directly
```bash
./update_gsheet_azure_database_inventory.sh -g "YOUR_SPREADSHEET_ID" -s "Database Inventory"
```

## Command Line Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-f, --file FILENAME` | Specify output CSV filename |
| `-c, --console` | Output to console only (no CSV file) |
| `-v, --verbose` | Show detailed progress messages |
| `-g, --gsheet ID` | Google Sheets spreadsheet ID |
| `-s, --sheet NAME` | Google Sheets sheet name |
| `--no-gsheet` | Skip Google Sheets update |

## CSV Output Format

The script generates a CSV with the following columns:

| Column | Description |
|--------|-------------|
| ResourceType | MySQL, PostgreSQL, CosmosDB, SQLDB, Redis |
| Name | Database/server name |
| ResourceGroup | Azure resource group |
| Subscription | Azure subscription name |
| Location | Azure region |
| SKU | Pricing tier/service level |
| Status | Current operational status |
| Version | Database version |
| Storage | Storage size and configuration |
| Backup | Backup retention and settings |
| HighAvailability | HA configuration |
| Replication | Replication status |
| ConnectionString | FQDN or connection endpoint |
| Tags | Resource tags (key=value pairs) |

## Google Sheets Integration

### Prerequisites
1. **Service Account (Recommended)**:
   - Follow the existing `service_account_setup.md` guide
   - Place `service-account-key.json` in the script directory
   - Share your Google Sheet with the service account email

2. **OAuth (Alternative)**:
   - Use existing OAuth setup from the VM/VMSS script
   - Browser authentication required

### Setting Up a New Sheet

1. Create a new Google Sheet or use an existing one
2. Copy the Spreadsheet ID from the URL:
   ```
   https://docs.google.com/spreadsheets/d/[SPREADSHEET_ID]/edit
   ```
3. If using service account, share the sheet with the service account email
4. Run the script with the `-g` option

## Example Workflows

### Daily Database Inventory
```bash
# Generate daily inventory and update Google Sheet
./update_gsheet_azure_database_inventory.sh \
  -f "database_inventory_$(date +%Y%m%d).csv" \
  -g "1ABC...XYZ" \
  -s "Daily DB Inventory"
```

### Quick Console Review
```bash
# Quick overview in console (no files created)
./update_gsheet_azure_database_inventory.sh -c -v
```

### Backup to Multiple Formats
```bash
# Save to CSV and update Google Sheet
./update_gsheet_azure_database_inventory.sh \
  -f "db_backup_$(date +%Y%m%d_%H%M).csv" \
  -g "YOUR_SPREADSHEET_ID"
```

## Data Collection Details

### MySQL/PostgreSQL Flexible Servers
- Server state and version
- Storage size in GB
- Backup retention period in days
- High availability mode
- Replication role
- Fully qualified domain name

### Cosmos DB
- Account kind (SQL, MongoDB, etc.)
- Provisioning state
- Default consistency level
- Backup policy type
- Multi-region write status
- Document endpoint

### SQL Databases
- Server and database name
- SKU/Edition information
- Database status
- Storage size
- Earliest restore date
- Connection server FQDN

### Redis Cache
- Provisioning state
- Redis version
- Port configuration
- Host name for connections

## Troubleshooting

### Common Issues

1. **No databases found**: Verify you have proper permissions on subscriptions
2. **jq not found**: Install jq (`brew install jq` on macOS)
3. **Google Sheets error**: Check service account permissions or OAuth setup
4. **Permission denied**: Ensure script is executable (`chmod +x script.sh`)

### Debug Mode
Run with verbose flag to see detailed processing:
```bash
./update_gsheet_azure_database_inventory.sh -c -v
```

### Validation
Use the existing validation script to test Google Sheets integration:
```bash
python3 validate_service_account_setup.py
```

## Integration with Existing Tools

This script uses the same Google Sheets integration as the VM/VMSS inventory script:
- Same service account setup
- Same Python dependencies
- Compatible with existing authentication methods

You can use both scripts with the same Google Sheets configuration by targeting different sheet names in the same spreadsheet.

## Performance Notes

- Processing time depends on number of subscriptions and resources
- Large environments may take several minutes
- Console mode is faster than CSV generation
- Google Sheets updates use selective updating (only changed values)

## Security Considerations

- Script only reads database metadata, not actual data
- Service account should have minimal required permissions
- Connection strings show FQDNs only, not credentials
- CSV files may contain sensitive configuration information