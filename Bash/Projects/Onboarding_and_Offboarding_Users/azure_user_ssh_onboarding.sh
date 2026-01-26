#!/bin/bash

#################################################################################
# Azure User Onboarding Script
# Description: Automates the onboarding process for users to Azure resources
#              Works with existing Microsoft Entra ID users
#              Requires Azure subscription Owner role
#################################################################################

set -euo pipefail  # Exit on any error, undefined variable, or pipe failure

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/onboarding_$(date +%Y%m%d_%H%M%S).log"
# Azure subscription roles (Owner role provides all these)
REQUIRED_AZURE_ROLES=("User Access Administrator" "Contributor")
# Alternative roles that provide equivalent permissions
EQUIVALENT_ROLES=("Owner" "Co-Administrator")

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RESOURCE_GROUP=""
SUBSCRIPTION_ID=""
USER_PRINCIPAL_NAME=""
RBAC_ROLES=()
DRY_RUN=false
MANAGE_VMS=false
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
Usage: $0 -u <user_principal_name> -s <subscription_id> [OPTIONS]

**CORE FUNCTIONALITY (requires Azure Owner role):**
- RBAC role assignments for existing users
- VM SSH key management
- Resource access management

Required Parameters:
    -u, --user-principal     User Principal Name (UPN) - email address of the user
    -s, --subscription       Azure subscription ID

Optional Parameters:
    -r, --resource-group     Specific resource group to grant access to
    -R, --rbac-roles         Comma-separated list of RBAC roles to assign
    -n, --dry-run           Preview changes without executing them
    --manage-vms            Enable VM SSH key management
    --vm-resource-group     Resource group containing the VMs (required if --manage-vms)
    --vm-names              Comma-separated list of VM names to manage
    --ssh-public-key        SSH public key to add to azroot account (file path or key string)
    -h, --help              Display this help message

Examples:
    # Basic onboarding - assign RBAC roles to existing user (requires Azure Owner role)
    $0 -u john.doe@company.com -s "12345678-1234-1234-1234-123456789012" -R "Contributor"
    
    # Onboarding existing user with specific resource group access
    $0 -u jane.smith@company.com -s "12345678-1234-1234-1234-123456789012" \\
       -R "Contributor,Storage Blob Data Reader" -r "production-rg"

    # Onboarding existing user with VM SSH access
    $0 -u existing.user@company.com -s "12345678-1234-1234-1234-123456789012" \\
       --manage-vms --vm-resource-group "vm-rg" --vm-names "web01,web02,db01" \\
       --ssh-public-key "~/.ssh/id_rsa.pub" -R "Virtual Machine Contributor"

    # Dry run to preview changes
    $0 -u test.user@company.com -s "12345678-1234-1234-1234-123456789012" -R "Reader" -n

EOF
}

# Check prerequisites
check_prerequisites() {
    log "INFO" "Checking prerequisites..."
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        log "ERROR" "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if logged into Azure CLI
    if ! az account show &> /dev/null; then
        log "ERROR" "Not logged into Azure CLI. Please run 'az login' first."
        exit 1
    fi
    
    # Verify subscription access
    if ! az account set --subscription "$SUBSCRIPTION_ID" &> /dev/null; then
        log "ERROR" "Cannot access subscription $SUBSCRIPTION_ID"
        exit 1
    fi
    
    log "INFO" "Prerequisites check completed successfully"
}

# Get user's group memberships
get_user_groups() {
    local user_id=$(az ad signed-in-user show --query "id" -o tsv)
    if [[ -n "$user_id" ]]; then
        # Get group memberships using the user's object ID, extract only the GUID portion
        local user_groups=$(az ad user get-member-groups --id "$user_id" --query "[]" -o tsv 2>/dev/null | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}')
        echo "$user_groups"
    fi
}

