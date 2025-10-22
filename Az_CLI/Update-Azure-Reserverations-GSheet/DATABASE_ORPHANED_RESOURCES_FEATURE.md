# Orphaned Database Resource Detection

## Overview

The Azure Database Inventory Script now includes **orphaned resource detection** specifically for database resources. This feature identifies database resources in your Google Sheet that no longer exist in your Azure environment and offers to clean them up automatically.

## Supported Database Types

The orphaned resource detection works with all supported database types:

- **MySQL Flexible Server**
- **PostgreSQL Flexible Server**
- **Cosmos DB**
- **Azure SQL Database**
- **Redis Cache**

## How It Works for Databases

### Resource Matching

- **CSV (Azure Data)**: Uses the `Name` column to identify database resources
- **Google Sheet**: Uses the `Group` column to identify database resources  
- **Comparison**: Case-insensitive exact matching between these columns

### Detection Process

When the database script runs with Google Sheets integration, it:

1. **Collects** all database resource names from the current Azure CSV export
2. **Compares** them with the `Group` column values in your Google Sheet
3. **Identifies** any Google Sheet rows for databases that don't exist in Azure
4. **Reports** these as "orphaned database resources"

### Interactive Database Cleanup

When orphaned database resources are found, the script:

1. **Lists** all orphaned databases with details (name, type, subscription, SKU, status)
2. **Explains** possible reasons (deleted, migrated, access revoked, renamed)
3. **Prompts** for user confirmation before deletion
4. **Provides** options: `y` (delete), `n` (skip), or `list` (show details)

## Example Database Scenarios

### Scenario 1: Database Migration

```
ORPHANED RESOURCES DETECTED
============================================================
Found 2 database resources in your Google Sheet that no longer exist in Azure:

 1. Name: old-mysql-server
    Type: MySQL
    Subscription: Vantage-Production

 2. Name: legacy-cosmos-db
    Type: CosmosDB
    Subscription: Vantage-Staging

These resources are no longer found in your Azure environment.
This could mean they were:
  - Deleted from Azure
  - Migrated to a different subscription
  - Renamed during a migration
  - Access was revoked

Do you want to DELETE these rows from the Google Sheet? (y/n/list):
```

### Common Database Use Cases

#### 🗃️ **MySQL/PostgreSQL Flexible Server Cleanup**

- Detect old single-server instances after migration to flexible server
- Clean up development/testing databases that were deleted
- Remove databases from decommissioned projects

#### 🌐 **Cosmos DB Management**  

- Track Cosmos DB accounts that were consolidated
- Remove databases that were migrated to other accounts
- Clean up development Cosmos DB instances

#### 💾 **Redis Cache Monitoring**

- Detect Redis instances that were scaled down or removed
- Track caches that were migrated to different tiers
- Remove development Redis instances

#### 🗄️ **Azure SQL Database Tracking**

- Clean up databases that were migrated to Managed Instance
- Remove development/test databases
- Track databases moved between resource groups

## Database-Specific Benefits

### 💰 **Cost Management**

- Accurate cost reporting by removing stale database entries
- Better budget planning with current database inventory
- Identify cost savings opportunities from removed resources

### 🔐 **Security Compliance**  

- Maintain accurate access control records
- Track database security configurations
- Ensure compliance documentation is current

### 📊 **Capacity Planning**

- Accurate storage and compute capacity tracking
- Better performance monitoring with current data
- Improved scaling decisions based on actual usage

### 🔄 **Backup & Recovery Planning**

- Current backup policy tracking
- Accurate disaster recovery planning
- Remove obsolete backup configurations

## Database CSV Structure

The database inventory uses this CSV structure for orphaned resource detection:

```csv
ResourceType,Name,ResourceGroup,Subscription,Location,SKU,Status,Version,Storage,Backup,HighAvailability,Replication,ConnectionString,Tags
MySQL,prod-mysql-01,databases,Vantage-Prod,canadacentral,Standard_E4ds_v5,Ready,8.0.21,512GB,35 days,ZoneRedundant,Primary,prod-mysql-01.mysql.database.azure.com,env=prod
PostgreSQL,app-postgres-db,applications,Vantage-Prod,canadacentral,Standard_D4s_v3,Ready,13,256GB,14 days,Disabled,Primary,app-postgres-db.postgres.database.azure.com,env=prod
CosmosDB,analytics-cosmos,analytics,Vantage-Prod,canadacentral,Standard,Ready,N/A,Unlimited,Continuous,GlobalDistribution,Primary,analytics-cosmos.documents.azure.com,env=prod
```

### Key Identification Column

- **`Name`**: The database resource name used for matching with Google Sheet `Group` column

## Usage Examples

### Basic Usage with Database Detection

```bash
# Run database inventory with orphaned resource detection
./update_gsheet_azure_database_inventory.sh -g YOUR_SHEET_ID -s "Database Inventory"
```

### Batch Processing

```bash
# Process multiple database subscriptions and clean up automatically
./update_gsheet_azure_database_inventory.sh -g YOUR_SHEET_ID --verbose
```

### Safe Dry Run

```bash
# Generate CSV first, then manually review before updating Google Sheet
./update_gsheet_azure_database_inventory.sh -f database_review.csv
# Review the CSV, then run with Google Sheets update
./update_gsheet_azure_database_inventory.sh -g YOUR_SHEET_ID
```

## Safety Features for Databases

### 🛡️ **Database-Safe Operations**

- **Connection String Protection**: Never deletes rows with active connection strings
- **Production Database Warnings**: Extra prompts for production-tagged resources
- **Backup Validation**: Checks backup retention settings before suggesting deletion
- **Dependency Checking**: Warns about databases with replication relationships

### 📝 **Audit Trail**

- All database deletion actions are logged with timestamps
- Includes database type, SKU, and subscription information
- Tracks which databases were removed and why

### ⚡ **Performance Considerations**

- Efficient batch processing for large database inventories
- Minimal API calls to avoid rate limiting
- Optimized for environments with many database resources

## Integration Notes

### Works with Existing Workflows

- Compatible with existing database monitoring processes
- Integrates with backup and recovery procedures  
- Supports existing tagging and categorization schemes

### Multi-Subscription Support

- Processes databases across all accessible subscriptions
- Maintains subscription-level tracking in Google Sheets
- Handles cross-subscription database migrations

## Troubleshooting Database-Specific Issues

### Connection String Mismatches

If connection strings don't match between Azure and Google Sheets:

- Check for DNS name changes
- Verify SSL certificate updates
- Confirm connection string format consistency

### Database Version Tracking

For version-related orphan detection issues:

- Ensure version numbers are consistently formatted
- Check for automatic version updates in Azure
- Verify version tracking in your Google Sheet

### Flexible Server Migration

When migrating from single server to flexible server:

- Expect old single-server entries to appear as orphaned
- Confirm migration completion before deleting old entries
- Maintain backup of old configuration data

This enhanced database inventory script provides comprehensive orphaned resource detection specifically tailored for database resource management, helping maintain accurate and current database inventories across your Azure environment.
