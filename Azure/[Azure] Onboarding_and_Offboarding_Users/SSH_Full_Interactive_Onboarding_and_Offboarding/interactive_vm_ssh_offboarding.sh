#!/bin/bash
# Azure VM SSH Key Offboarding Script
# Automates removing SSH keys from Azure VMs (azroot account)

set -euo pipefail

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
BACKUP_KEYS=true
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
- Remove specific SSH public keys from Azure VMs (azroot account)
- Support for multiple VMs or auto-discovery of all VMs in resource group
- Automatic backup of authorized_keys before modification
- Import parameters from CSV file for batch operations
- **FULLY INTERACTIVE MODE:** Run without parameters for guided setup

**INTERACTIVE MODE:**
Run the script without any parameters to be guided through:
- Azure subscription selection from available subscriptions
- Resource group selection from subscription (filtered to show only groups with VMs)
- VM selection from resource group (with multi-select support)
- SSH key configuration (file path, direct input, or default)
- Backup keys confirmation
- Dry-run mode selection

**COMMAND LINE MODE:**
Required Parameters (if not provided, interactive prompts will appear):
    -u, --username <username>       Username for identification
    -s, --subscription <id>         Azure subscription ID
    -k, --key <public_key>          SSH public key to remove (file path or key string)
    -g, --resource-group <name>     VM resource group name

Optional Parameters:
    -v, --vm <name>                 VM name (can be used multiple times for multiple VMs)
                                   If not specified, will discover all VMs in resource group
    -n, --no-backup                Skip backing up authorized_keys before modification
    -d, --dry-run                  Preview operations without making changes
    -f, --file <csv_file>          Process multiple users from CSV file
    -h, --help                     Display this help message

**CSV FILE MODE:**
Examples:
    # Interactive mode (recommended for first-time users)
    $0
    
    # Process single CSV file
    $0 -f offboarding_batch.csv
    
    # Process CSV file with dry-run
    $0 -f offboarding_batch.csv -d
    
    # Command line mode
    $0 -u john.doe -s 12345678-1234-1234-1234-123456789012 \\
       -k ~/.ssh/id_rsa.pub -g prod-rg -v vm01 -v vm02
    
    # Auto-discover all VMs in resource group
    $0 -u jane.smith -s 87654321-4321-4321-4321-210987654321 \\
       -k ~/.ssh/jane_key.pub -g staging-rg
    
    # Dry-run mode
    $0 -u test.user -s 11111111-2222-3333-4444-555555555555 \\
       -k "ssh-rsa AAAAB3Nz..." -g test-rg -d

**CSV File Format Example (offboarding_batch.csv):**
username,subscription_id,ssh_public_key,vm_resource_group,vm_names,backup_keys
john.doe,12345678-1234-1234-1234-123456789012,~/.ssh/id_rsa.pub,prod-rg,"vm01,vm02",true
jane.smith,87654321-4321-4321-4321-210987654321,~/.ssh/jane_key.pub,test-rg,vm03,false
mike.wilson,11111111-2222-3333-4444-555555555555,"ssh-rsa AAAAB3Nz...",dev-rg,"vm04,vm05",true
# Empty vm_names field will auto-discover all VMs in the resource group:
sara.jones,22222222-3333-4444-5555-666666666666,~/.ssh/sara_key.pub,staging-rg,,true

EOF
}