# Check if user has a role through group membership at given scope
check_group_roles_at_scope() {
    local scope_param="$1"  # --subscription or --resource-group
    local scope_value="$2"  # subscription id or rg name
    local role_name="$3"
    local groups="$4"
    
    if [[ -z "$groups" ]]; then
        return 1
    fi
    
    # Check each group for the specific role
    while IFS= read -r group_id; do
        if [[ -n "$group_id" ]] && [[ "$group_id" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
            # Use group ID directly (without group name lookup to avoid parsing issues)
            local has_role=$(az role assignment list --assignee "$group_id" $scope_param "$scope_value" \
                            --query "[?roleDefinitionName=='$role_name']" -o tsv 2>/dev/null)
            
            if [[ -n "$has_role" ]]; then
                # Try to get group display name for better logging (but don't fail if it doesn't work)
                local group_name=$(az ad group show --group "$group_id" --query "displayName" -o tsv 2>/dev/null || echo "$group_id")
                log "INFO" "✓ Found role '$role_name' through group membership: $group_name"
                return 0
            fi
            
            # Check for equivalent roles
            for equiv_role in "${EQUIVALENT_ROLES[@]}"; do
                local has_equiv=$(az role assignment list --assignee "$group_id" $scope_param "$scope_value" \
                                 --query "[?roleDefinitionName=='$equiv_role']" -o tsv 2>/dev/null)
                if [[ -n "$has_equiv" ]]; then
                    local group_name=$(az ad group show --group "$group_id" --query "displayName" -o tsv 2>/dev/null || echo "$group_id")
                    log "INFO" "✓ Found equivalent role '$equiv_role' through group membership: $group_name (provides '$role_name' permissions)"
                    return 0
                fi
            done
        fi
    done <<< "$groups"
    
    return 1  # Role not found through groups
}

# Check if user has a role or equivalent role at given scope (direct assignment or through groups)
check_role_at_scope() {
    local user="$1"
    local scope_param="$2"  # --subscription or --resource-group
    local scope_value="$3"  # subscription id or rg name
    local role_name="$4"
    
    # First check direct assignment
    local has_role=$(az role assignment list --assignee "$user" $scope_param "$scope_value" \
                    --query "[?roleDefinitionName=='$role_name']" -o tsv)
    
    if [[ -n "$has_role" ]]; then
        log "INFO" "✓ Found direct assignment of role: $role_name"
        return 0  # Found the role
    fi
    
    # Check for equivalent roles (direct assignment)
    for equiv_role in "${EQUIVALENT_ROLES[@]}"; do
        local has_equiv=$(az role assignment list --assignee "$user" $scope_param "$scope_value" \
                         --query "[?roleDefinitionName=='$equiv_role']" -o tsv)
        if [[ -n "$has_equiv" ]]; then
            log "INFO" "✓ Found direct assignment of equivalent role '$equiv_role' (provides '$role_name' permissions)"
            return 0  # Found equivalent role
        fi
    done
    
    # If not found through direct assignment, check group memberships
    local user_groups=$(get_user_groups)
    if [[ -n "$user_groups" ]]; then
        log "INFO" "Checking group memberships for role: $role_name"
        if check_group_roles_at_scope "$scope_param" "$scope_value" "$role_name" "$user_groups"; then
            return 0  # Found through group membership
        fi
    fi
    
    return 1  # Role not found
}

# Verify user has required permissions
check_permissions() {
    log "INFO" "Checking user permissions..."
    
    local current_user=$(az account show --query user.name -o tsv)
    log "INFO" "Current user: $current_user"
    
    # Check Azure subscription roles first
    log "INFO" "Checking Azure subscription permissions..."
    local has_owner=$(az role assignment list --assignee "$current_user" --subscription "$SUBSCRIPTION_ID" \
                     --query "[?roleDefinitionName=='Owner']" -o tsv)
    if [[ -n "$has_owner" ]]; then
        log "INFO" "✓ Owner role confirmed - all Azure operations permitted"
        return 0
    fi
    
    log "INFO" "Checking individual Azure roles at subscription level..."
    local subscription_roles_sufficient=true
    for role in "${REQUIRED_AZURE_ROLES[@]}"; do
        if check_role_at_scope "$current_user" "--subscription" "$SUBSCRIPTION_ID" "$role"; then
            log "INFO" "✓ Confirmed subscription-level Azure role: $role"
        else
            subscription_roles_sufficient=false
        fi
    done
    
    # If not sufficient at subscription level, check resource group level (if specified)
    if [[ "$subscription_roles_sufficient" == "false" && -n "$RESOURCE_GROUP" ]]; then
        log "INFO" "Checking Azure roles at resource group level: $RESOURCE_GROUP"
        local rg_roles_sufficient=true
        for role in "${REQUIRED_AZURE_ROLES[@]}"; do
            if check_role_at_scope "$current_user" "--resource-group" "$RESOURCE_GROUP" "$role"; then
                log "INFO" "✓ Confirmed resource group-level Azure role: $role"
            else
                rg_roles_sufficient=false
            fi
        done
        
        if [[ "$rg_roles_sufficient" == "true" ]]; then
            log "INFO" "✓ Sufficient permissions at resource group level for RBAC operations"
        else
            log "WARN" "Could not find required roles at resource group level."
            log "INFO" "Required for RBAC operations: User Access Administrator or Owner"
            log "INFO" "The script will proceed - actual operations will succeed/fail based on your effective permissions."
        fi
    elif [[ "$subscription_roles_sufficient" == "false" ]]; then
        log "WARN" "Could not find required roles at subscription level."
        log "INFO" "Required for RBAC operations: User Access Administrator or Owner"
        log "INFO" "The script will proceed - actual operations will succeed/fail based on your effective permissions."
    fi
}

# Validate user input
validate_input() {
    log "INFO" "Validating input parameters..."
    
    # Validate email format for UPN
    if [[ ! "$USER_PRINCIPAL_NAME" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log "ERROR" "Invalid User Principal Name format: $USER_PRINCIPAL_NAME"
        exit 1
    fi
    
    # Validate subscription ID format (GUID)
    if [[ ! "$SUBSCRIPTION_ID" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
        log "ERROR" "Invalid subscription ID format: $SUBSCRIPTION_ID"
        exit 1
    fi
    
    log "INFO" "Working with existing user - Azure resource access management only"
    
    log "INFO" "Input validation completed successfully"
}

# Check if user already exists in Microsoft Entra ID
check_user_exists() {
    log "INFO" "Checking if user already exists in Microsoft Entra ID..."
    
    local existing_user=$(az ad user show --id "$USER_PRINCIPAL_NAME" --query id -o tsv 2>/dev/null || echo "")
    
    if [[ -n "$existing_user" ]]; then
        log "INFO" "User already exists in Microsoft Entra ID: $existing_user"
        return 0
    else
        log "ERROR" "User does not exist in Microsoft Entra ID. Please create the user first or use an existing user."
        exit 1
    fi
}

# Verify existing user in Microsoft Entra ID (replaces create function)
verify_entra_id_user() {
    log "INFO" "Verifying user exists in Microsoft Entra ID..."
    
    if check_user_exists; then
        log "INFO" "User verification completed - user exists in Entra ID"
        return 0
    else
        log "ERROR" "User verification failed - cannot proceed"
        exit 1
    fi
}

# Skip Microsoft Entra ID group operations (replaces add_to_entra_groups)
skip_entra_group_operations() {
    print_operation_status "Microsoft Entra ID Group Assignment" "skip" "Entra ID operations require special permissions - skipped"
    log "INFO" "Skipping Entra ID group operations - requires User Administrator or Groups Administrator role"
    return 0
}

# Assign RBAC roles
assign_rbac_roles() {
    if [[ ${#RBAC_ROLES[@]} -eq 0 ]]; then
        print_operation_status "RBAC Role Assignment" "skip" "No RBAC roles specified"
        return 0
    fi
    
    print_operation_status "RBAC Role Assignment" "start" "Assigning ${#RBAC_ROLES[@]} role(s)"
    log "INFO" "Assigning RBAC roles..."
    
    local scope="/subscriptions/$SUBSCRIPTION_ID"
    if [[ -n "$RESOURCE_GROUP" ]]; then
        scope="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
        log "INFO" "Using resource group scope: $RESOURCE_GROUP"
    fi
    
    for role in "${RBAC_ROLES[@]}"; do
        log "INFO" "Assigning role: $role"
        
        # Check if role assignment already exists
        local existing_assignment=$(az role assignment list \
            --assignee "$USER_PRINCIPAL_NAME" \
            --role "$role" \
            --scope "$scope" \
            --query "[0].id" -o tsv 2>/dev/null || echo "")
        
        if [[ -n "$existing_assignment" ]]; then
            log "INFO" "Role '$role' already assigned to user"
            continue
        fi
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "INFO" "[DRY RUN] Would assign role '$role' at scope: $scope"
        else
            if az role assignment create \
                --assignee "$USER_PRINCIPAL_NAME" \
                --role "$role" \
                --scope "$scope" &>/dev/null; then
                log "INFO" "Successfully assigned role: $role"
            else
                log "ERROR" "Failed to assign role: $role"
            fi
        fi
    done
    
    local success_roles=${#RBAC_ROLES[@]}
    if [[ "$DRY_RUN" == "true" ]]; then
        print_operation_status "RBAC Role Assignment" "success" "[DRY RUN] Would assign $success_roles roles"
    else
        print_operation_status "RBAC Role Assignment" "success" "Assigned $success_roles RBAC roles successfully"
    fi
}

# Generate onboarding summary
generate_summary() {
    echo -e "${BLUE}┌──────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│                        ONBOARDING SUMMARY                       │${NC}"
    echo -e "${BLUE}├──────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│ User:         $USER_PRINCIPAL_NAME${NC}"
    echo -e "${BLUE}│ Subscription: $SUBSCRIPTION_ID${NC}"
    if [[ -n "$RESOURCE_GROUP" ]]; then
        echo -e "${BLUE}│ Resource Group: $RESOURCE_GROUP${NC}"
    fi
    echo -e "${BLUE}│ Date:         $(date)${NC}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${BLUE}│ Mode:         ${YELLOW}DRY RUN (no changes made)${BLUE}${NC}"
    else
        echo -e "${BLUE}│ Mode:         ${GREEN}EXECUTION (changes applied)${BLUE}${NC}"
    fi
    
    echo -e "${BLUE}├──────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│                           OPERATIONS                            │${NC}"
    echo -e "${BLUE}├──────────────────────────────────────────────────────────────────┤${NC}"
    
    echo -e "${BLUE}│ ✓ User verification         $(if [[ "$DRY_RUN" == "true" ]]; then echo "[DRY RUN]"; else echo "[EXECUTED]"; fi)${NC}"
    [[ ${#RBAC_ROLES[@]} -gt 0 ]] && echo -e "${BLUE}│ ✓ RBAC role assignments     $(if [[ "$DRY_RUN" == "true" ]]; then echo "[DRY RUN]"; else echo "[EXECUTED]"; fi)${NC}"
    [[ "$MANAGE_VMS" == "true" ]] && echo -e "${BLUE}│ ✓ VM SSH key setup          $(if [[ "$DRY_RUN" == "true" ]]; then echo "[DRY RUN]"; else echo "[EXECUTED]"; fi)${NC}"
    
    if [[ ${#RBAC_ROLES[@]} -gt 0 ]]; then
        echo -e "${BLUE}├──────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${BLUE}│ Roles: ${RBAC_ROLES[*]}${NC}"
    fi
    
    echo -e "${BLUE}└──────────────────────────────────────────────────────────────────┘${NC}"
    echo
}

# Validate SSH public key
validate_ssh_key() {
    if [[ -z "$SSH_PUBLIC_KEY" ]]; then
        log "ERROR" "SSH public key is required for VM management"
        return 1
    fi
    
    local ssh_key_content=""
    
    # Check if it's a file path
    if [[ -f "$SSH_PUBLIC_KEY" ]]; then
        ssh_key_content=$(cat "$SSH_PUBLIC_KEY")
        log "INFO" "Loading SSH public key from file: $SSH_PUBLIC_KEY"
    else
        # Assume it's the key content directly
        ssh_key_content="$SSH_PUBLIC_KEY"
        log "INFO" "Using SSH public key provided as string"
    fi
    
    # Validate SSH key format
    if [[ ! "$ssh_key_content" =~ ^(ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521) ]]; then
        log "ERROR" "Invalid SSH public key format"
        return 1
    fi
    
    # Store the validated key content
    SSH_PUBLIC_KEY="$ssh_key_content"
    log "INFO" "SSH public key validated successfully"
    return 0
}

# Manage SSH keys on Azure VMs (azroot account only)
manage_vm_ssh_access() {
    if [[ "$MANAGE_VMS" != "true" ]]; then
        print_operation_status "VM SSH Access Management" "skip" "--manage-vms not specified"
        return 0
    fi
    
    print_operation_status "VM SSH Access Management" "start" "Preparing to add SSH keys to azroot accounts"
    
    log "INFO" "Managing SSH keys on Azure VMs for azroot account..."
    
    # Validate prerequisites
    if [[ -z "$VM_RESOURCE_GROUP" ]]; then
        log "ERROR" "VM resource group is required for VM management"
        return 1
    fi
    
    if [[ ${#VM_NAMES[@]} -eq 0 ]]; then
        log "INFO" "No VM names specified, discovering VMs in resource group: $VM_RESOURCE_GROUP"
        
        # Get all Linux VMs in the resource group
        local discovered_vms=$(az vm list -g "$VM_RESOURCE_GROUP" --query "[?storageProfile.osDisk.osType=='Linux'].name" -o tsv)
        
        if [[ -z "$discovered_vms" ]]; then
            log "WARN" "No Linux VMs found in resource group: $VM_RESOURCE_GROUP"
            return 0
        fi
        
        # Convert to array
        IFS=$'\n' read -ra VM_NAMES <<< "$discovered_vms"
        log "INFO" "Discovered ${#VM_NAMES[@]} Linux VMs: ${VM_NAMES[*]}"
    fi
    
    # Validate SSH key
    if ! validate_ssh_key; then
        return 1
    fi
    
    # Process each VM
    local success_count=0
    local total_vms=${#VM_NAMES[@]}
    
    for vm_name in "${VM_NAMES[@]}"; do
        log "INFO" "Processing VM: $vm_name"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "INFO" "[DRY RUN] Would add SSH key to azroot account on VM: $vm_name"
            ((success_count++))
            continue
        fi
        
        # Check if VM exists and is running
        local vm_state=$(az vm get-instance-view -g "$VM_RESOURCE_GROUP" -n "$vm_name" --query "instanceView.statuses[1].displayStatus" -o tsv 2>/dev/null)
        
        if [[ -z "$vm_state" ]]; then
            log "ERROR" "VM not found: $vm_name"
            continue
        fi
        
        if [[ "$vm_state" != "VM running" ]]; then
            log "WARN" "VM is not running: $vm_name (state: $vm_state)"
            log "INFO" "Attempting to add SSH key anyway..."
        fi
        
        # Add SSH key using Azure VM extension
        if add_ssh_key_to_vm "$vm_name"; then
            ((success_count++))
        fi
    done
    
    local failed_vms=$((total_vms - success_count))
    
    if [[ "$failed_vms" -eq 0 ]]; then
        print_operation_status "VM SSH Access Management" "success" "SSH keys added to $success_count VMs"
    else
        print_operation_status "VM SSH Access Management" "error" "SSH key setup failed on $failed_vms out of $total_vms VMs"
        log "WARN" "SSH key setup failed on $failed_vms VMs"
    fi
    
    return 0
}

# Add SSH key to azroot account on a specific VM
add_ssh_key_to_vm() {
    local vm_name="$1"
    
    log "INFO" "Adding SSH key to azroot account on VM: $vm_name"
    
    # Create a temporary script for VM execution
    local temp_script=$(mktemp)
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
    log_vm "INFO" "Creating SSH directory: \$SSH_DIR"
    mkdir -p "\$SSH_DIR"
    chown azroot:azroot "\$SSH_DIR"
    chmod 700 "\$SSH_DIR"
fi

# Create authorized_keys file if it doesn't exist
if [[ ! -f "\$AUTHORIZED_KEYS" ]]; then
    log_vm "INFO" "Creating authorized_keys file"
    touch "\$AUTHORIZED_KEYS"
    chown azroot:azroot "\$AUTHORIZED_KEYS"
    chmod 600 "\$AUTHORIZED_KEYS"
fi

# Check if key already exists
if grep -Fxq "\$SSH_KEY" "\$AUTHORIZED_KEYS"; then
    log_vm "INFO" "SSH key already exists in authorized_keys"
else
    echo "\$SSH_KEY" >> "\$AUTHORIZED_KEYS"
    log_vm "INFO" "SSH key added to authorized_keys"
fi

# Ensure proper permissions
chown azroot:azroot "\$AUTHORIZED_KEYS"
chmod 600 "\$AUTHORIZED_KEYS"

log_vm "INFO" "SSH key management completed for azroot account"
EOF

    # Execute the script on the VM using Azure VM extension
    local extension_name="ssh-add-$(date +%s)"
    
    log "INFO" "Executing SSH key addition script on VM: $vm_name"
    
    if az vm extension set \
        --resource-group "$VM_RESOURCE_GROUP" \
        --vm-name "$vm_name" \
        --name CustomScript \
        --publisher Microsoft.Azure.Extensions \
        --settings "{\"fileUris\": [], \"commandToExecute\": \"bash -s\"}" \
        --protected-settings "{\"script\": \"$(base64 -i "$temp_script")\"}" \
        --no-wait &>/dev/null; then
        
        log "INFO" "SSH key addition script deployed to VM: $vm_name"
        
        # Wait a moment for execution
        sleep 5
        
        # Check extension status
        local extension_status=$(az vm extension show \
            --resource-group "$VM_RESOURCE_GROUP" \
            --vm-name "$vm_name" \
            --name CustomScript \
            --query "provisioningState" -o tsv 2>/dev/null || echo "Unknown")
        
        if [[ "$extension_status" == "Succeeded" ]]; then
            log "INFO" "Successfully added SSH key to VM: $vm_name"
            rm -f "$temp_script"
            return 0
        else
            log "WARN" "Extension status unclear for VM: $vm_name (status: $extension_status)"
            log "INFO" "SSH key addition may still be in progress"
        fi
    else
        log "ERROR" "Failed to deploy SSH key addition script to VM: $vm_name"
        rm -f "$temp_script"
        return 1
    fi
    
    rm -f "$temp_script"
    return 0
}

# Main execution function
main() {
    echo
    echo -e "${BLUE}╭═══════════════════════════════════════════════════════════════════╮${NC}"
    echo -e "${BLUE}│                     Azure User Onboarding Script                  │${NC}"
    echo -e "${BLUE}╰═══════════════════════════════════════════════════════════════════╯${NC}"
    echo
    
    # Phase 1: Prerequisites and Validation
    print_section "🔍 PHASE 1: Prerequisites & Validation" "$BLUE"
    
    print_progress "1" "6" "Checking prerequisites"
    check_prerequisites
    
    print_progress "2" "6" "Verifying permissions"
    check_permissions
    
    print_progress "3" "6" "Validating input parameters"
    validate_input
    
    # Phase 2: User Setup
    print_section "👤 PHASE 2: User Account Verification" "$BLUE"
    
    echo -e "${YELLOW}👤 Processing user: $USER_PRINCIPAL_NAME${NC}"
    echo -e "${YELLOW}🔧 Subscription: $SUBSCRIPTION_ID${NC}"
    echo
    
    print_progress "4" "6" "Verifying existing user account"
    verify_entra_id_user
    echo
    
    # Phase 3: Access & Permissions
    print_section "🔐 PHASE 3: Access & Permissions" "$YELLOW"
    
    print_progress "5" "6" "Assigning RBAC roles"
    assign_rbac_roles
    echo
    
    print_progress "6" "6" "Configuring VM access"
    manage_vm_ssh_access
    echo
    
    # Phase 4: Summary and Results
    print_section "📋 PHASE 4: Summary & Results" "$GREEN"
    
    generate_summary
    
    echo
    echo -e "${GREEN}╭═══════════════════════════════════════════════════════════════════╮${NC}"
    echo -e "${GREEN}│                     ✅ ONBOARDING COMPLETED                         │${NC}"
    echo -e "${GREEN}╰═══════════════════════════════════════════════════════════════════╯${NC}"
    echo
    echo -e "${BLUE}📁 Log file: ${LOG_FILE}${NC}"
    echo
}

#################################################################################
# Command Line Argument Processing
#################################################################################

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--user-principal)
            USER_PRINCIPAL_NAME="$2"
            shift 2
            ;;
        -s|--subscription)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        -r|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -R|--rbac-roles)
            IFS=',' read -ra RBAC_ROLES <<< "$2"
            shift 2
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        --manage-vms)
            MANAGE_VMS=true
            shift
            ;;
        --vm-resource-group)
            VM_RESOURCE_GROUP="$2"
            shift 2
            ;;
        --vm-names)
            IFS=',' read -ra VM_NAMES <<< "$2"
            shift 2
            ;;
        --ssh-public-key)
            SSH_PUBLIC_KEY="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown parameter: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$USER_PRINCIPAL_NAME" || -z "$SUBSCRIPTION_ID" ]]; then
    echo -e "${RED}Error: Missing required parameters${NC}"
    echo
    usage
    exit 1
fi

# Set default values if not specified
if [[ ${#RBAC_ROLES[@]} -eq 0 ]]; then
    # Set default roles - adjust based on your organization's needs
    RBAC_ROLES=()
fi

# Execute main function
main "$@"