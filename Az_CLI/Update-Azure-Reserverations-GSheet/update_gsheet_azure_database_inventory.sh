#!/bin/bash

# Azure Database Inventory Script with Google Sheets Integration
# This script collects database information across all accessible Azure subscriptions
# Includes MySQL, PostgreSQL, Cosmos DB, and other database services
# and outputs the data to a CSV file with optional Google Sheets integration

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    # Only show status messages in CSV mode or when explicitly requested
    if [[ "$OUTPUT_MODE" == "csv" ]] || [[ "$SHOW_STATUS" == "true" ]]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Azure CLI is installed and user is logged in
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if az CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        print_status "Installation guide: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    # Check if user is logged in
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure CLI. Please run 'az login' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Generate timestamp for filename
get_timestamp() {
    date +"%Y%m%d_%H%M%S"
}

# Get default output filename
get_default_filename() {
    echo "azure_database_inventory_$(get_timestamp).csv"
}

# Function to get user input for CSV output
get_output_preference() {
    local default_file=$(get_default_filename)
    
    echo
    print_status "Output Options:"
    echo "1. Save to CSV file (recommended)"
    echo "2. Display to console only"
    echo
    
    while true; do
        read -p "Choose option (1 or 2): " choice
        case $choice in
            1)
                while true; do
                    read -p "Enter CSV filename [${default_file}]: " filename
                    filename=${filename:-$default_file}
                    
                    # Check if file exists
                    if [[ -f "$filename" ]]; then
                        read -p "File '$filename' already exists. Overwrite? (y/n): " overwrite
                        case $overwrite in
                            [Yy]*)
                                export OUTPUT_FILE="$filename"
                                export OUTPUT_MODE="csv"
                                return 0
                                ;;
                            [Nn]*)
                                continue
                                ;;
                            *)
                                echo "Please answer yes or no."
                                ;;
                        esac
                    else
                        export OUTPUT_FILE="$filename"
                        export OUTPUT_MODE="csv"
                        return 0
                    fi
                done
                ;;
            2)
                export OUTPUT_MODE="console"
                return 0
                ;;
            *)
                echo "Please choose 1 or 2."
                ;;
        esac
    done
}

# Function to initialize output with headers
init_output() {
    if [[ "$OUTPUT_MODE" == "csv" ]]; then
        echo "ResourceType,Name,ResourceGroup,Subscription,Location,SKU,Status,Version,Storage,Backup,HighAvailability,Replication,ConnectionString,Tags" > "$OUTPUT_FILE"
        print_success "Initialized CSV file: $OUTPUT_FILE"
    else
        # Initialize table format for console output
        printf "\n%-8s %-25s %-20s %-20s %-12s %-15s %-12s %-10s %-10s %-8s %-8s %-12s %-30s\n" \
            "Type" "Name" "Resource Group" "Subscription" "Location" "SKU" "Status" "Version" "Storage" "Backup" "HA" "Replication" "Tags"
        printf "%-8s %-25s %-20s %-20s %-12s %-15s %-12s %-10s %-10s %-8s %-8s %-12s %-30s\n" \
            "========" "=========================" "====================" "====================" "============" "===============" "============" "==========" "==========" "========" "========" "============" "=============================="
    fi
}

# Function to append data to output
append_to_output() {
    if [[ "$OUTPUT_MODE" == "csv" ]]; then
        echo "$1" >> "$OUTPUT_FILE"
    else
        # For console mode, store data in a file to output later
        if [[ "$SHOW_STATUS" == "true" ]]; then
            # In verbose mode, output immediately
            format_table_row "$1"
        else
            # In quiet console mode, store in temp file for later display
            if [[ -n "$TEMP_DATA_FILE" ]]; then
                echo "$1" >> "$TEMP_DATA_FILE"
            else
                # Fallback to immediate display if no temp file
                format_table_row "$1"
            fi
        fi
    fi
}