# Check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        echo -e "${RED}Error: Azure CLI not installed${NC}" >&2
        exit 1
    fi
    
    # Check if logged into Azure
    if ! az account show &> /dev/null; then
        echo -e "${RED}Error: Not logged into Azure${NC}" >&2
        exit 1
    fi

    # Check if Python 3 is installed (required for CSV parsing)
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Error: python3 not installed (required for CSV parsing)${NC}" >&2
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
    
    # VM names are optional - if empty, we'll discover all VMs in the resource group
    if [[ ${#VM_NAMES[@]:-0} -eq 0 ]]; then
        # Silent discovery - will be logged during actual discovery
        :
    fi
    
    if [[ -z "$SSH_PUBLIC_KEY" ]]; then
        log "ERROR" "SSH public key is required for offboarding operations. Use -k option."
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
    
    echo -e "${BLUE}Operation:${NC} Remove specific SSH key"
    echo -e "${BLUE}SSH Key:${NC} $(echo "$SSH_PUBLIC_KEY" | cut -c1-50)..."
    
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
    echo -e "${YELLOW}This will REMOVE the specified SSH key from the azroot account on the specified VMs.${NC}"
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

# Interactive function to get subscription ID
interactive_get_subscription() {
    print_section "Select Azure Subscription"
    
    log "INFO" "Fetching available subscriptions..."
    
    # Get subscriptions and format them for display
    local subscriptions_json
    subscriptions_json=$(az account list --output json 2>/dev/null) || {
        log "ERROR" "Failed to list Azure subscriptions. Please ensure you are logged in with 'az login'"
        exit 1
    }
    
    # Check if any subscriptions are available
    if [[ $(echo "$subscriptions_json" | jq 'length') -eq 0 ]]; then
        log "ERROR" "No subscriptions found. Please check your Azure access."
        exit 1
    fi
    
    # Display subscriptions
    echo -e "\n${BLUE}Available Subscriptions:${NC}"
    echo "────────────────────────────────────────────────────────────────"
    
    local subscription_ids=()
    local counter=1
    
    while IFS= read -r line; do
        local sub_id=$(echo "$line" | jq -r '.id')
        local sub_name=$(echo "$line" | jq -r '.name')
        local is_default=$(echo "$line" | jq -r '.isDefault')
        local state=$(echo "$line" | jq -r '.state')
        
        subscription_ids+=("$sub_id")
        
        if [[ "$is_default" == "true" ]]; then
            echo -e "$(printf "%2d)" "$counter") ${GREEN}$sub_name${NC} (${YELLOW}Default${NC})"
        else
            echo -e "$(printf "%2d)" "$counter") $sub_name"
        fi
        echo "     ID: $sub_id"
        echo "     State: $state"
        echo
        
        ((counter++))
    done < <(echo "$subscriptions_json" | jq -c '.[]')
    
    # Prompt for selection
    while true; do
        echo -n -e "${BLUE}Select subscription (1-$((counter-1))): ${NC}"
        read -r selection
        
        if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -lt "$counter" ]]; then
            SUBSCRIPTION_ID="${subscription_ids[$((selection-1))]}"
            local selected_name=$(echo "$subscriptions_json" | jq -r ".[$((selection-1))].name")
            log "INFO" "Selected subscription: $selected_name ($SUBSCRIPTION_ID)"
            break
        else
            echo -e "${RED}Invalid selection. Please enter a number between 1 and $((counter-1)).${NC}"
        fi
    done
}

# Interactive function to get username
interactive_get_username() {
    print_section "User Identification" "$GREEN"
    while [[ -z "$USER_NAME" ]]; do
        read -r -p "Enter username for identification: " USER_NAME
        if [[ -z "$USER_NAME" ]]; then
            echo -e "${RED}❌ Username cannot be empty${NC}"
        fi
    done
    echo -e "${GREEN}✅ Username: $USER_NAME${NC}"
    echo
}

# Interactive function to get SSH public key
interactive_get_ssh_key() {
    print_section "SSH Public Key Selection"
    
    echo -e "${BLUE}SSH Key Options:${NC}"
    echo "1) Enter path to SSH public key file"
    echo "2) Paste SSH public key directly"
    echo "3) Use default key (~/.ssh/id_rsa.pub)"
    echo
    
    while [[ -z "$SSH_PUBLIC_KEY" ]]; do
        echo -n -e "${BLUE}Select option (1-3): ${NC}"
        read -r key_option
        
        case "$key_option" in
            1)
                echo -n -e "${BLUE}Enter path to SSH public key file: ${NC}"
                read -r key_path
                if [[ -f "$key_path" ]]; then
                    SSH_PUBLIC_KEY="$key_path"
                    log "INFO" "SSH key file set to: $key_path"
                else
                    echo -e "${RED}File not found: $key_path${NC}"
                fi
                ;;
            2)
                echo -e "${BLUE}Paste your SSH public key (press Enter when done):${NC}"
                read -r SSH_PUBLIC_KEY
                if [[ -n "$SSH_PUBLIC_KEY" ]]; then
                    log "INFO" "SSH public key entered directly"
                else
                    echo -e "${RED}SSH key cannot be empty. Please try again.${NC}"
                fi
                ;;
            3)
                local default_key="~/.ssh/id_rsa.pub"
                if [[ -f "${default_key/#\~/$HOME}" ]]; then
                    SSH_PUBLIC_KEY="$default_key"
                    log "INFO" "Using default SSH key: $default_key"
                else
                    echo -e "${RED}Default key file not found: $default_key${NC}"
                fi
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1, 2, or 3.${NC}"
                ;;
        esac
    done
}

