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
DRY_RUN=false
VM_RESOURCE_GROUP=""
VM_NAMES=()
SSH_PUBLIC_KEY=""
REMOVE_ALL_KEYS=false
BACKUP_KEYS=true

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
Usage: $0 -u <username> -s <subscription_id> -g <vm_resource_group> -v <vm_name> [OPTIONS]

**FUNCTIONALITY:**
- Remove specific SSH public keys from Azure VMs (azroot account)
- Remove all SSH keys from Azure VMs (azroot account)
- Support for multiple VMs
- Automatic backup of authorized_keys before modification

Required Parameters:
    -u <username>           Username for identification
    -s <subscription_id>    Azure subscription ID
    -g <vm_resource_group>  Resource group containing VMs
    -v <vm_name>           VM name (can be specified multiple times)

Optional Parameters:
    -k <ssh_public_key>    Specific SSH public key to remove (file path or key content)
    -a                     Remove ALL SSH keys from azroot account
    -n                     No backup (skip backup of authorized_keys)
    -d                     Dry run mode (show what would be done)
    -h                     Display this help message

Examples:
    # Remove specific SSH key from single VM
    $0 -u john.doe -s "12345678-1234-1234-1234-123456789012" \\
       -k ~/.ssh/id_rsa.pub -g "myvm-rg" -v "myvm01"

    # Remove ALL SSH keys from multiple VMs
    $0 -u jane.smith -s "12345678-1234-1234-1234-123456789012" \\
       -g "myvm-rg" -v "vm01" -v "vm02" -v "vm03" -a

    # Dry run mode
    $0 -u john.doe -s "12345678-1234-1234-1234-123456789012" \\
       -k ~/.ssh/id_rsa.pub -g "myvm-rg" -v "myvm01" -d

    # Remove specific key without backup
    $0 -u john.doe -s "12345678-1234-1234-1234-123456789012" \\
       -k ~/.ssh/id_rsa.pub -g "myvm-rg" -v "myvm01" -n

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
            -a)
                REMOVE_ALL_KEYS=true
                shift
                ;;
            -n)
                BACKUP_KEYS=false
                shift
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
    echo "SSH Key Offboarding Log - $(date)" > "$LOG_FILE"
    log "INFO" "Starting SSH key offboarding script"
    
    # Validate input
    validate_input
    
    # Validate SSH key (if provided)
    validate_ssh_key
    
    # Check prerequisites
    check_prerequisites
    
    # Check VM permissions
    check_vm_permissions "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP"
    
    # Remove SSH access from VMs
    current_vm=0
    remove_vm_ssh_access "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP" "${VM_NAMES[@]}"
    
    # Generate summary
    generate_summary
}

# Run main function with all arguments
main "$@"