# Function to format a single table row
format_table_row() {
    local csv_line="$1"
    # Parse CSV line and format as table row
    IFS=',' read -ra FIELDS <<< "$csv_line"
    # Truncate long fields for better display
    local name="${FIELDS[1]:0:24}"
    local rg="${FIELDS[2]:0:19}"
    local sub="${FIELDS[3]:0:19}"
    local location="${FIELDS[4]:0:11}"
    local sku="${FIELDS[5]:0:14}"
    local status="${FIELDS[6]:0:11}"
    local version="${FIELDS[7]:0:9}"
    local storage="${FIELDS[8]:0:9}"
    local backup="${FIELDS[9]:0:7}"
    local ha="${FIELDS[10]:0:7}"
    local replication="${FIELDS[11]:0:11}"
    local tags="${FIELDS[13]:0:29}"
    
    printf "%-8s %-25s %-20s %-20s %-12s %-15s %-12s %-10s %-10s %-8s %-8s %-12s %-30s\n" \
        "${FIELDS[0]}" "$name" "$rg" "$sub" "$location" "$sku" "$status" "$version" "$storage" "$backup" "$ha" "$replication" "$tags"
}

# Function to safely extract JSON values
safe_extract() {
    local value="$1"
    if [[ "$value" == "null" ]] || [[ -z "$value" ]]; then
        echo "N/A"
    else
        echo "$value" | tr -d '"' | tr ',' ';'
    fi
}