# Interactive function to get resource group
interactive_get_resource_group() {
    print_section "Select Resource Group"
    
    log "INFO" "Fetching resource groups for subscription..."
    
    # Get resource groups
    local resource_groups_json
    resource_groups_json=$(az group list --subscription "$SUBSCRIPTION_ID" --output json 2>/dev/null) || {
        log "ERROR" "Failed to list resource groups for subscription: $SUBSCRIPTION_ID"
        exit 1
    }
    
    # Check if any resource groups are available
    if [[ $(echo "$resource_groups_json" | jq 'length') -eq 0 ]]; then
        log "ERROR" "No resource groups found in subscription: $SUBSCRIPTION_ID"
        exit 1
    fi
    
    # Filter resource groups to only show those with VMs using Azure Resource Graph
    log "INFO" "Fetching VMs across all resource groups (single API call)..."
    echo -e "${BLUE}Finding resource groups with VMs...${NC}"
    
    # Use Azure Resource Graph to get all VMs and their resource groups in one query
    local vm_by_rg_json
    vm_by_rg_json=$(az graph query -q "Resources | where type == 'microsoft.compute/virtualmachines' | where subscriptionId == '$SUBSCRIPTION_ID' | summarize VMCount=count() by resourceGroup | project resourceGroup, VMCount" --output json 2>/dev/null) || {
        log "ERROR" "Azure Resource Graph query failed. Please ensure you have the necessary permissions."
        exit 1
    }
    
    # Process Resource Graph results
    local resource_groups_with_vms=()
    
    # Check if we have data in the response
    if [[ $(echo "$vm_by_rg_json" | jq '.data | length') -eq 0 ]]; then
        log "WARNING" "No VMs found in subscription: $SUBSCRIPTION_ID"
    fi
    
    # Process VM counts by resource group and merge with location info
    while IFS= read -r vm_line; do
        # Azure Resource Graph returns data as objects with resourceGroup and VMCount properties
        local rg_name=$(echo "$vm_line" | jq -r '.resourceGroup')
        local vm_count=$(echo "$vm_line" | jq -r '.VMCount')
        
        # Skip if values are null or empty
        if [[ "$rg_name" == "null" || "$rg_name" == "" || "$vm_count" == "null" || "$vm_count" == "" ]]; then
            continue
        fi
        
        local rg_location="Unknown"
        
        # Find matching location from resource groups list
        while IFS= read -r rg_line; do
            local rg_list_name=$(echo "$rg_line" | jq -r '.name')
            if [[ "$rg_list_name" == "$rg_name" ]]; then
                rg_location=$(echo "$rg_line" | jq -r '.location')
                break
            fi
        done < <(echo "$resource_groups_json" | jq -c '.[]')
        
        resource_groups_with_vms+=("$rg_name|$rg_location|$vm_count")
    done < <(echo "$vm_by_rg_json" | jq -c '.data[]')
    
    # Check if any resource groups with VMs were found
    if [[ ${#resource_groups_with_vms[@]} -eq 0 ]]; then
        log "WARNING" "No resource groups with VMs found in subscription: $SUBSCRIPTION_ID"
        echo -e "${YELLOW}No resource groups containing VMs were found.${NC}"
        echo -n -e "${BLUE}Do you want to enter a resource group name manually? (y/n): ${NC}"
        read -r continue_choice
        if [[ "$continue_choice" != "y" && "$continue_choice" != "Y" ]]; then
            log "INFO" "Operation cancelled by user"
            exit 0
        else
            echo -n -e "${BLUE}Enter resource group name: ${NC}"
            read -r VM_RESOURCE_GROUP
            if [[ -n "$VM_RESOURCE_GROUP" ]]; then
                log "INFO" "Custom resource group entered: $VM_RESOURCE_GROUP"
                return 0
            else
                echo -e "${RED}Resource group name cannot be empty.${NC}"
                exit 1
            fi
        fi
    fi
    
    # Display resource groups with VMs
    echo -e "${BLUE}Available Resource Groups (containing VMs):${NC}"
    echo "────────────────────────────────────────────────────────────────"
    
    local resource_group_names=()
    local counter=1
    
    for rg_info in "${resource_groups_with_vms[@]}"; do
        IFS='|' read -r rg_name rg_location vm_count <<< "$rg_info"
        resource_group_names+=("$rg_name")
        
        echo -e "$(printf "%2d" "$counter")) ${GREEN}$rg_name${NC}"
        echo "     Location: $rg_location"
        echo "     VMs: $vm_count"
        echo
        
        ((counter++))
    done
    
    # Add option to enter custom resource group
    echo -e "${counter}) ${YELLOW}Enter custom resource group name${NC}"
    echo
    
    # Prompt for selection
    while true; do
        echo -n -e "${BLUE}Select resource group (1-${counter}): ${NC}"
        read -r selection
        
        if [[ "$selection" =~ ^[0-9]+$ ]]; then
            if [[ "$selection" -ge 1 ]] && [[ "$selection" -lt "$counter" ]]; then
                VM_RESOURCE_GROUP="${resource_group_names[$((selection-1))]}"
                log "INFO" "Selected resource group: $VM_RESOURCE_GROUP"
                break
            elif [[ "$selection" -eq "$counter" ]]; then
                echo -n -e "${BLUE}Enter resource group name: ${NC}"
                read -r VM_RESOURCE_GROUP
                if [[ -n "$VM_RESOURCE_GROUP" ]]; then
                    log "INFO" "Custom resource group entered: $VM_RESOURCE_GROUP"
                    break
                else
                    echo -e "${RED}Resource group name cannot be empty. Please try again.${NC}"
                fi
            else
                echo -e "${RED}Invalid selection. Please enter a number between 1 and ${counter}.${NC}"
            fi
        else
            echo -e "${RED}Invalid input. Please enter a valid number.${NC}"
        fi
    done
}

# Interactive function to get VM names
interactive_get_vm_names() {
    print_section "Select Virtual Machines"
    
    log "INFO" "Fetching VMs in resource group: $VM_RESOURCE_GROUP"
    
    # Get VMs in the resource group (we already know VMs exist from the filtering)
    local vms_json
    vms_json=$(az vm list --resource-group "$VM_RESOURCE_GROUP" --subscription "$SUBSCRIPTION_ID" --output json 2>/dev/null) || {
        log "ERROR" "Failed to list VMs in resource group: $VM_RESOURCE_GROUP"
        exit 1
    }
    
    # Display VMs
    echo -e "\n${BLUE}Available Virtual Machines:${NC}"
    echo "────────────────────────────────────────────────────────────────"
    
    local vm_names_list=()
    local counter=1
    
    while IFS= read -r line; do
        local vm_name=$(echo "$line" | jq -r '.name')
        local vm_size=$(echo "$line" | jq -r '.hardwareProfile.vmSize')
        local vm_state=$(echo "$line" | jq -r '.provisioningState // "Unknown"')
        
        vm_names_list+=("$vm_name")
        
        echo -e "$(printf "%2d" "$counter")) $vm_name"
        echo "     Size: $vm_size, State: $vm_state"
        echo
        
        ((counter++))
    done < <(echo "$vms_json" | jq -c '.[]')
    
    # Add options for all VMs or custom selection
    echo -e "${counter}) ${GREEN}Select ALL VMs in resource group${NC}"
    echo -e "$((counter+1))) ${YELLOW}Enter custom VM names${NC}\n"
    
    # Prompt for selection
    echo -e "${BLUE}You can select multiple VMs by entering numbers separated by commas (e.g., 1,3,5)${NC}"
    while true; do
        echo -n -e "${BLUE}Select VMs (1-$((counter+1))) or 'all' for all VMs: ${NC}"
        read -r selection
        
        if [[ "$selection" == "all" || "$selection" == "$counter" ]]; then
            # Select all VMs
            VM_NAMES=("${vm_names_list[@]}")
            log "INFO" "Selected all VMs: ${VM_NAMES[*]}"
            break
        elif [[ "$selection" == "$((counter+1))" ]]; then
            # Custom VM names
            echo -n -e "${BLUE}Enter VM names separated by commas: ${NC}"
            read -r custom_vms
            IFS=',' read -ra VM_NAMES <<< "$custom_vms"
            # Trim whitespace
            for i in "${!VM_NAMES[@]}"; do
                VM_NAMES[i]=$(echo "${VM_NAMES[i]}" | xargs)
            done
            log "INFO" "Custom VMs entered: ${VM_NAMES[*]}"
            break
        else
            # Parse comma-separated selections
            IFS=',' read -ra selections <<< "$selection"
            local valid_selection=true
            VM_NAMES=()
            
            for sel in "${selections[@]}"; do
                sel=$(echo "$sel" | xargs)  # Trim whitespace
                if [[ "$sel" =~ ^[0-9]+$ ]] && [[ "$sel" -ge 1 ]] && [[ "$sel" -lt "$counter" ]]; then
                    VM_NAMES+=("${vm_names_list[$((sel-1))]}")
                else
                    echo -e "${RED}Invalid selection: $sel${NC}"
                    valid_selection=false
                    break
                fi
            done
            
            if [[ "$valid_selection" == "true" && ${#VM_NAMES[@]} -gt 0 ]]; then
                log "INFO" "Selected VMs: ${VM_NAMES[*]}"
                break
            elif [[ "$valid_selection" == "true" ]]; then
                echo -e "${RED}No valid VMs selected. Please try again.${NC}"
            fi
        fi
    done
}

# Interactive function to confirm backup keys
interactive_get_backup_confirmation() {
    print_section "Backup Configuration" "$GREEN"
    echo "Before removing SSH keys, we can backup the current authorized_keys file."
    echo "This creates a timestamped backup for recovery purposes."
    echo
    
    while true; do
        read -r -p "Create backup of authorized_keys before modification? [Y/n]: " backup_choice
        backup_choice=${backup_choice:-Y}  # Default to Y if empty
        
        case "$backup_choice" in
            [Yy]|[Yy][Ee][Ss])
                BACKUP_KEYS=true
                echo -e "${GREEN}✅ Will create backup before removing keys${NC}"
                break
                ;;
            [Nn]|[Nn][Oo])
                BACKUP_KEYS=false
                echo -e "${YELLOW}⚠️  Will NOT create backup (proceed with caution)${NC}"
                break
                ;;
            *)
                echo -e "${RED}❌ Please enter Y (yes) or N (no)${NC}"
                ;;
        esac
    done
    echo
}

# Interactive function to confirm dry run mode
interactive_get_dry_run() {
    print_section "Execution Mode" "$GREEN"
    while true; do
        read -r -p "Run in dry-run mode (preview operations without making changes)? [y/N]: " dry_run_choice
        dry_run_choice=${dry_run_choice:-N}  # Default to N if empty
        
        case "$dry_run_choice" in
            [Yy]|[Yy][Ee][Ss])
                DRY_RUN=true
                echo -e "${YELLOW}⚠️  Dry-run mode enabled - no changes will be made${NC}"
                break
                ;;
            [Nn]|[Nn][Oo])
                DRY_RUN=false
                echo -e "${GREEN}✅ Live mode - changes will be applied${NC}"
                break
                ;;
            *)
                echo -e "${RED}❌ Please enter Y (yes) or N (no)${NC}"
                ;;
        esac
    done
    echo
}

