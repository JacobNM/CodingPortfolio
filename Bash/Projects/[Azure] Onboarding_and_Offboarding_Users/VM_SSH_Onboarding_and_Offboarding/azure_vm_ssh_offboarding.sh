#!/bin/bash

#################################################################################
# Azure VM SSH Key Offboarding Script
# Description: Automates removing SSH keys from Azure VMs for user access
#              Removes SSH keys from the azroot account on specified VMs
#################################################################################

set -euo pipefail  # Exit on any error, undefined variable, or pipe failure

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/ssh_offboarding_$(date +%Y%m%d_%H%M%S).log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SUBSCRIPTION_ID=""
USER_NAME=""
DRY_RUN=false  # Controlled by command line only (-d flag), NOT from CSV file
VM_RESOURCE_GROUP=""
VM_NAMES=()
SSH_PUBLIC_KEY=""
REMOVE_ALL_KEYS=false
BACKUP_KEYS=true
CSV_FILE=""

#################################################################################
# Functions
#################################################################################

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Print section header with visual separator
print_section() {
    local title="$1"
    local color="${2:-$BLUE}"
    echo
    echo -e "${color}╭─────────────────────────────────────────────────────╮${NC}"
    echo -e "${color}│ $title${NC}"
    echo -e "${color}╰─────────────────────────────────────────────────────╯${NC}"
    echo
}

# Print operation status with progress indicator
print_operation_status() {
    local operation="$1"
    local status="$2" # "start", "success", "skip", "error"
    local message="${3:-}"
    
    case "$status" in
        "start")
            echo -e "${BLUE}🔄 Starting: $operation${NC}"
            if [[ -n "$message" ]]; then
                echo -e "   $message"
            fi
            ;;
        "success")
            echo -e "${GREEN}✅ Completed: $operation${NC}"
            if [[ -n "$message" ]]; then
                echo -e "   $message"
            fi
            ;;
        "skip")
            echo -e "${YELLOW}⏭️  Skipped: $operation${NC}"
            if [[ -n "$message" ]]; then
                echo -e "   $message"
            fi
            ;;
        "error")
            echo -e "${RED}❌ Failed: $operation${NC}"
            if [[ -n "$message" ]]; then
                echo -e "   $message"
            fi
            ;;
    esac
}

# Print progress indicator
print_progress() {
    local current="$1"
    local total="$2"
    local operation="$3"
    echo -e "${BLUE}[Step $current/$total] $operation${NC}"
}

# Print usage information
usage() {
    cat << EOF
Usage: $0 [COMMAND_LINE_OPTIONS | -f <csv_file>]

**FUNCTIONALITY:**
- Remove specific SSH public keys from Azure VMs (azroot account)
- Remove all SSH keys from Azure VMs (azroot account)
- Support for multiple VMs
- Automatic backup of authorized_keys before modification
- Import parameters from CSV file for batch operations

**COMMAND LINE MODE:**
Required Parameters:
    -u, --username <username>           Username for identification
    -s, --subscription <subscription_id> Azure subscription ID
    -g, --resource-group <vm_resource_group> Resource group containing VMs
    -v, --vm <vm_name>                 VM name (can be specified multiple times)

Optional Parameters:
    -k, --key <ssh_public_key>         Specific SSH public key to remove (file path or key content)
    -a, --remove-all                   Remove ALL SSH keys from azroot account
    -n, --no-backup                   No backup (skip backup of authorized_keys)
    -d, --dry-run                      Dry run mode (show what would be done)
    -h, --help                         Display this help message

**CSV FILE MODE:**
    -f, --file <csv_file>              CSV file containing offboarding parameters
                           Format: username,subscription_id,ssh_public_key,vm_resource_group,vm_names,remove_all_keys,backup_keys
                           VM names can be comma-separated within quotes
                           ssh_public_key can be empty if remove_all_keys is true
                           Boolean values should be 'true' or 'false'

Examples:
    # Command line mode - Remove specific SSH key from single VM (short options)
    $0 -u john.doe -s "12345678-1234-1234-1234-123456789012" \\
       -k ~/.ssh/id_rsa.pub -g "myvm-rg" -v "myvm01"

    # Command line mode - Remove ALL SSH keys from multiple VMs (long options)
    $0 --username jane.smith --subscription "12345678-1234-1234-1234-123456789012" \\
       --resource-group "myvm-rg" --vm "vm01" --vm "vm02" --vm "vm03" --remove-all

    # Command line mode - Dry run mode (mixed options)
    $0 -u john.doe --subscription "12345678-1234-1234-1234-123456789012" \\
       --key ~/.ssh/id_rsa.pub -g "myvm-rg" -v "myvm01" --dry-run

    # Command line mode - Remove specific key without backup (long options)
    $0 --username john.doe --subscription "12345678-1234-1234-1234-123456789012" \\
       --key ~/.ssh/id_rsa.pub --resource-group "myvm-rg" --vm "myvm01" --no-backup

    # CSV file mode - Batch processing
    $0 --file offboarding_batch.csv --dry-run

**CSV File Format Example (offboarding_batch.csv):**
username,subscription_id,ssh_public_key,vm_resource_group,vm_names,remove_all_keys,backup_keys
john.doe,12345678-1234-1234-1234-123456789012,~/.ssh/id_rsa.pub,prod-rg,"vm01,vm02",false,true
jane.smith,87654321-4321-4321-4321-210987654321,,test-rg,vm03,true,false
mike.wilson,11111111-2222-3333-4444-555555555555,"ssh-rsa AAAAB3Nz...",dev-rg,"vm04,vm05",false,true

EOF
}