# Function to get MySQL Flexible Server data
get_mysql_data() {
    local subscription_id="$1"
    local subscription_name="$2"
    
    if [[ "$OUTPUT_MODE" == "csv" ]] || [[ "$SHOW_STATUS" == "true" ]]; then
        print_status "Collecting MySQL Flexible Server data for subscription: $subscription_name"
    fi
    
    # Query for MySQL Flexible Servers
    local mysql_query='
    Resources
    | where type =~ "Microsoft.DBforMySQL/flexibleServers"
    | project 
        name,
        resourceGroup,
        location,
        sku = sku.name,
        status = properties.state,
        version = properties.version,
        storage = properties.storage.storageSizeGB,
        backup = properties.backup.backupRetentionDays,
        highAvailability = properties.highAvailability.mode,
        replication = properties.replicationRole,
        fqdn = properties.fullyQualifiedDomainName,
        tags,
        subscriptionId
    '
    
    # Execute query and process results
    local mysql_data
    mysql_data=$(az graph query -q "$mysql_query" --subscriptions "$subscription_id" --output json 2>/dev/null || echo "[]")
    
    if [[ "$mysql_data" != "[]" ]] && [[ -n "$mysql_data" ]]; then
        echo "$mysql_data" | jq -r --arg sub_name "$subscription_name" '
        .data[] | 
        "MySQL," + 
        .name + "," + 
        .resourceGroup + "," + 
        $sub_name + "," + 
        .location + "," + 
        (.sku // "N/A") + "," + 
        (.status // "N/A") + "," + 
        (.version // "N/A") + "," + 
        ((.storage | tostring) + "GB") + "," + 
        ((.backup | tostring) + " days") + "," + 
        (.highAvailability // "N/A") + "," + 
        (.replication // "N/A") + "," + 
        (.fqdn // "N/A") + "," + 
        ((.tags | to_entries | map(.key + "=" + (.value | tostring)) | join(";")) // "N/A")
        ' | while IFS= read -r line; do
            append_to_output "$line"
        done
    fi
}

# Function to get PostgreSQL Flexible Server data
get_postgresql_data() {
    local subscription_id="$1"
    local subscription_name="$2"
    
    if [[ "$OUTPUT_MODE" == "csv" ]] || [[ "$SHOW_STATUS" == "true" ]]; then
        print_status "Collecting PostgreSQL Flexible Server data for subscription: $subscription_name"
    fi
    
    # Query for PostgreSQL Flexible Servers
    local postgres_query='
    Resources
    | where type =~ "Microsoft.DBforPostgreSQL/flexibleServers"
    | project 
        name,
        resourceGroup,
        location,
        sku = sku.name,
        status = properties.state,
        version = properties.version,
        storage = properties.storage.storageSizeGB,
        backup = properties.backup.backupRetentionDays,
        highAvailability = properties.highAvailability.mode,
        replication = properties.replicationRole,
        fqdn = properties.fullyQualifiedDomainName,
        tags,
        subscriptionId
    '
    
    # Execute query and process results
    local postgres_data
    postgres_data=$(az graph query -q "$postgres_query" --subscriptions "$subscription_id" --output json 2>/dev/null || echo "[]")
    
    if [[ "$postgres_data" != "[]" ]] && [[ -n "$postgres_data" ]]; then
        echo "$postgres_data" | jq -r --arg sub_name "$subscription_name" '
        .data[] | 
        "PostgreSQL," + 
        .name + "," + 
        .resourceGroup + "," + 
        $sub_name + "," + 
        .location + "," + 
        (.sku // "N/A") + "," + 
        (.status // "N/A") + "," + 
        (.version // "N/A") + "," + 
        ((.storage | tostring) + "GB") + "," + 
        ((.backup | tostring) + " days") + "," + 
        (.highAvailability // "N/A") + "," + 
        (.replication // "N/A") + "," + 
        (.fqdn // "N/A") + "," + 
        ((.tags | to_entries | map(.key + "=" + (.value | tostring)) | join(";")) // "N/A")
        ' | while IFS= read -r line; do
            append_to_output "$line"
        done
    fi
}

# Function to get Cosmos DB data
get_cosmosdb_data() {
    local subscription_id="$1"
    local subscription_name="$2"
    
    if [[ "$OUTPUT_MODE" == "csv" ]] || [[ "$SHOW_STATUS" == "true" ]]; then
        print_status "Collecting Cosmos DB data for subscription: $subscription_name"
    fi
    
    # Query for Cosmos DB accounts
    local cosmos_query='
    Resources
    | where type =~ "Microsoft.DocumentDB/databaseAccounts"
    | project 
        name,
        resourceGroup,
        location,
        kind = kind,
        status = properties.provisioningState,
        consistencyLevel = properties.consistencyPolicy.defaultConsistencyLevel,
        capabilities = properties.capabilities,
        backupPolicy = properties.backupPolicy.type,
        multiRegion = properties.enableMultipleWriteLocations,
        fqdn = properties.documentEndpoint,
        tags,
        subscriptionId
    '
    
    # Execute query and process results
    local cosmos_data
    cosmos_data=$(az graph query -q "$cosmos_query" --subscriptions "$subscription_id" --output json 2>/dev/null || echo "[]")
    
    if [[ "$cosmos_data" != "[]" ]] && [[ -n "$cosmos_data" ]]; then
        echo "$cosmos_data" | jq -r --arg sub_name "$subscription_name" '
        .data[] | 
        "CosmosDB," + 
        .name + "," + 
        .resourceGroup + "," + 
        $sub_name + "," + 
        .location + "," + 
        (.kind // "N/A") + "," + 
        (.status // "N/A") + "," + 
        (.consistencyLevel // "N/A") + "," + 
        "N/A," + 
        (.backupPolicy // "N/A") + "," + 
        (if .multiRegion then "Yes" else "No" end) + "," + 
        "N/A," + 
        (.fqdn // "N/A") + "," + 
        ((.tags | to_entries | map(.key + "=" + (.value | tostring)) | join(";")) // "N/A")
        ' | while IFS= read -r line; do
            append_to_output "$line"
        done
    fi
}

# Function to get SQL Database data
get_sqldb_data() {
    local subscription_id="$1"
    local subscription_name="$2"
    
    if [[ "$OUTPUT_MODE" == "csv" ]] || [[ "$SHOW_STATUS" == "true" ]]; then
        print_status "Collecting SQL Database data for subscription: $subscription_name"
    fi
    
    # Query for SQL Databases
    local sqldb_query='
    Resources
    | where type =~ "Microsoft.Sql/servers/databases"
    | where name != "master"
    | project 
        name,
        resourceGroup,
        location,
        sku = sku.name,
        status = properties.status,
        edition = properties.edition,
        storage = properties.maxSizeBytes,
        backup = properties.earliestRestoreDate,
        collation = properties.collation,
        serverName = tostring(split(id, "/")[8]),
        tags,
        subscriptionId
    '
    
    # Execute query and process results
    local sqldb_data
    sqldb_data=$(az graph query -q "$sqldb_query" --subscriptions "$subscription_id" --output json 2>/dev/null || echo "[]")
    
    if [[ "$sqldb_data" != "[]" ]] && [[ -n "$sqldb_data" ]]; then
        echo "$sqldb_data" | jq -r --arg sub_name "$subscription_name" '
        .data[] | 
        "SQLDB," + 
        (.serverName + "/" + .name) + "," + 
        .resourceGroup + "," + 
        $sub_name + "," + 
        .location + "," + 
        (.sku // (.edition // "N/A")) + "," + 
        (.status // "N/A") + "," + 
        (.collation // "N/A") + "," + 
        (if .storage then ((.storage | tonumber / 1024 / 1024 / 1024 | floor | tostring) + "GB") else "N/A" end) + "," + 
        (if .backup then (.backup | split("T")[0]) else "N/A" end) + "," + 
        "N/A," + 
        "N/A," + 
        (.serverName + ".database.windows.net") + "," + 
        ((.tags | to_entries | map(.key + "=" + (.value | tostring)) | join(";")) // "N/A")
        ' | while IFS= read -r line; do
            append_to_output "$line"
        done
    fi
}

# Function to get Redis Cache data
get_redis_data() {
    local subscription_id="$1"
    local subscription_name="$2"
    
    if [[ "$OUTPUT_MODE" == "csv" ]] || [[ "$SHOW_STATUS" == "true" ]]; then
        print_status "Collecting Redis Cache data for subscription: $subscription_name"
    fi
    
    # Query for Redis Cache
    local redis_query='
    Resources
    | where type =~ "Microsoft.Cache/redis"
    | project 
        name,
        resourceGroup,
        location,
        sku = sku.name,
        status = properties.provisioningState,
        version = properties.redisVersion,
        port = properties.port,
        sslPort = properties.sslPort,
        hostName = properties.hostName,
        tags,
        subscriptionId
    '
    
    # Execute query and process results
    local redis_data
    redis_data=$(az graph query -q "$redis_query" --subscriptions "$subscription_id" --output json 2>/dev/null || echo "[]")
    
    if [[ "$redis_data" != "[]" ]] && [[ -n "$redis_data" ]]; then
        echo "$redis_data" | jq -r --arg sub_name "$subscription_name" '
        .data[] | 
        "Redis," + 
        .name + "," + 
        .resourceGroup + "," + 
        $sub_name + "," + 
        .location + "," + 
        (.sku // "N/A") + "," + 
        (.status // "N/A") + "," + 
        (.version // "N/A") + "," + 
        "N/A," + 
        "N/A," + 
        "N/A," + 
        "N/A," + 
        (.hostName // "N/A") + "," + 
        ((.tags | to_entries | map(.key + "=" + (.value | tostring)) | join(";")) // "N/A")
        ' | while IFS= read -r line; do
            append_to_output "$line"
        done
    fi
}

# Main function to collect data from all subscriptions
collect_data() {
    print_status "Getting list of accessible subscriptions..."
    
    # Get all subscriptions
    local subscriptions
    subscriptions=$(az account list --output json --query '[].{id:id, name:name, state:state}' 2>/dev/null)
    
    if [[ -z "$subscriptions" ]] || [[ "$subscriptions" == "[]" ]]; then
        print_error "No accessible subscriptions found."
        exit 1
    fi
    
    # Count active subscriptions
    local active_subs
    active_subs=$(echo "$subscriptions" | jq '[.[] | select(.state == "Enabled")] | length')
    
    print_success "Found $active_subs active subscription(s)"
    
    # Initialize output for CSV mode or when verbose
    if [[ "$OUTPUT_MODE" == "csv" ]] || [[ "$SHOW_STATUS" == "true" ]]; then
        init_output
    fi
    
    # Show progress indicator for console mode without verbose
    if [[ "$OUTPUT_MODE" == "console" ]] && [[ "$SHOW_STATUS" != "true" ]]; then
        echo -n "Collecting data"
    fi
    
    # Create temporary file for console mode data collection
    local temp_file=""
    if [[ "$OUTPUT_MODE" == "console" ]] && [[ "$SHOW_STATUS" != "true" ]]; then
        temp_file=$(mktemp)
    fi
    
    # Store current subscription to restore later
    local original_subscription
    original_subscription=$(az account show --query id -o tsv 2>/dev/null || echo "")
    
    # Collect data from all subscriptions
    echo "$subscriptions" | jq -r '.[] | select(.state == "Enabled") | .id + "|" + .name' | while IFS='|' read -r sub_id sub_name; do
        # Show progress for different modes
        if [[ "$OUTPUT_MODE" == "csv" ]] || [[ "$SHOW_STATUS" == "true" ]]; then
            print_status "Processing subscription: $sub_name ($sub_id)"
        elif [[ "$OUTPUT_MODE" == "console" ]]; then
            echo -n "."
        fi
        
        # Set temp file for data collection in console mode
        if [[ "$OUTPUT_MODE" == "console" ]] && [[ "$SHOW_STATUS" != "true" ]] && [[ -n "$temp_file" ]]; then
            export TEMP_DATA_FILE="$temp_file"
        fi
        
        # Get MySQL data
        get_mysql_data "$sub_id" "$sub_name"
        
        # Get PostgreSQL data
        get_postgresql_data "$sub_id" "$sub_name"
        
        # Get Cosmos DB data
        get_cosmosdb_data "$sub_id" "$sub_name"
        
        # Get SQL Database data
        get_sqldb_data "$sub_id" "$sub_name"
        
        # Get Redis Cache data
        get_redis_data "$sub_id" "$sub_name"
        
    done
    
    # Restore original subscription context if it existed
    if [[ -n "$original_subscription" ]]; then
        az account set --subscription "$original_subscription" >/dev/null 2>&1 || true
    fi
    
    # Complete progress indicator and display table for console mode
    if [[ "$OUTPUT_MODE" == "console" ]] && [[ "$SHOW_STATUS" != "true" ]]; then
        echo " Done!"
        echo
        # Now initialize and display the table output after data collection is complete
        init_output
        
        # Display all collected data from temp file
        if [[ -n "$temp_file" ]] && [[ -f "$temp_file" ]]; then
            while IFS= read -r line; do
                if [[ -n "$line" ]]; then
                    format_table_row "$line"
                fi
            done < "$temp_file"
            # Clean up temp file
            rm -f "$temp_file"
        fi
    fi
    
    # Count results if CSV mode
    if [[ "$OUTPUT_MODE" == "csv" ]]; then
        local total_lines
        total_lines=$(($(wc -l < "$OUTPUT_FILE") - 1))  # Subtract header
        local mysql_lines
        mysql_lines=$(grep -c "^MySQL," "$OUTPUT_FILE" 2>/dev/null || echo "0")
        local postgres_lines
        postgres_lines=$(grep -c "^PostgreSQL," "$OUTPUT_FILE" 2>/dev/null || echo "0")
        local cosmos_lines
        cosmos_lines=$(grep -c "^CosmosDB," "$OUTPUT_FILE" 2>/dev/null || echo "0")
        local sqldb_lines
        sqldb_lines=$(grep -c "^SQLDB," "$OUTPUT_FILE" 2>/dev/null || echo "0")
        local redis_lines
        redis_lines=$(grep -c "^Redis," "$OUTPUT_FILE" 2>/dev/null || echo "0")
        
        print_success "Database inventory complete!"
        print_success "Total resources: $total_lines"
        print_success "  MySQL: $mysql_lines, PostgreSQL: $postgres_lines, CosmosDB: $cosmos_lines"
        print_success "  SQL Database: $sqldb_lines, Redis: $redis_lines"
        print_success "Results saved to: $OUTPUT_FILE"
    else
        echo
        print_success "Database inventory complete! Results displayed in table format above."
        print_success "Processed $active_subs subscription(s)"
    fi
}

# Function to update Google Sheet with CSV data
update_google_sheet() {
    local csv_file="$1"
    local spreadsheet_id="$2"
    local sheet_name="$3"
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local service_account_script="$script_dir/update_gsheet_service_account.py"
    local oauth_script="$script_dir/update_gsheet.py"
    local service_account_key="$script_dir/service-account-key.json"
    
    print_status "Updating Google Sheet..."
    print_status "Spreadsheet ID: $spreadsheet_id"
    print_status "Sheet Name: $sheet_name"
    
    # Prefer service account method if available
    if [[ -f "$service_account_key" ]] && [[ -f "$service_account_script" ]]; then
        print_status "Using service account authentication (no browser required)"
        print_status "Mode: Selective update (only changes differing values)"
        python3 "$service_account_script" "$csv_file" "$spreadsheet_id" --sheet-name "$sheet_name" --verbose
        return $?
    elif [[ -f "$oauth_script" ]]; then
        print_status "Using OAuth authentication (browser required)"
        print_status "Mode: Selective update (only changes differing values)"
        python3 "$oauth_script" "$csv_file" "$spreadsheet_id" --sheet-name "$sheet_name" --verbose
        return $?
    else
        print_error "No Google Sheets updater script found"
        print_status "Available methods:"
        print_status "1. Service Account: Place 'service-account-key.json' in this directory"
        print_status "2. OAuth: Run setup.sh to configure OAuth credentials"
        return 1
    fi
}

# Function to get Google Sheet configuration
get_google_sheet_config() {
    echo
    print_status "Google Sheets Integration Configuration"
    echo "=========================================="
    echo
    
    # Ask if user wants to update Google Sheets
    while true; do
        read -p "Do you want to update a Google Sheet with this data? (y/n): " update_gsheet
        case $update_gsheet in
            [Yy]*)
                break
                ;;
            [Nn]*)
                export SKIP_GSHEET_UPDATE="true"
                return 0
                ;;
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
    
    # Get spreadsheet ID
    echo
    echo "To get your Google Sheets spreadsheet ID:"
    echo "1. Open your Google Sheet in a browser"
    echo "2. Copy the ID from the URL:"
    echo "   https://docs.google.com/spreadsheets/d/[SPREADSHEET_ID]/edit"
    echo
    
    while true; do
        read -p "Enter Google Sheets spreadsheet ID: " gsheet_id
        if [[ -n "$gsheet_id" ]]; then
            export GSHEET_SPREADSHEET_ID="$gsheet_id"
            break
        else
            echo "Please enter a valid spreadsheet ID."
        fi
    done
    
    # Get sheet name (optional)
    read -p "Enter sheet name [Database Inventory]: " gsheet_name
    gsheet_name=${gsheet_name:-"Database Inventory"}
    export GSHEET_SHEET_NAME="$gsheet_name"
    
    echo
    print_success "Google Sheets configuration saved:"
    print_success "  Spreadsheet ID: $GSHEET_SPREADSHEET_ID"
    print_success "  Sheet Name: $GSHEET_SHEET_NAME"
}

# Function to display help
show_help() {
    echo "Azure Database Inventory Script with Google Sheets Integration"
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "This script collects database information from all accessible Azure subscriptions"
    echo "and optionally updates a Google Sheet with the data."
    echo "Supported database types:"
    echo "  - MySQL Flexible Server"
    echo "  - PostgreSQL Flexible Server"
    echo "  - Cosmos DB"
    echo "  - Azure SQL Database"
    echo "  - Redis Cache"
    echo
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -f, --file FILENAME     Specify output CSV filename"
    echo "  -c, --console           Output to console only (no CSV file)"
    echo "  -v, --verbose           Show detailed progress messages"
    echo "  -g, --gsheet ID         Google Sheets spreadsheet ID"
    echo "  -s, --sheet NAME        Google Sheets sheet name [Database Inventory]"
    echo "  --no-gsheet             Skip Google Sheets update"
    echo
    echo "Examples:"
    echo "  $0                                          # Interactive mode"
    echo "  $0 -f db_inventory.csv                     # Save to specific file"
    echo "  $0 -c                                      # Console table output (clean)"
    echo "  $0 -c -v                                   # Console table with progress"
    echo "  $0 -g 1ABC...XYZ -s \"DB Inventory\"        # Update specific Google Sheet"
    echo "  $0 --no-gsheet                             # Skip Google Sheets integration"
    echo
    echo "Google Sheets Setup (Service Account - Recommended):"
    echo "  1. Follow QUICK_SETUP.md (5 minutes total)"
    echo "  2. Download service-account-key.json from Google Cloud Console"
    echo "  3. Share your Google Sheet with the service account email"
    echo "  4. Run: ./validate_setup.py to test your setup"
    echo
    echo "CSV Columns:"
    echo "  ResourceType, Name, ResourceGroup, Subscription, Location,"
    echo "  SKU, Status, Version, Storage, Backup, HighAvailability, Replication,"
    echo "  ConnectionString, Tags"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--file)
                if [[ -n "$2" ]] && [[ "$2" != -* ]]; then
                    export OUTPUT_FILE="$2"
                    export OUTPUT_MODE="csv"
                    shift 2
                else
                    print_error "Option $1 requires a filename argument"
                    exit 1
                fi
                ;;
            -c|--console)
                export OUTPUT_MODE="console"
                shift
                ;;
            -v|--verbose)
                export SHOW_STATUS="true"
                shift
                ;;
            -g|--gsheet)
                if [[ -n "$2" ]] && [[ "$2" != -* ]]; then
                    export GSHEET_SPREADSHEET_ID="$2"
                    shift 2
                else
                    print_error "Option $1 requires a spreadsheet ID argument"
                    exit 1
                fi
                ;;
            -s|--sheet)
                if [[ -n "$2" ]] && [[ "$2" != -* ]]; then
                    export GSHEET_SHEET_NAME="$2"
                    shift 2
                else
                    print_error "Option $1 requires a sheet name argument"
                    exit 1
                fi
                ;;
            --no-gsheet)
                export SKIP_GSHEET_UPDATE="true"
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Main execution
main() {
    echo "============================================"
    echo "Azure Database Inventory Script"
    echo "with Google Sheets Integration"
    echo "============================================"
    echo
    
    # Parse command line arguments
    parse_args "$@"
    
    # Check prerequisites
    check_prerequisites
    
    # Check if jq is available (required for JSON processing)
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed. Please install jq:"
        print_status "macOS: brew install jq"
        print_status "Ubuntu/Debian: sudo apt-get install jq"
        print_status "CentOS/RHEL: sudo yum install jq"
        exit 1
    fi
    
    # Get output preferences if not set via command line
    if [[ -z "$OUTPUT_MODE" ]]; then
        get_output_preference
    fi
    
    # Get Google Sheets configuration if needed
    if [[ "$OUTPUT_MODE" == "csv" ]] && [[ "$SKIP_GSHEET_UPDATE" != "true" ]] && [[ -z "$GSHEET_SPREADSHEET_ID" ]]; then
        get_google_sheet_config
    fi
    
    # Collect the data
    collect_data
    
    # Update Google Sheet if configured and CSV mode
    if [[ "$OUTPUT_MODE" == "csv" ]] && [[ "$SKIP_GSHEET_UPDATE" != "true" ]] && [[ -n "$GSHEET_SPREADSHEET_ID" ]]; then
        echo
        print_status "Updating Google Sheet..."
        
        # Set default sheet name if not provided
        local sheet_name="${GSHEET_SHEET_NAME:-Database Inventory}"
        
        if update_google_sheet "$OUTPUT_FILE" "$GSHEET_SPREADSHEET_ID" "$sheet_name"; then
            print_success "Google Sheet updated successfully!"
            print_success "View at: https://docs.google.com/spreadsheets/d/$GSHEET_SPREADSHEET_ID"
        else
            print_warning "Google Sheet update failed, but CSV file was created successfully."
            print_status "You can manually upload the CSV file: $OUTPUT_FILE"
        fi
    fi
    
    echo
    print_success "Script completed successfully!"
}

# Run main function with all arguments
main "$@"