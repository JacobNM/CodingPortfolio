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
Usage: $0 -u <username> -s <subscription_id> -k <ssh_public_key> -g <vm_resource_group> -v <vm_name> [OPTIONS]

**FUNCTIONALITY:**
- Add SSH public keys to Azure VMs (azroot account)
- Support for multiple VMs

Required Parameters:
    -u <username>           Username for identification
    -s <subscription_id>    Azure subscription ID
    -k <ssh_public_key>     SSH public key file path or key content
    -g <vm_resource_group>  Resource group containing VMs
    -v <vm_name>           VM name (can be specified multiple times)

Optional Parameters:
    -d                     Dry run mode (show what would be done)
    -h                     Display this help message

Examples:
    # Add SSH key to single VM
    $0 -u john.doe -s "12345678-1234-1234-1234-123456789012" \\
       -k ~/.ssh/id_rsa.pub -g "myvm-rg" -v "myvm01"

    # Add SSH key to multiple VMs
    $0 -u jane.smith -s "12345678-1234-1234-1234-123456789012" \\
       -k ~/.ssh/id_rsa.pub -g "myvm-rg" -v "vm01" -v "vm02" -v "vm03"

    # Dry run mode
    $0 -u john.doe -s "12345678-1234-1234-1234-123456789012" \\
       -k ~/.ssh/id_rsa.pub -g "myvm-rg" -v "myvm01" -d

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
    
    # Validate input
    validate_input
    
    # Validate SSH key
    validate_ssh_key "$SSH_PUBLIC_KEY"
    
    # Check prerequisites
    check_prerequisites
    
    # Check VM permissions
    check_vm_permissions "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP"
    
    # Manage SSH access on VMs
    current_vm=0
    manage_vm_ssh_access "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP" "${VM_NAMES[@]}"
    
    # Generate summary
    generate_summary
}

# Run main function with all arguments
main "$@"