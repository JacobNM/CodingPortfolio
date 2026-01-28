#!/bin/bash
# Azure VM SSH Key Onboarding Script
# Automates adding SSH keys to Azure VMs (azroot account)

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/ssh_onboarding_$(date +%Y%m%d_%H%M%S).log"

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
CSV_FILE=""

# Functions

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Log-only function (writes only to log file, not terminal)
log_only() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" >> "$LOG_FILE"
}

# Print section header with visual separator
print_section() {
    local title="$1"
    local color="${2:-$BLUE}"
    echo
    echo -e "${color}$title${NC}"
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
- Add SSH public keys to Azure VMs (azroot account)
- Support for multiple VMs or auto-discovery of all VMs in resource group
- Import parameters from CSV file for batch operations

**COMMAND LINE MODE:**
Required Parameters:
    -u, --username <username>           Username for identification
    -s, --subscription <subscription_id> Azure subscription ID
    -k, --key <ssh_public_key>         SSH public key file path or key content
    -g, --resource-group <vm_resource_group> Resource group containing VMs
    -v, --vm <vm_name>                 VM name (can be specified multiple times, optional - if omitted, all VMs in resource group will be used)

Optional Parameters:
    -d, --dry-run                      Dry run mode (show what would be done)
    -h, --help                         Display this help message

**CSV FILE MODE:**
    -f, --file <csv_file>              CSV file containing onboarding parameters
                           Format: username,subscription_id,ssh_public_key,vm_resource_group,vm_names
                           VM names can be comma-separated within quotes (or empty for auto-discovery)

Examples:
    # Command line mode - Add SSH key to single VM (short options)
    $0 -u john.doe -s "12345678-1234-1234-1234-123456789012" \\
       -k ~/.ssh/id_rsa.pub -g "myvm-rg" -v "myvm01"

    # Command line mode - Add SSH key to ALL VMs in resource group (auto-discovery)
    $0 -u john.doe -s "12345678-1234-1234-1234-123456789012" \\
       -k ~/.ssh/id_rsa.pub -g "myvm-rg"

    # Command line mode - Add SSH key to multiple specific VMs (long options)
    $0 --username jane.smith --subscription "12345678-1234-1234-1234-123456789012" \\
       --key ~/.ssh/id_rsa.pub --resource-group "myvm-rg" --vm "vm01" --vm "vm02" --vm "vm03"

    # Command line mode - Dry run with auto-discovery (mixed options)
    $0 -u john.doe --subscription "12345678-1234-1234-1234-123456789012" \\
       --key ~/.ssh/id_rsa.pub -g "myvm-rg" --dry-run

    # CSV file mode - Batch processing
    $0 --file onboarding_batch.csv --dry-run

**CSV File Format Example (onboarding_batch.csv):**
username,subscription_id,ssh_public_key,vm_resource_group,vm_names
john.doe,12345678-1234-1234-1234-123456789012,~/.ssh/id_rsa.pub,prod-rg,"vm01,vm02"
jane.smith,87654321-4321-4321-4321-210987654321,~/.ssh/jane_key.pub,test-rg,vm03
# Empty vm_names field will auto-discover all VMs in the resource group:
mike.wilson,11111111-2222-3333-4444-555555555555,"ssh-rsa AAAAB3Nz...",dev-rg,
sara.jones,22222222-3333-4444-5555-666666666666,~/.ssh/sara_key.pub,staging-rg,

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
        echo -e "${RED}Error: Not logged into Azure${NC}" >&2
        exit 1
    fi
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
    
    if [[ -z "$SSH_PUBLIC_KEY" ]]; then
        log "ERROR" "SSH public key is required"
        exit 1
    fi
    
    if [[ -z "$VM_RESOURCE_GROUP" ]]; then
        log "ERROR" "VM resource group is required"
        exit 1
    fi
    
    # VM names are optional - if empty, we'll discover all VMs in the resource group
    if [[ ${#VM_NAMES[@]:-0} -eq 0 ]]; then
        log "INFO" "No VM names specified - will discover all VMs in resource group '$VM_RESOURCE_GROUP'"
    fi
    
    log "SUCCESS" "Input validation completed"
}

# Generate SSH onboarding summary
generate_summary() {
    print_section "SSH Onboarding Summary"
    
    echo -e "${BLUE}User:${NC} $USER_NAME"
    echo -e "${BLUE}Subscription:${NC} $SUBSCRIPTION_ID"
    echo -e "${BLUE}Resource Group:${NC} $VM_RESOURCE_GROUP"
    echo -e "${BLUE}VMs:${NC} ${VM_NAMES[*]}"
    echo -e "${BLUE}SSH Key:${NC} $(echo "$SSH_PUBLIC_KEY" | cut -c1-50)..."
    echo -e "${BLUE}Dry Run:${NC} $DRY_RUN"
    echo -e "${BLUE}Log File:${NC} $LOG_FILE"
    
    if [[ "$DRY_RUN" == "false" ]]; then
        log "SUCCESS" "SSH key onboarding completed successfully"
        echo -e "${GREEN}✓ SSH key has been added to the specified VMs${NC}"
        echo -e "${YELLOW}Users can now SSH to the VMs using: ssh azroot@<vm-ip>${NC}"
    else
        echo -e "${YELLOW}This was a dry run. No changes were made.${NC}"
    fi
}

# Validate SSH public key
validate_ssh_key() {
    print_section "Validating SSH Key"
    
    local key_input="$1"
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

# Discover all VMs in a resource group
discover_vms_in_resource_group() {
    local subscription_id="$1"
    local resource_group="$2"
    
    # In dry-run mode, we still want to discover actual VMs, just not modify them
    if [[ "$DRY_RUN" == "true" ]]; then
        log_only "INFO" "DRY RUN: Discovering VMs in resource group '$resource_group'" >&2
    fi
    
    # Verify subscription is set correctly
    local current_sub
    current_sub=$(az account show --query id -o tsv 2>/dev/null)
    if [[ "$current_sub" != "$subscription_id" ]]; then
        az account set --subscription "$subscription_id" 2>/dev/null || {
            log "ERROR" "Failed to set subscription '$subscription_id'" >&2
            return 1
        }
    fi
    
    # Get list of VM names from Azure with error handling
    local vm_list
    local az_error
    vm_list=$(az vm list --resource-group "$resource_group" --query '[].name' -o tsv 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        log "ERROR" "Azure CLI command failed (exit code: $exit_code)" >&2
        log "ERROR" "Error details: $vm_list" >&2
        return 1
    fi
    
    # Remove any empty lines and trim whitespace
    vm_list=$(echo "$vm_list" | grep -v '^$' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [[ -z "$vm_list" ]]; then
        log "WARNING" "No VMs found in resource group '$resource_group'" >&2
        log "INFO" "Verifying resource group exists..." >&2
        az group show --name "$resource_group" >/dev/null 2>&1 || {
            log "ERROR" "Resource group '$resource_group' does not exist or is not accessible" >&2
            return 1
        }
        return 1
    fi
    
    local vm_count
    vm_count=$(echo "$vm_list" | wc -l | tr -d ' ')
    log "SUCCESS" "Discovered $vm_count VM(s) in resource group '$resource_group'" >&2
    
    echo "$vm_list"
    return 0
}

# Prompt for confirmation before performing operations
prompt_for_confirmation() {
    local operation="$1"
    local vm_count="$2"
    local vm_list="$3"
    
    echo -e "\n${YELLOW}⚠️  CONFIRMATION REQUIRED${NC}"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${BLUE}Operation:${NC} $operation"
    echo -e "${BLUE}VM Count:${NC} $vm_count VM(s)"
    echo -e "${BLUE}Target VMs:${NC} $vm_list"
    echo -e "${BLUE}User:${NC} $USER_NAME"
    echo -e "${BLUE}Subscription:${NC} $SUBSCRIPTION_ID"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${YELLOW}This will ADD SSH keys to the azroot account on the specified VMs.${NC}"
    echo ""
    
    while true; do
        read -p "Do you want to continue? [y/N]: " -r response < /dev/tty
        case "$response" in
            [Yy]|[Yy][Ee][Ss])
                echo -e "\n${GREEN}✓ Confirmed. Proceeding with operation...${NC}"
                return 0
                ;;
            [Nn]|[Nn][Oo]|"")
                echo -e "\n${YELLOW}✗ Operation cancelled by user.${NC}"
                return 1
                ;;
            *)
                echo -e "${RED}Please enter 'y' for yes or 'n' for no.${NC}"
                ;;
        esac
    done
}

# Manage SSH keys on Azure VMs (azroot account only)
manage_vm_ssh_access() {
    print_section "Managing VM SSH Access"
    
    local subscription_id="$1"
    local resource_group="$2"
    shift 2
    local vm_names=("$@")
    
    # Check if we need to discover VMs (empty array or array with only empty strings)
    local needs_discovery=true
    for vm_name in "${vm_names[@]}"; do
        if [[ -n "$(echo "$vm_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')" ]]; then
            needs_discovery=false
            break
        fi
    done
    if [[ ${#vm_names[@]} -eq 0 ]]; then
        needs_discovery=true
    fi
    
    # If no VM names provided or all are empty, discover all VMs in the resource group
    if [[ "$needs_discovery" == "true" ]]; then
        
        # Reset the array since we found only empty elements
        vm_names=()
        
        local discovered_vms
        if discovered_vms=$(discover_vms_in_resource_group "$subscription_id" "$resource_group"); then
            # Handle the case where there might be only one VM name without newlines
            if [[ -n "$discovered_vms" ]]; then
                # Split by newlines and add to array
                while IFS= read -r vm_name; do
                    # Trim whitespace
                    vm_name=$(echo "$vm_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    
                    if [[ -n "$vm_name" ]]; then
                        vm_names+=("$vm_name")
                    fi
                done <<< "$discovered_vms"
            fi
            
            if [[ ${#vm_names[@]} -eq 0 ]]; then
                log "ERROR" "No valid VM names found after filtering"
                return 1
            fi
            
            # Update global VM_NAMES array for summary display
            VM_NAMES=("${vm_names[@]}")
            log "INFO" "Auto-discovered ${#vm_names[@]} VM(s): $(IFS=', '; echo "${vm_names[*]}")"
        else
            log "ERROR" "Failed to discover VMs in resource group '$resource_group'"
            return 1
        fi
    fi
    
    # Prompt for confirmation if not in dry-run mode
    if [[ "$DRY_RUN" != "true" ]]; then
        local vm_list_str="$(IFS=', '; echo "${vm_names[*]}")"
        
        if ! prompt_for_confirmation "SSH Key Addition" "${#vm_names[@]}" "$vm_list_str"; then
            log "INFO" "Operation cancelled by user"
            return 1
        fi
    fi
    
    print_operation_status "SSH Key Management" "start" "Processing ${#vm_names[@]} VMs"
    
    for vm_name in "${vm_names[@]}"; do
        print_progress "$((++current_vm))" "${#vm_names[@]}" "Processing VM: $vm_name"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            print_operation_status "SSH Key Addition: $vm_name" "skip" "Dry run mode - would add SSH key to azroot account"
            log_only "INFO" "DRY RUN: Would add SSH key to $vm_name (azroot account)"
        else
            # Check if VM exists and is running (only in non-dry-run mode)
            local vm_status=$(az vm get-instance-view --resource-group "$resource_group" --name "$vm_name" \
                             --query "instanceView.statuses[?code=='PowerState/running']" -o tsv 2>/dev/null || echo "")
            
            if [[ -z "$vm_status" ]]; then
                print_operation_status "VM Check: $vm_name" "error" "VM not found or not running"
                log "ERROR" "VM $vm_name is not running or does not exist in resource group $resource_group"
                continue
            fi
            
            add_ssh_key_to_vm "$vm_name" "$resource_group"
        fi
    done
    
    print_operation_status "SSH Key Management" "success" "Completed processing ${#vm_names[@]} VMs"
}

# Add SSH key to azroot account on a specific VM
add_ssh_key_to_vm() {
    local vm_name="$1"
    local resource_group="$2"
    
    # Create temporary script to run on VM
    local temp_script=$(mktemp)
    trap "rm -f $temp_script" RETURN
    
    # Base64-encode SSH public key to safely embed it in the generated script
    local SSH_KEY_B64
    SSH_KEY_B64="$(printf '%s' "$SSH_PUBLIC_KEY" | base64 | tr -d '\n')"
    
    cat > "$temp_script" << EOF
#!/bin/bash
set -euo pipefail

SSH_KEY_B64="$SSH_KEY_B64"
SSH_KEY=\$(printf '%s' "\$SSH_KEY_B64" | base64 -d)
AZROOT_HOME="/home/azroot"
SSH_DIR="\$AZROOT_HOME/.ssh"
AUTHORIZED_KEYS="\$SSH_DIR/authorized_keys"

# Function to log with timestamp
log_vm() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') [\$1] \$2"
}

log_vm "INFO" "Adding SSH key to azroot account"

# Ensure SSH directory exists
if [[ ! -d "\$SSH_DIR" ]]; then
    mkdir -p "\$SSH_DIR"
    chown azroot:azroot "\$SSH_DIR"
    chmod 700 "\$SSH_DIR"
fi

# Create authorized_keys file if it doesn't exist
if [[ ! -f "\$AUTHORIZED_KEYS" ]]; then
    touch "\$AUTHORIZED_KEYS"
    chown azroot:azroot "\$AUTHORIZED_KEYS"
    chmod 600 "\$AUTHORIZED_KEYS"
fi

# Check if key already exists
if grep -qF "\$SSH_KEY" "\$AUTHORIZED_KEYS"; then
    log_vm "INFO" "SSH key already exists in authorized_keys"
else
    echo "\$SSH_KEY" >> "\$AUTHORIZED_KEYS"
    log_vm "SUCCESS" "SSH key added to authorized_keys"
fi

log_vm "SUCCESS" "SSH key management completed for azroot account"
EOF
    
    print_operation_status "SSH Key Addition: $vm_name" "start" "Adding key to azroot account"
    
    # Execute the script on the VM
    local run_result=$(az vm run-command invoke \
        --resource-group "$resource_group" \
        --name "$vm_name" \
        --command-id RunShellScript \
        --scripts @"$temp_script" \
        --output json 2>&1)
    
    if [[ $? -eq 0 ]]; then
        print_operation_status "SSH Key Addition: $vm_name" "success" "SSH key added to azroot account"
        log "SUCCESS" "SSH key added to $vm_name (azroot account)"
    else
        print_operation_status "SSH Key Addition: $vm_name" "error" "Failed to add SSH key"
        log "ERROR" "Failed to add SSH key to $vm_name: $run_result"
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
    
    # Count lines (excluding header) for progress tracking
    local line_count=$(tail -n +2 "$csv_file" | wc -l | xargs)
    
    local line_number=1
    local processed_rows=0
    local failed_rows=0
    
    # Read CSV file line by line, skipping the header
    # Use a more robust CSV parser to handle quoted fields with commas
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip header row
        if [[ $line_number -eq 1 ]]; then
            line_number=$((line_number + 1))
            continue
        fi
        
        # Skip empty lines
        if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*$ ]]; then
            line_number=$((line_number + 1))
            continue
        fi
        
        # Parse CSV line using python to handle quoted fields properly
        local csv_fields
        csv_fields=$(python3 -c "
import csv
import sys
reader = csv.reader([sys.argv[1]])
for row in reader:
    for field in row:
        print(repr(field))
" "$line")
        
        # Extract fields from python output
        local field_array=()
        while IFS= read -r field; do
            # Remove python repr quotes
            field=$(echo "$field" | sed "s/^'//;s/'$//")
            field_array+=("$field")
        done <<< "$csv_fields"
        
        # Assign fields to variables (handle missing fields gracefully)
        csv_username="${field_array[0]:-}"
        csv_subscription="${field_array[1]:-}"
        csv_ssh_key="${field_array[2]:-}"
        csv_resource_group="${field_array[3]:-}"
        csv_vm_names="${field_array[4]:-}"
        
        # Skip rows with empty essential fields
        if [[ -z "$csv_username" && -z "$csv_subscription" && -z "$csv_ssh_key" ]]; then
            line_number=$((line_number + 1))
            continue
        fi
        
        print_progress "$((line_number-1))" "$line_count" "Processing user: $csv_username"
        
        # Set variables for current row
        USER_NAME="$csv_username"
        SUBSCRIPTION_ID="$csv_subscription"
        SSH_PUBLIC_KEY="$csv_ssh_key"
        VM_RESOURCE_GROUP="$csv_resource_group"
        
        # Parse VM names (handle comma-separated values)
        # Remove any surrounding single quotes that might be embedded in the CSV field
        csv_vm_names=$(echo "$csv_vm_names" | sed "s/^'\|'$//g")
        
        if [[ -n "$csv_vm_names" ]]; then
            IFS=',' read -ra VM_NAMES <<< "$csv_vm_names"
            # Trim whitespace and quotes from each VM name
            for i in "${!VM_NAMES[@]}"; do
                VM_NAMES[i]=$(echo "${VM_NAMES[i]}" | sed "s/^'\|'$//g" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            done
        else
            VM_NAMES=()
        fi
        
        # Note: DRY_RUN is controlled by command line flag, not CSV
        
        # Process current row
        if process_single_operation; then
            processed_rows=$((processed_rows + 1))
            print_operation_status "User: $USER_NAME" "success"
        else
            failed_rows=$((failed_rows + 1))
            print_operation_status "User: $USER_NAME" "error"
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

# Process a single onboarding operation (used by CSV processing)
process_single_operation() {
    local operation_failed=false
    
    # Validate input for current operation
    if ! validate_input_for_row; then
        return 1
    fi
    
    # Validate SSH key for current operation
    if ! validate_ssh_key "$SSH_PUBLIC_KEY"; then
        return 1
    fi
    
    # Check VM permissions for current operation
    if ! check_vm_permissions "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP"; then
        return 1
    fi
    
    # Manage SSH access on VMs for current operation
    current_vm=0
    if ! manage_vm_ssh_access "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP" "${VM_NAMES[@]:-}"; then
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
    
    if [[ -z "$SSH_PUBLIC_KEY" ]]; then
        log "ERROR" "SSH public key is required (CSV column: ssh_public_key)"
        validation_failed=true
    fi
    
    if [[ -z "$VM_RESOURCE_GROUP" ]]; then
        log "ERROR" "VM resource group is required (CSV column: vm_resource_group)"
        validation_failed=true
    fi
    
    # VM names are optional - if empty, we'll discover all VMs in the resource group
    if [[ ${#VM_NAMES[@]:-0} -eq 0 ]]; then
        # Silent discovery - will be logged during actual discovery
        :
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
    echo "SSH Key Onboarding Log - $(date)" > "$LOG_FILE"
    log "INFO" "Starting SSH key onboarding script"
    
    # Check prerequisites first
    check_prerequisites
    
    # Determine mode: CSV file or command line parameters
    if [[ -n "$CSV_FILE" ]]; then
        # CSV File Mode
        print_section "CSV File Mode"
        log "INFO" "Processing SSH key onboarding from CSV file: $CSV_FILE"
        
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
        
        # Validate input
        validate_input
        
        # Validate SSH key
        validate_ssh_key "$SSH_PUBLIC_KEY"
        
        # Check VM permissions
        check_vm_permissions "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP"
        
        # Manage SSH access on VMs
        current_vm=0
        manage_vm_ssh_access "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP" "${VM_NAMES[@]:-}"
        
        # Generate summary
        generate_summary
    fi
}

main "$@"