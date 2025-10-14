#!/bin/bash

# Azure VM and VMSS Inventory Script
# This script collects VM and VMSS information across all accessible Azure subscriptions
# and outputs the data to a CSV file

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
    echo "azure_vm_vmss_inventory_$(get_timestamp).csv"
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
        echo "ResourceType,Name,ResourceGroup,Subscription,SubscriptionId,Location,SKU,Capacity,PowerState,OsType" > "$OUTPUT_FILE"
        print_success "Initialized CSV file: $OUTPUT_FILE"
    else
        # Initialize table format for console output
        printf "\n%-12s %-25s %-25s %-20s %-38s %-15s %-18s %-8s %-12s %-8s\n" \
            "Type" "Name" "Resource Group" "Subscription" "Subscription ID" "Location" "SKU" "Capacity" "Power State" "OS Type"
        printf "%-12s %-25s %-25s %-20s %-38s %-15s %-18s %-8s %-12s %-8s\n" \
            "============" "=========================" "=========================" "====================" "======================================" "===============" "==================" "========" "============" "========"
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
    local rg="${FIELDS[2]:0:24}"
    local sub="${FIELDS[3]:0:19}"
    local sub_id="${FIELDS[4]:0:37}"
    local location="${FIELDS[5]:0:14}"
    local sku="${FIELDS[6]:0:17}"
    local capacity="${FIELDS[7]:0:7}"
    local power="${FIELDS[8]:0:11}"
    local os="${FIELDS[9]:0:7}"
    
    printf "%-12s %-25s %-25s %-20s %-38s %-15s %-18s %-8s %-12s %-8s\n" \
        "${FIELDS[0]}" "$name" "$rg" "$sub" "$sub_id" "$location" "$sku" "$capacity" "$power" "$os"
}

# Function to get VM data for a subscription
get_vm_data() {
    local subscription_id="$1"
    local subscription_name="$2"
    
    # Show progress for CSV mode or when verbose
    if [[ "$OUTPUT_MODE" == "csv" ]] || [[ "$SHOW_STATUS" == "true" ]]; then
        print_status "Collecting VM data for subscription: $subscription_name"
    fi
    
    # Query for VMs with instance view to get power state
    local vm_query='
    Resources
    | where type =~ "Microsoft.Compute/virtualMachines"
    | extend powerState = properties.extended.instanceView.statuses[1].displayStatus
    | extend osType = case(
        properties.storageProfile.osDisk.osType == "Windows", "Windows",
        properties.storageProfile.osDisk.osType == "Linux", "Linux",
        "Unknown"
    )
    | project 
        name,
        resourceGroup,
        location,
        vmSize = properties.hardwareProfile.vmSize,
        powerState = coalesce(powerState, "Unknown"),
        osType,
        subscriptionId
    '
    
    # Execute query and process results
    local vm_data
    vm_data=$(az graph query -q "$vm_query" --subscriptions "$subscription_id" --output json 2>/dev/null || echo "[]")
    
    if [[ "$vm_data" != "[]" ]] && [[ -n "$vm_data" ]]; then
        echo "$vm_data" | jq -r --arg sub_name "$subscription_name" '
        .data[] | 
        "VM," + .name + "," + .resourceGroup + "," + $sub_name + "," + .subscriptionId + "," + .location + "," + .vmSize + ",," + .powerState + "," + .osType
        ' | while IFS= read -r line; do
            append_to_output "$line"
        done
    fi
}

# Function to get VMSS data for a subscription
get_vmss_data() {
    local subscription_id="$1"
    local subscription_name="$2"
    
    # Show progress for CSV mode or when verbose
    if [[ "$OUTPUT_MODE" == "csv" ]] || [[ "$SHOW_STATUS" == "true" ]]; then
        print_status "Collecting VMSS data for subscription: $subscription_name"
    fi
    
    # Query for VMSS
    local vmss_query='
    Resources
    | where type =~ "Microsoft.Compute/virtualMachineScaleSets"
    | project 
        name,
        resourceGroup,
        location,
        capacity = sku.capacity,
        vmSize = sku.name,
        provisioningState = properties.provisioningState,
        subscriptionId
    '
    
    # Execute query and process results
    local vmss_data
    vmss_data=$(az graph query -q "$vmss_query" --subscriptions "$subscription_id" --output json 2>/dev/null || echo "[]")
    
    if [[ "$vmss_data" != "[]" ]] && [[ -n "$vmss_data" ]]; then
        echo "$vmss_data" | jq -r --arg sub_name "$subscription_name" '
        .data[] | 
        "VMSS," + .name + "," + .resourceGroup + "," + $sub_name + "," + .subscriptionId + "," + .location + "," + .vmSize + "," + (.capacity | tostring) + "," + .provisioningState + ","
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
    
    local vm_count=0
    local vmss_count=0
    local COLLECTED_DATA=""
    
    # Show progress indicator for console mode without verbose
    if [[ "$OUTPUT_MODE" == "console" ]] && [[ "$SHOW_STATUS" != "true" ]]; then
        echo -n "Collecting data"
    fi
    
    # Create temporary file for console mode data collection
    local temp_file=""
    if [[ "$OUTPUT_MODE" == "console" ]] && [[ "$SHOW_STATUS" != "true" ]]; then
        temp_file=$(mktemp)
    fi
    
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
        
        # Get VM data
        get_vm_data "$sub_id" "$sub_name"
        
        # Get VMSS data
        get_vmss_data "$sub_id" "$sub_name"
        
    done
    
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
        local vm_lines
        vm_lines=$(grep -c "^VM," "$OUTPUT_FILE" 2>/dev/null || echo "0")
        local vmss_lines
        vmss_lines=$(grep -c "^VMSS," "$OUTPUT_FILE" 2>/dev/null || echo "0")
        
        print_success "Inventory complete!"
        print_success "Total resources: $total_lines (VMs: $vm_lines, VMSS: $vmss_lines)"
        print_success "Results saved to: $OUTPUT_FILE"
    else
        echo
        print_success "Inventory complete! Results displayed in table format above."
        print_success "Processed $active_subs subscription(s)"
    fi
}

# Function to display help
show_help() {
    echo "Azure VM and VMSS Inventory Script"
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -f, --file FILENAME     Specify output CSV filename"
    echo "  -c, --console           Output to console only (no CSV file)"
    echo "  -v, --verbose           Show detailed progress messages"
    echo
    echo "Examples:"
    echo "  $0                                    # Interactive mode"
    echo "  $0 -f my_inventory.csv               # Save to specific file"
    echo "  $0 -c                                # Console table output (clean)"
    echo "  $0 -c -v                             # Console table with progress messages"
    echo
    echo "The script will collect VM and VMSS information from all accessible"
    echo "Azure subscriptions. Output is formatted as a table for console display"
    echo "or CSV format when saving to a file."
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
    echo "Azure VM and VMSS Inventory Script"
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
    
    # Collect the data
    collect_data
    
    echo
    print_success "Script completed successfully!"
}

# Run main function with all arguments
main "$@"