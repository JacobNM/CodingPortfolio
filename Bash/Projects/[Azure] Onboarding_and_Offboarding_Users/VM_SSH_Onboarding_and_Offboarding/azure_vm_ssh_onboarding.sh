#!/bin/bash

#################################################################################
# Azure VM SSH Key Onboarding Script
# Description: Automates adding SSH keys to Azure VMs for user access
#              Adds SSH keys to the azroot account on specified VMs
#################################################################################

set -euo pipefail  # Exit on any error, undefined variable, or pipe failure

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
DRY_RUN=false
VM_RESOURCE_GROUP=""
VM_NAMES=()
SSH_PUBLIC_KEY=""
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
- Add SSH public keys to Azure VMs (azroot account)
- Support for multiple VMs
- Import parameters from CSV file for batch operations

**COMMAND LINE MODE:**
Required Parameters:
    -u <username>           Username for identification
    -s <subscription_id>    Azure subscription ID
    -k <ssh_public_key>     SSH public key file path or key content
    -g <vm_resource_group>  Resource group containing VMs
    -v <vm_name>           VM name (can be specified multiple times)

Optional Parameters:
    -d                     Dry run mode (show what would be done)
    -h                     Display this help message

**CSV FILE MODE:**
    -f <csv_file>          CSV file containing onboarding parameters
                           Format: username,subscription_id,ssh_public_key,vm_resource_group,vm_names,dry_run
                           VM names can be comma-separated within quotes
                           dry_run should be 'true' or 'false'

Examples:
    # Command line mode - Add SSH key to single VM
    $0 -u john.doe -s "12345678-1234-1234-1234-123456789012" \\
       -k ~/.ssh/id_rsa.pub -g "myvm-rg" -v "myvm01"

    # Command line mode - Add SSH key to multiple VMs
    $0 -u jane.smith -s "12345678-1234-1234-1234-123456789012" \\
       -k ~/.ssh/id_rsa.pub -g "myvm-rg" -v "vm01" -v "vm02" -v "vm03"

    # Command line mode - Dry run
    $0 -u john.doe -s "12345678-1234-1234-1234-123456789012" \\
       -k ~/.ssh/id_rsa.pub -g "myvm-rg" -v "myvm01" -d

    # CSV file mode - Batch processing
    $0 -f onboarding_batch.csv

**CSV File Format Example (onboarding_batch.csv):**
username,subscription_id,ssh_public_key,vm_resource_group,vm_names,dry_run
john.doe,12345678-1234-1234-1234-123456789012,~/.ssh/id_rsa.pub,prod-rg,"vm01,vm02",false
jane.smith,87654321-4321-4321-4321-210987654321,~/.ssh/jane_key.pub,test-rg,vm03,true
mike.wilson,11111111-2222-3333-4444-555555555555,"ssh-rsa AAAAB3Nz...",dev-rg,"vm04,vm05,vm06",false

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
    
    if [[ -z "$SSH_PUBLIC_KEY" ]]; then
        log "ERROR" "SSH public key is required"
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

# Manage SSH keys on Azure VMs (azroot account only)
manage_vm_ssh_access() {
    print_section "Managing VM SSH Access"
    
    local subscription_id="$1"
    local resource_group="$2"
    shift 2
    local vm_names=("$@")
    
    print_operation_status "SSH Key Management" "start" "Processing ${#vm_names[@]} VMs"
    
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
            print_operation_status "SSH Key Addition: $vm_name" "skip" "Dry run mode - would add SSH key to azroot account"
            log "INFO" "DRY RUN: Would add SSH key to $vm_name (azroot account)"
        else
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
    
    # Check if file exists
    if [[ ! -f "$csv_file" ]]; then
        log "ERROR" "CSV file does not exist: $csv_file"
        exit 1
    fi
    
    # Check if file is readable
    if [[ ! -r "$csv_file" ]]; then
        log "ERROR" "CSV file is not readable: $csv_file"
        exit 1
    fi
    
    # Count lines (excluding header)
    local line_count=$(tail -n +2 "$csv_file" | wc -l | xargs)
    if [[ $line_count -eq 0 ]]; then
        log "ERROR" "CSV file contains no data rows (only header or empty file)"
        exit 1
    fi
    
    log "SUCCESS" "CSV file validation completed - found $line_count data rows"
}

# Parse CSV file and process each row
process_csv_file() {
    local csv_file="$1"
    
    print_section "Processing CSV File: $csv_file"
    
    local line_number=1
    local processed_rows=0
    local failed_rows=0
    
    # Read CSV file line by line, skipping the header
    while IFS=',' read -r csv_username csv_subscription csv_ssh_key csv_resource_group csv_vm_names csv_dry_run || [[ -n "$csv_username" ]]; do
        # Skip header row
        if [[ $line_number -eq 1 ]]; then
            line_number=$((line_number + 1))
            continue
        fi
        
        # Skip empty lines
        if [[ -z "$csv_username" && -z "$csv_subscription" && -z "$csv_ssh_key" ]]; then
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
        csv_dry_run=$(echo "$csv_dry_run" | sed 's/^"//;s/"$//' | xargs)
        
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
        
        # Set dry run mode
        if [[ "$csv_dry_run" =~ ^[Tt][Rr][Uu][Ee]$ ]]; then
            DRY_RUN=true
        else
            DRY_RUN=false
        fi
        
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
    if ! manage_vm_ssh_access "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP" "${VM_NAMES[@]}"; then
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
    
    if [[ ${#VM_NAMES[@]} -eq 0 ]]; then
        log "ERROR" "At least one VM name is required (CSV column: vm_names)"
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
            -u)
                USER_NAME="$2"
                shift 2
                ;;
            -s)
                SUBSCRIPTION_ID="$2"
                shift 2
                ;;
            -k)
                SSH_PUBLIC_KEY="$2"
                shift 2
                ;;
            -g)
                VM_RESOURCE_GROUP="$2"
                shift 2
                ;;
            -v)
                VM_NAMES+=("$2")
                shift 2
                ;;
            -f)
                CSV_FILE="$2"
                shift 2
                ;;
            -d)
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
        
        # Process CSV file
        if process_csv_file "$CSV_FILE"; then
            log "SUCCESS" "CSV file processing completed successfully"
            exit 0
        else
            log "ERROR" "CSV file processing completed with errors"
            exit 1
        fi
    else
        # Command Line Mode
        print_section "Command Line Mode"
        log "INFO" "Processing SSH key onboarding from command line parameters"
        
        # Validate input
        validate_input
        
        # Validate SSH key
        validate_ssh_key "$SSH_PUBLIC_KEY"
        
        # Check VM permissions
        check_vm_permissions "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP"
        
        # Manage SSH access on VMs
        current_vm=0
        manage_vm_ssh_access "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP" "${VM_NAMES[@]}"
        
        # Generate summary
        generate_summary
    fi
}

# Run main function with all arguments
main "$@"