# Check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        log "ERROR" "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if logged in to Azure
    if ! az account show &> /dev/null; then
        log "ERROR" "Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    log "SUCCESS" "Prerequisites check completed"
}

# Check basic VM access permissions
check_vm_permissions() {
    print_section "Checking VM Permissions"
    
    local subscription_id="$1"
    local resource_group="$2"
    
    # Set the subscription
    az account set --subscription "$subscription_id" || {
        log "ERROR" "Failed to set subscription: $subscription_id"
        exit 1
    }
    
    # Check if we can access the resource group
    if ! az group show --name "$resource_group" &> /dev/null; then
        log "ERROR" "Cannot access resource group: $resource_group"
        exit 1
    fi
    
    log "SUCCESS" "Basic VM permissions verified"
}

# Validate user input
validate_input() {
    print_section "Validating Input"
    
    if [[ -z "$USER_NAME" ]]; then
        log "ERROR" "Username is required"
        exit 1
    fi
    
    if [[ -z "$SUBSCRIPTION_ID" ]]; then
        log "ERROR" "Subscription ID is required"
        exit 1
    fi
    
    if [[ -z "$VM_RESOURCE_GROUP" ]]; then
        log "ERROR" "VM resource group is required"
        exit 1
    fi
    
    if [[ ${#VM_NAMES[@]} -eq 0 ]]; then
        log "ERROR" "At least one VM name is required"
        exit 1
    fi
    
    if [[ "$REMOVE_ALL_KEYS" == "false" && -z "$SSH_PUBLIC_KEY" ]]; then
        log "ERROR" "Either specify a specific SSH key (-k) or use -a to remove all keys"
        exit 1
    fi
    
    if [[ "$REMOVE_ALL_KEYS" == "true" && -n "$SSH_PUBLIC_KEY" ]]; then
        log "ERROR" "Cannot specify both -k (specific key) and -a (all keys) options"
        exit 1
    fi
    
    log "SUCCESS" "Input validation completed"
}

# Generate SSH offboarding summary
generate_summary() {
    print_section "SSH Offboarding Summary"
    
    echo -e "${BLUE}User:${NC} $USER_NAME"
    echo -e "${BLUE}Subscription:${NC} $SUBSCRIPTION_ID"
    echo -e "${BLUE}Resource Group:${NC} $VM_RESOURCE_GROUP"
    echo -e "${BLUE}VMs:${NC} ${VM_NAMES[*]}"
    
    if [[ "$REMOVE_ALL_KEYS" == "true" ]]; then
        echo -e "${BLUE}Operation:${NC} Remove ALL SSH keys"
    else
        echo -e "${BLUE}Operation:${NC} Remove specific SSH key"
        echo -e "${BLUE}SSH Key:${NC} $(echo "$SSH_PUBLIC_KEY" | cut -c1-50)..."
    fi
    
    echo -e "${BLUE}Backup Keys:${NC} $BACKUP_KEYS"
    echo -e "${BLUE}Dry Run:${NC} $DRY_RUN"
    echo -e "${BLUE}Log File:${NC} $LOG_FILE"
    
    if [[ "$DRY_RUN" == "false" ]]; then
        log "SUCCESS" "SSH key offboarding completed successfully"
        echo -e "${GREEN}✓ SSH keys have been removed from the specified VMs${NC}"
        if [[ "$BACKUP_KEYS" == "true" ]]; then
            echo -e "${YELLOW}ℹ️  Original authorized_keys files have been backed up${NC}"
        fi
    else
        echo -e "${YELLOW}This was a dry run. No changes were made.${NC}"
    fi
}

# Validate SSH public key (if provided)
validate_ssh_key() {
    if [[ -z "$SSH_PUBLIC_KEY" ]]; then
        return 0  # No key to validate
    fi
    
    print_section "Validating SSH Key"
    
    local key_input="$SSH_PUBLIC_KEY"
    local key_content=""
    
    # Check if it's a file path
    if [[ -f "$key_input" ]]; then
        log "INFO" "Reading SSH key from file: $key_input"
        key_content=$(cat "$key_input")
    else
        # Assume it's the key content directly
        key_content="$key_input"
    fi
    
    # Validate SSH key format
    if [[ ! "$key_content" =~ ^ssh-(rsa|dss|ed25519|ecdsa) ]]; then
        log "ERROR" "Invalid SSH public key format. Key must start with ssh-rsa, ssh-dss, ssh-ed25519, or ssh-ecdsa"
        exit 1
    fi
    
    # Update the global variable with the key content
    SSH_PUBLIC_KEY="$key_content"
    
    log "SUCCESS" "SSH key validation completed"
}

# Remove SSH keys from Azure VMs (azroot account only)
remove_vm_ssh_access() {
    print_section "Removing VM SSH Access"
    
    local subscription_id="$1"
    local resource_group="$2"
    shift 2
    local vm_names=("$@")
    
    print_operation_status "SSH Key Removal" "start" "Processing ${#vm_names[@]} VMs"
    
    for vm_name in "${vm_names[@]}"; do
        print_progress "$((++current_vm))" "${#vm_names[@]}" "Processing VM: $vm_name"
        
        # Check if VM exists and is running
        local vm_status=$(az vm get-instance-view --resource-group "$resource_group" --name "$vm_name" \
                         --query "instanceView.statuses[?code=='PowerState/running']" -o tsv 2>/dev/null || echo "")
        
        if [[ -z "$vm_status" ]]; then
            print_operation_status "VM Check: $vm_name" "error" "VM not found or not running"
            log "ERROR" "VM $vm_name is not running or does not exist in resource group $resource_group"
            continue
        fi
        
        if [[ "$DRY_RUN" == "true" ]]; then
            if [[ "$REMOVE_ALL_KEYS" == "true" ]]; then
                print_operation_status "SSH Key Removal: $vm_name" "skip" "Dry run mode - would remove ALL SSH keys from azroot account"
                log "INFO" "DRY RUN: Would remove ALL SSH keys from $vm_name (azroot account)"
            else
                print_operation_status "SSH Key Removal: $vm_name" "skip" "Dry run mode - would remove specific SSH key from azroot account"
                log "INFO" "DRY RUN: Would remove specific SSH key from $vm_name (azroot account)"
            fi
        else
            remove_ssh_keys_from_vm "$vm_name" "$resource_group"
        fi
    done
    
    print_operation_status "SSH Key Removal" "success" "Completed processing ${#vm_names[@]} VMs"
}

# Remove SSH keys from azroot account on a specific VM
remove_ssh_keys_from_vm() {
    local vm_name="$1"
    local resource_group="$2"
    
    # Create temporary script to run on VM
    local temp_script=$(mktemp)
    trap "rm -f $temp_script" RETURN
    
    if [[ "$REMOVE_ALL_KEYS" == "true" ]]; then
        # Script to remove ALL SSH keys
        cat > "$temp_script" << EOF
#!/bin/bash
set -euo pipefail

AZROOT_HOME="/home/azroot"
SSH_DIR="\$AZROOT_HOME/.ssh"
AUTHORIZED_KEYS="\$SSH_DIR/authorized_keys"

# Function to log with timestamp
log_vm() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') [\$1] \$2"
}

log_vm "INFO" "Removing ALL SSH keys from azroot account"

# Check if authorized_keys exists
if [[ ! -f "\$AUTHORIZED_KEYS" ]]; then
    log_vm "INFO" "No authorized_keys file found, nothing to remove"
    exit 0
fi

# Backup authorized_keys before modification (if backup enabled)
if [[ "$BACKUP_KEYS" == "true" ]]; then
    cp "\$AUTHORIZED_KEYS" "\$AUTHORIZED_KEYS.backup.\$(date +%Y%m%d_%H%M%S)"
    log_vm "INFO" "Backed up authorized_keys file"
fi

# Clear the authorized_keys file (remove all SSH keys)
> "\$AUTHORIZED_KEYS"
chown azroot:azroot "\$AUTHORIZED_KEYS"
chmod 600 "\$AUTHORIZED_KEYS"

log_vm "SUCCESS" "Cleared all SSH keys from azroot authorized_keys"
EOF
    else
        # Script to remove specific SSH key
        cat > "$temp_script" << EOF
#!/bin/bash
set -euo pipefail

SSH_KEY="$SSH_PUBLIC_KEY"
AZROOT_HOME="/home/azroot"
SSH_DIR="\$AZROOT_HOME/.ssh"
AUTHORIZED_KEYS="\$SSH_DIR/authorized_keys"

# Function to log with timestamp
log_vm() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') [\$1] \$2"
}

log_vm "INFO" "Removing specific SSH key from azroot account"

# Check if authorized_keys exists
if [[ ! -f "\$AUTHORIZED_KEYS" ]]; then
    log_vm "INFO" "No authorized_keys file found, nothing to remove"
    exit 0
fi

# Backup authorized_keys before modification (if backup enabled)
if [[ "$BACKUP_KEYS" == "true" ]]; then
    cp "\$AUTHORIZED_KEYS" "\$AUTHORIZED_KEYS.backup.\$(date +%Y%m%d_%H%M%S)"
    log_vm "INFO" "Backed up authorized_keys file"
fi

# Remove the specific SSH key
if grep -qF "\$SSH_KEY" "\$AUTHORIZED_KEYS"; then
    grep -vF "\$SSH_KEY" "\$AUTHORIZED_KEYS" > "\$AUTHORIZED_KEYS.tmp"
    mv "\$AUTHORIZED_KEYS.tmp" "\$AUTHORIZED_KEYS"
    chown azroot:azroot "\$AUTHORIZED_KEYS"
    chmod 600 "\$AUTHORIZED_KEYS"
    log_vm "SUCCESS" "Removed specific SSH key from authorized_keys"
else
    log_vm "INFO" "SSH key not found in authorized_keys, nothing to remove"
fi
EOF
    fi
    
    if [[ "$REMOVE_ALL_KEYS" == "true" ]]; then
        print_operation_status "SSH Key Removal: $vm_name" "start" "Removing ALL keys from azroot account"
    else
        print_operation_status "SSH Key Removal: $vm_name" "start" "Removing specific key from azroot account"
    fi
    
    # Execute the script on the VM
    local run_result=$(az vm run-command invoke \
        --resource-group "$resource_group" \
        --name "$vm_name" \
        --command-id RunShellScript \
        --scripts @"$temp_script" \
        --output json 2>&1)
    
    if [[ $? -eq 0 ]]; then
        print_operation_status "SSH Key Removal: $vm_name" "success" "SSH keys removed from azroot account"
        if [[ "$REMOVE_ALL_KEYS" == "true" ]]; then
            log "SUCCESS" "Removed ALL SSH keys from $vm_name (azroot account)"
        else
            log "SUCCESS" "Removed specific SSH key from $vm_name (azroot account)"
        fi
    else
        print_operation_status "SSH Key Removal: $vm_name" "error" "Failed to remove SSH keys"
        log "ERROR" "Failed to remove SSH keys from $vm_name: $run_result"
    fi
}

# Validate CSV file format and content
validate_csv_file() {
    local csv_file="$1"
    
    print_section "Validating CSV File"
    
    # Expand tilde and resolve path
    csv_file="${csv_file/#\~/$HOME}"
    # Remove escaped characters and resolve the path
    csv_file=$(eval echo "$csv_file")
    
    # Update the global variable with the resolved path
    CSV_FILE="$csv_file"
    
    log "INFO" "Resolved CSV file path: $csv_file"
    
    # Check if file exists
    if [[ ! -f "$csv_file" ]]; then
        log "ERROR" "CSV file does not exist: $csv_file"
        log "INFO" "Make sure the file path is correct and the file exists"
        exit 1
    fi
    
    # Check if file is readable
    if [[ ! -r "$csv_file" ]]; then
        log "ERROR" "CSV file is not readable: $csv_file"
        log "INFO" "Check file permissions"
        exit 1
    fi
    
    # Count lines (excluding header)
    local total_lines=$(wc -l < "$csv_file")
    local line_count=$(tail -n +2 "$csv_file" | wc -l | xargs)
    
    log "INFO" "CSV file stats: Total lines=$total_lines, Data lines=$line_count"
    
    # Debug: Show first few lines of the file
    log "INFO" "CSV file content preview:"
    head -n 3 "$csv_file" | while IFS= read -r line; do
        log "INFO" "  Line: '$line'"
    done
    
    if [[ $line_count -eq 0 ]]; then
        log "ERROR" "CSV file contains no data rows (only header or empty file)"
        log "ERROR" "Total lines in file: $total_lines"
        exit 1
    fi
    
    log "SUCCESS" "CSV file validation completed - found $line_count data rows"
}

# Parse CSV file and process each row
process_csv_file() {
    local csv_file="$CSV_FILE"  # Use the resolved path from validate_csv_file
    
    print_section "Processing CSV File: $csv_file"
    
    local line_number=1
    local processed_rows=0
    local failed_rows=0
    
    # Read CSV file line by line, skipping the header
    while IFS=',' read -r csv_username csv_subscription csv_ssh_key csv_resource_group csv_vm_names csv_remove_all csv_backup || [[ -n "$csv_username" ]]; do
        # Skip header row
        if [[ $line_number -eq 1 ]]; then
            line_number=$((line_number + 1))
            continue
        fi
        
        # Skip empty lines
        if [[ -z "$csv_username" && -z "$csv_subscription" && -z "$csv_resource_group" ]]; then
            line_number=$((line_number + 1))
            continue
        fi
        
        log "INFO" "Processing CSV row $line_number: user=$csv_username, subscription=$csv_subscription, rg=$csv_resource_group"
        
        # Clean up CSV fields (remove quotes and trim whitespace)
        csv_username=$(echo "$csv_username" | sed 's/^"//;s/"$//' | xargs)
        csv_subscription=$(echo "$csv_subscription" | sed 's/^"//;s/"$//' | xargs)
        csv_ssh_key=$(echo "$csv_ssh_key" | sed 's/^"//;s/"$//' | xargs)
        csv_resource_group=$(echo "$csv_resource_group" | sed 's/^"//;s/"$//' | xargs)
        csv_vm_names=$(echo "$csv_vm_names" | sed 's/^"//;s/"$//' | xargs)
        csv_remove_all=$(echo "$csv_remove_all" | sed 's/^"//;s/"$//' | xargs)
        csv_backup=$(echo "$csv_backup" | sed 's/^"//;s/"$//' | xargs)
        
        # Set variables for current row
        USER_NAME="$csv_username"
        SUBSCRIPTION_ID="$csv_subscription"
        SSH_PUBLIC_KEY="$csv_ssh_key"
        VM_RESOURCE_GROUP="$csv_resource_group"
        
        # Parse VM names (handle comma-separated values)
        IFS=',' read -ra VM_NAMES <<< "$csv_vm_names"
        # Trim whitespace from each VM name
        for i in "${!VM_NAMES[@]}"; do
            VM_NAMES[i]=$(echo "${VM_NAMES[i]}" | xargs)
        done
        
        # Set remove all keys mode
        if [[ "$csv_remove_all" =~ ^[Tt][Rr][Uu][Ee]$ ]]; then
            REMOVE_ALL_KEYS=true
        else
            REMOVE_ALL_KEYS=false
        fi
        
        # Set backup mode
        if [[ "$csv_backup" =~ ^[Tt][Rr][Uu][Ee]$ ]]; then
            BACKUP_KEYS=true
        else
            BACKUP_KEYS=false
        fi
        
        # Note: DRY_RUN is controlled by command line flag, not CSV
        
        # Process current row
        if process_single_operation; then
            processed_rows=$((processed_rows + 1))
            log "SUCCESS" "Completed processing row $line_number for user: $USER_NAME"
        else
            failed_rows=$((failed_rows + 1))
            log "ERROR" "Failed processing row $line_number for user: $USER_NAME"
        fi
        
        line_number=$((line_number + 1))
        echo # Add separator between operations
    done < "$csv_file"
    
    # Generate CSV processing summary
    print_section "CSV Processing Summary"
    echo -e "${BLUE}Total rows processed:${NC} $((processed_rows + failed_rows))"
    echo -e "${GREEN}Successful operations:${NC} $processed_rows"
    echo -e "${RED}Failed operations:${NC} $failed_rows"
    
    if [[ $failed_rows -gt 0 ]]; then
        log "WARNING" "Some operations failed. Check the log file for details: $LOG_FILE"
        return 1
    else
        log "SUCCESS" "All CSV operations completed successfully"
        return 0
    fi
}

# Process a single offboarding operation (used by CSV processing)
process_single_operation() {
    local operation_failed=false
    
    # Validate input for current operation
    if ! validate_input_for_row; then
        return 1
    fi
    
    # Validate SSH key for current operation (only if not removing all keys and SSH key is provided)
    if [[ "$REMOVE_ALL_KEYS" == "false" && -n "$SSH_PUBLIC_KEY" ]]; then
        if ! validate_ssh_key "$SSH_PUBLIC_KEY"; then
            return 1
        fi
    fi
    
    # Check VM permissions for current operation
    if ! check_vm_permissions "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP"; then
        return 1
    fi
    
    # Remove SSH access from VMs for current operation
    current_vm=0
    if ! remove_vm_ssh_access "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP" "${VM_NAMES[@]}"; then
        return 1
    fi
    
    return 0
}

# Validate input for a single CSV row
validate_input_for_row() {
    local validation_failed=false
    
    # Check required parameters
    if [[ -z "$USER_NAME" ]]; then
        log "ERROR" "Username is required (CSV column: username)"
        validation_failed=true
    fi
    
    if [[ -z "$SUBSCRIPTION_ID" ]]; then
        log "ERROR" "Subscription ID is required (CSV column: subscription_id)"
        validation_failed=true
    fi
    
    if [[ -z "$VM_RESOURCE_GROUP" ]]; then
        log "ERROR" "VM resource group is required (CSV column: vm_resource_group)"
        validation_failed=true
    fi
    
    if [[ ${#VM_NAMES[@]} -eq 0 ]]; then
        log "ERROR" "At least one VM name is required (CSV column: vm_names)"
        validation_failed=true
    fi
    
    # Check that either SSH key is provided or remove_all_keys is true
    if [[ "$REMOVE_ALL_KEYS" == "false" && -z "$SSH_PUBLIC_KEY" ]]; then
        log "ERROR" "SSH public key is required when remove_all_keys is false (CSV column: ssh_public_key)"
        validation_failed=true
    fi
    
    if [[ "$validation_failed" == "true" ]]; then
        return 1
    fi
    
    return 0
}

#################################################################################
# Main Script
#################################################################################

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--username)
                USER_NAME="$2"
                shift 2
                ;;
            -s|--subscription)
                SUBSCRIPTION_ID="$2"
                shift 2
                ;;
            -k|--key)
                SSH_PUBLIC_KEY="$2"
                shift 2
                ;;
            -g|--resource-group)
                VM_RESOURCE_GROUP="$2"
                shift 2
                ;;
            -v|--vm)
                VM_NAMES+=("$2")
                shift 2
                ;;
            -f|--file)
                CSV_FILE="$2"
                shift 2
                ;;
            -a|--remove-all)
                REMOVE_ALL_KEYS=true
                shift
                ;;
            -n|--no-backup)
                BACKUP_KEYS=false
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage >&2
                exit 1
                ;;
        esac
    done
    
    # Initialize log file
    echo "SSH Key Offboarding Log - $(date)" > "$LOG_FILE"
    log "INFO" "Starting SSH key offboarding script"
    
    # Check prerequisites first
    check_prerequisites
    
    # Determine mode: CSV file or command line parameters
    if [[ -n "$CSV_FILE" ]]; then
        # CSV File Mode
        print_section "CSV File Mode"
        log "INFO" "Processing SSH key offboarding from CSV file: $CSV_FILE"
        
        # Validate CSV file
        validate_csv_file "$CSV_FILE"
        
        # Process CSV file (uses resolved path from CSV_FILE global variable)
        if process_csv_file; then
            log "SUCCESS" "CSV file processing completed successfully"
            exit 0
        else
            log "ERROR" "CSV file processing completed with errors"
            exit 1
        fi
    else
        # Command Line Mode
        print_section "Command Line Mode"
        log "INFO" "Processing SSH key offboarding from command line parameters"
        
        # Validate input
        validate_input
        
        # Validate SSH key (if provided)
        validate_ssh_key
        
        # Check VM permissions
        check_vm_permissions "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP"
        
        # Remove SSH access from VMs
        current_vm=0
        remove_vm_ssh_access "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP" "${VM_NAMES[@]}"
        
        # Generate summary
        generate_summary
    fi
}

# Run main function with all arguments
main "$@"