# Remove SSH keys from Azure VMs (azroot account only)
remove_vm_ssh_access() {
    print_section "Removing VM SSH Access"
    
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
        local operation_type="SSH Key Removal"
        
        if ! prompt_for_confirmation "$operation_type" "${#vm_names[@]}" "$vm_list_str"; then
            log "INFO" "Operation cancelled by user"
            return 1
        fi
    fi
    
    print_operation_status "SSH Key Removal" "start" "Processing ${#vm_names[@]} VMs"
    
    for vm_name in "${vm_names[@]}"; do
        print_progress "$((++current_vm))" "${#vm_names[@]}" "Processing VM: $vm_name"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            print_operation_status "SSH Key Removal: $vm_name" "skip" "Dry run mode - would remove specific SSH key from azroot account"
            log_only "INFO" "DRY RUN: Would remove specific SSH key from $vm_name (azroot account)"

        else
            # Check if VM exists and is running (only in non-dry-run mode)
            local vm_status=$(az vm get-instance-view --resource-group "$resource_group" --name "$vm_name" \
                             --query "instanceView.statuses[?code=='PowerState/running']" -o tsv 2>/dev/null || echo "")
            
            if [[ -z "$vm_status" ]]; then
                print_operation_status "VM Check: $vm_name" "error" "VM not found or not running"
                log "ERROR" "VM $vm_name is not running or does not exist in resource group $resource_group"
                continue
            fi
            
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
    
    # Base64-encode SSH public key to safely embed it in the generated script
    local SSH_KEY_B64
    SSH_KEY_B64="$(printf '%s' "$SSH_PUBLIC_KEY" | base64 | tr -d '\n')"
    
    # Create script to remove specific SSH key
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
    
    print_operation_status "SSH Key Removal: $vm_name" "start" "Removing specific key from azroot account"
    
    # Execute the script on the VM
    local run_result=$(az vm run-command invoke \
        --resource-group "$resource_group" \
        --name "$vm_name" \
        --command-id RunShellScript \
        --scripts @"$temp_script" \
        --output json 2>&1)
    
    if [[ $? -eq 0 ]]; then
        print_operation_status "SSH Key Removal: $vm_name" "success" "SSH key removed from azroot account"
        log "SUCCESS" "Removed specific SSH key from $vm_name (azroot account)"
    else
        print_operation_status "SSH Key Removal: $vm_name" "error" "Failed to remove SSH key"
        log "ERROR" "Failed to remove SSH key from $vm_name: $run_result"
    fi
}

# Validate CSV file format and content
validate_csv_file() {
    local csv_file="$1"
    
    print_section "Validating CSV File"
    
    # Safely expand tilde in the path
    csv_file="${csv_file/#\~/$HOME}"
    
    # Safely expand environment variables in the path, if envsubst is available  
    if command -v envsubst >/dev/null 2>&1; then  
        csv_file="$(printf '%s' "$csv_file" | envsubst)"  
    fi
    
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
        csv_backup="${field_array[5]:-}"
        
        # Skip rows with empty essential fields
        if [[ -z "$csv_username" && -z "$csv_subscription" && -z "$csv_resource_group" ]]; then
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
                VM_NAMES[i]=$(echo "${VM_NAMES[i]}" | sed "s/^'\|'$//g" | xargs)
            done
        else
            VM_NAMES=()
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

# Process a single offboarding operation (used by CSV processing)
process_single_operation() {
    local operation_failed=false
    
    # Validate input for current operation
    if ! validate_input_for_row; then
        return 1
    fi
    
    # Validate SSH key for current operation (only if not removing all keys and SSH key is provided)
    # Validate SSH key if provided
    if [[ -n "$SSH_PUBLIC_KEY" ]]; then
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
    if ! remove_vm_ssh_access "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP" "${VM_NAMES[@]:-}"; then
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
    
    # VM names are optional - if empty, we'll discover all VMs in the resource group
    if [[ ${#VM_NAMES[@]:-0} -eq 0 ]]; then
        # Silent discovery - will be logged during actual discovery
        :
    fi
    
    # Check that SSH key is provided
    if [[ -z "$SSH_PUBLIC_KEY" ]]; then
        log "ERROR" "SSH public key is required (CSV column: ssh_public_key)"
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
    # Store original parameter count to detect interactive mode
    local original_param_count=$#
    
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
    
    # Determine mode: CSV file, command line parameters, or interactive
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
    elif [[ $original_param_count -eq 0 ]]; then
        # Interactive Mode (no parameters provided)
        print_section "🔧 Azure VM SSH Key Offboarding - Interactive Mode" "$GREEN"
        echo -e "${GREEN}Welcome to the interactive SSH key offboarding tool!${NC}"
        echo "This tool will guide you through removing SSH keys from Azure VMs."
        echo
        log "INFO" "Starting interactive mode"
        
        # Interactive prompts
        interactive_get_subscription
        interactive_get_username
        interactive_get_ssh_key
        interactive_get_resource_group
        interactive_get_vm_names
        interactive_get_backup_confirmation
        interactive_get_dry_run
        
        # Validate SSH key
        validate_ssh_key
        
        # Check VM permissions
        check_vm_permissions "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP"
        
        # Show configuration summary and ask for confirmation
        print_section "Configuration Summary" "$BLUE"
        echo -e "${BLUE}Username:${NC} $USER_NAME"
        echo -e "${BLUE}Subscription ID:${NC} $SUBSCRIPTION_ID"
        echo -e "${BLUE}Resource Group:${NC} $VM_RESOURCE_GROUP"
        echo -e "${BLUE}Target VMs:${NC} ${VM_NAMES[*]}"
        echo -e "${BLUE}Backup Keys:${NC} $BACKUP_KEYS"
        echo -e "${BLUE}Dry Run Mode:${NC} $DRY_RUN"
        echo
        
        if ! prompt_for_confirmation; then
            echo -e "${YELLOW}⚠️  Operation cancelled by user${NC}"
            exit 0
        fi
        
        # Remove SSH access from VMs
        current_vm=0
        remove_vm_ssh_access "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP" "${VM_NAMES[@]:-}"
        
        # Generate summary
        generate_summary
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
        remove_vm_ssh_access "$SUBSCRIPTION_ID" "$VM_RESOURCE_GROUP" "${VM_NAMES[@]:-}"
        
        # Generate summary
        generate_summary
    fi
}

main "$@"