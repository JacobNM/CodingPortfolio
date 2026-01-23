#!/bin/bash

#################################################################################
# Azure User Offboarding Script
# Description: Automates the offboarding process for users from Azure resources
#              Supports optional Microsoft Entra ID operations (requires additional permissions)
#              Core functionality works with Azure subscription Owner role
# Author: Your Organization
# Version: 2.0
# Last Modified: $(date)
#################################################################################

set -euo pipefail  # Exit on any error, undefined variable, or pipe failure

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/offboarding_$(date +%Y%m%d_%H%M%S).log"
# Azure subscription roles (Owner role provides all these)
REQUIRED_AZURE_ROLES=("User Access Administrator" "Contributor")
# Alternative roles that provide equivalent permissions
EQUIVALENT_ROLES=("Owner" "Co-Administrator")
# Entra ID roles (only needed if --entra-operations is enabled)
REQUIRED_ENTRA_ROLES=("User Administrator" "Groups Administrator")

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SUBSCRIPTION_ID=""
USER_PRINCIPAL_NAME=""
DRY_RUN=false
DISABLE_USER=true
REMOVE_FROM_GROUPS=true
REVOKE_RBAC_ROLES=true
BACKUP_DATA=true
FORCE_EXECUTION=false
ENTRA_OPERATIONS=false
MANAGE_VMS=false
VM_RESOURCE_GROUP=""
VM_NAMES=()

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
    echo -e "${color}╭─────────────────────────────────────────────────────────╮${NC}"
    echo -e "${color}│ $title${NC}"
    echo -e "${color}╰─────────────────────────────────────────────────────────╯${NC}"
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
- RBAC role revocation
- VM SSH key removal
- Resource access removal

**ENTRA ID FUNCTIONALITY (requires additional Entra ID permissions):**
- User account disabling
- Group membership removal

Required Parameters:
    -u, --user-principal     User Principal Name (UPN) - email address of the user
    -s, --subscription       Azure subscription ID

Optional Parameters:
    --entra-operations       Enable Microsoft Entra ID operations (user disable, group removal)
    --no-disable-user       Skip disabling the user account (only applies with --entra-operations)
    --no-remove-groups      Skip removing user from Entra ID groups (only applies with --entra-operations)
    --no-revoke-roles       Skip revoking RBAC role assignments (default: revoke)
    --no-backup            Skip creating backup of user's access (default: create backup)
    --manage-vms            Enable VM SSH key management
    --vm-resource-group     Resource group containing the VMs (required if --manage-vms)
    --vm-names              Comma-separated list of VM names to manage
    -f, --force            Force execution without confirmation prompts
    -n, --dry-run          Preview changes without executing them
    -h, --help             Display this help message

Examples:
    # Basic offboarding - revoke RBAC roles only (requires Azure Owner role)
    $0 -u john.doe@company.com -s "12345678-1234-1234-1234-123456789012"
    
    # Full offboarding with Entra ID operations (requires Entra ID permissions)
    $0 -u jane.smith@company.com -s "12345678-1234-1234-1234-123456789012" --entra-operations
    
    # Keep user active but remove Azure access (no Entra ID needed)
    $0 -u existing.user@company.com -s "12345678-1234-1234-1234-123456789012" --no-revoke-roles
    
    # Offboard user with VM SSH key removal
    $0 -u dev.user@company.com -s "12345678-1234-1234-1234-123456789012" \\
       --manage-vms --vm-resource-group "vm-rg" --vm-names "web01,web02,db01"
    
    # Dry run to preview changes
    $0 -u test.user@company.com -s "12345678-1234-1234-1234-123456789012" -n
    
    # Force execution without prompts (for automation)
    $0 -u automated.user@company.com -s "12345678-1234-1234-1234-123456789012" --entra-operations -f

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
    
    if [[ "$subscription_roles_sufficient" == "false" ]]; then
        log "WARN" "Could not find required roles at subscription level."
        log "INFO" "Required for offboarding operations: User Access Administrator or Owner"
        log "INFO" "The script will proceed - actual operations will succeed/fail based on your effective permissions."
    fi
    
    # Check Entra ID permissions only if required
    if [[ "$ENTRA_OPERATIONS" == "true" ]]; then
        log "INFO" "Checking Microsoft Entra ID permissions..."
        log "WARN" "Entra ID operations enabled - ensure you have User Administrator or Groups Administrator role"
        log "INFO" "If Entra ID operations fail, consider running without --entra-operations"
    else
        log "INFO" "Entra ID operations disabled - Azure access removal only"
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
    
    # Validate Entra ID specific requirements
    if [[ "$ENTRA_OPERATIONS" != "true" ]]; then
        if [[ "$DISABLE_USER" == "true" ]] || [[ "$REMOVE_FROM_GROUPS" == "true" ]]; then
            log "INFO" "Entra ID operations (disable user, remove groups) disabled without --entra-operations"
            DISABLE_USER=false
            REMOVE_FROM_GROUPS=false
        fi
        log "INFO" "Working with existing user (Azure access removal only)"
    else
        log "INFO" "Entra ID operations enabled - will disable user and remove from groups if requested"
    fi
    
    log "INFO" "Input validation completed successfully"
}

# Check if user exists in Microsoft Entra ID
check_user_exists() {
    log "INFO" "Checking if user exists in Microsoft Entra ID..."
    
    local existing_user=$(az ad user show --id "$USER_PRINCIPAL_NAME" --query id -o tsv 2>/dev/null || echo "")
    
    if [[ -n "$existing_user" ]]; then
        log "INFO" "User found in Microsoft Entra ID: $existing_user"
        return 0
    else
        log "WARN" "User does not exist in Microsoft Entra ID: $USER_PRINCIPAL_NAME"
        return 1
    fi
}

# Get comprehensive user information
get_user_info() {
    log "INFO" "Gathering user information for audit trail..."
    
    local user_info_file="${SCRIPT_DIR}/user_backup_${USER_PRINCIPAL_NAME//[@.]/_}_$(date +%Y%m%d_%H%M%S).json"
    
    if [[ "$BACKUP_DATA" != "true" ]]; then
        log "INFO" "Skipping user data backup per configuration"
        return 0
    fi
    
    log "INFO" "Creating user data backup..."
    
    # Initialize backup structure
    local user_details='{}' 
    local group_memberships='[]'
    local owned_apps='[]'
    
    # Only get Entra ID data if operations are enabled
    if [[ "$ENTRA_OPERATIONS" == "true" ]]; then
        if ! check_user_exists; then
            log "WARN" "Cannot gather Entra ID user info - user does not exist"
        else
            # Get basic user information
            user_details=$(az entra user show --id "$USER_PRINCIPAL_NAME" --output json 2>/dev/null || echo '{}')
            
            # Get user's group memberships
            group_memberships=$(az entra user get-member-groups --id "$USER_PRINCIPAL_NAME" --output json 2>/dev/null || echo '[]')
            
            # Get user's owned applications (if any)
            owned_apps=$(az entra app list --filter "owners/any(o:o/id eq '$(az entra user show --id "$USER_PRINCIPAL_NAME" --query id -o tsv)')" --output json 2>/dev/null || echo '[]')
        fi
    else
        log "INFO" "Skipping Entra ID data collection (--entra-operations not specified)"
    fi
    
    # Get user's role assignments across all scopes (Azure subscription level)
    local role_assignments=$(az role assignment list --assignee "$USER_PRINCIPAL_NAME" --all --output json 2>/dev/null || echo '[]')
    
    # Create comprehensive backup
    cat > "$user_info_file" << EOF
{
    "offboarding_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "user_principal_name": "$USER_PRINCIPAL_NAME",
    "subscription_id": "$SUBSCRIPTION_ID",
    "user_details": $user_details,
    "group_memberships": $group_memberships,
    "role_assignments": $role_assignments,
    "owned_applications": $owned_apps
}
EOF
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would create user backup at: $user_info_file"
        rm -f "$user_info_file"  # Clean up the file since this is dry run
    else
        log "INFO" "User data backup created: $user_info_file"
    fi
    
    return 0
}

# Remove user from Microsoft Entra ID groups
remove_from_groups() {
    if [[ "$ENTRA_OPERATIONS" != "true" ]]; then
        print_operation_status "Microsoft Entra ID Group Removal" "skip" "--entra-operations not specified"
        return 0
    fi
    
    if [[ "$REMOVE_FROM_GROUPS" != "true" ]]; then
        print_operation_status "Microsoft Entra ID Group Removal" "skip" "Disabled in configuration"
        return 0
    fi
    
    print_operation_status "Microsoft Entra ID Group Removal" "start" "Scanning user's group memberships"
    log "INFO" "Removing user from Microsoft Entra ID groups..."
    
    if ! check_user_exists; then
        log "WARN" "Cannot remove from groups - user does not exist"
        return 1
    fi
    
    local user_id=$(az entra user show --id "$USER_PRINCIPAL_NAME" --query id -o tsv)
    local groups=$(az entra user get-member-groups --id "$USER_PRINCIPAL_NAME" --query "[]" -o tsv 2>/dev/null || echo "")
    
    if [[ -z "$groups" ]]; then
        print_operation_status "Microsoft Entra ID Group Removal" "skip" "User is not a member of any groups"
        return 0
    fi
    
    local group_count=0
    while IFS= read -r group_id; do
        if [[ -n "$group_id" ]]; then
            local group_name=$(az entra group show --group "$group_id" --query displayName -o tsv 2>/dev/null || echo "Unknown")
            
            if [[ "$DRY_RUN" == "true" ]]; then
                log "INFO" "[DRY RUN] Would remove user from group: $group_name ($group_id)"
            else
                if az entra group member remove --group "$group_id" --member-id "$user_id" &>/dev/null; then
                    log "INFO" "Removed user from group: $group_name"
                    ((group_count++))
                else
                    log "ERROR" "Failed to remove user from group: $group_name"
                fi
            fi
        fi
    done <<< "$groups"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        print_operation_status "Microsoft Entra ID Group Removal" "success" "Removed user from $group_count groups"
    else
        print_operation_status "Microsoft Entra ID Group Removal" "success" "[DRY RUN] Would remove user from groups"
    fi
}

# Revoke RBAC role assignments
revoke_rbac_roles() {
    if [[ "$REVOKE_RBAC_ROLES" != "true" ]]; then
        print_operation_status "RBAC Role Revocation" "skip" "Disabled in configuration"
        return 0
    fi
    
    print_operation_status "RBAC Role Revocation" "start" "Scanning user's role assignments"
    log "INFO" "Revoking RBAC role assignments..."
    
    local role_assignments=$(az role assignment list --assignee "$USER_PRINCIPAL_NAME" --all --output json 2>/dev/null || echo "[]")
    local role_count=$(echo "$role_assignments" | jq '. | length' 2>/dev/null || echo "0")
    
    if [[ "$role_count" -eq 0 ]]; then
        print_operation_status "RBAC Role Revocation" "skip" "User has no RBAC role assignments"
        return 0
    fi
    
    echo -e "   ${BLUE}Found $role_count role assignments to process${NC}"
    
    local revoked_count=0
    while IFS= read -r assignment; do
        if [[ -n "$assignment" ]]; then
            local assignment_id=$(echo "$assignment" | jq -r '.id')
            local role_name=$(echo "$assignment" | jq -r '.roleDefinitionName')
            local scope=$(echo "$assignment" | jq -r '.scope')
            
            if [[ "$DRY_RUN" == "true" ]]; then
                log "INFO" "[DRY RUN] Would revoke role: $role_name at scope: $scope"
            else
                if az role assignment delete --ids "$assignment_id" &>/dev/null; then
                    log "INFO" "Revoked role: $role_name at scope: $scope"
                    ((revoked_count++))
                else
                    log "ERROR" "Failed to revoke role: $role_name at scope: $scope"
                fi
            fi
        fi
    done < <(echo "$role_assignments" | jq -c '.[]')
    
    if [[ "$DRY_RUN" != "true" ]]; then
        print_operation_status "RBAC Role Revocation" "success" "Revoked $revoked_count of $role_count role assignments"
    else
        print_operation_status "RBAC Role Revocation" "success" "[DRY RUN] Would revoke $role_count role assignments"
    fi
}

# Disable user account
disable_user_account() {
    if [[ "$ENTRA_OPERATIONS" != "true" ]]; then
        print_operation_status "User Account Disabling" "skip" "--entra-operations not specified"
        return 0
    fi
    
    if [[ "$DISABLE_USER" != "true" ]]; then
        print_operation_status "User Account Disabling" "skip" "Disabled in configuration"
        return 0
    fi
    
    print_operation_status "User Account Disabling" "start" "Checking user account status"
    log "INFO" "Disabling user account..."
    
    if ! check_user_exists; then
        log "WARN" "Cannot disable user - user does not exist"
        return 1
    fi
    
    # Check if user is already disabled
    local account_enabled=$(az entra user show --id "$USER_PRINCIPAL_NAME" --query accountEnabled -o tsv 2>/dev/null)
    
    if [[ "$account_enabled" == "false" ]]; then
        print_operation_status "User Account Disabling" "skip" "User account is already disabled"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_operation_status "User Account Disabling" "success" "[DRY RUN] Would disable user account"
    else
        if az entra user update --id "$USER_PRINCIPAL_NAME" --account-enabled false &>/dev/null; then
            print_operation_status "User Account Disabling" "success" "Successfully disabled user account"
        else
            print_operation_status "User Account Disabling" "error" "Failed to disable user account"
            return 1
        fi
    fi
}

# Check for owned resources that need reassignment
check_owned_resources() {
    if [[ "$ENTRA_OPERATIONS" != "true" ]]; then
        echo -e "   ${YELLOW}⏭️  Skipping owned resources check (--entra-operations not specified)${NC}"
        return 0
    fi
    
    log "INFO" "Checking for resources owned by the user..."
    
    if ! check_user_exists; then
        return 1
    fi
    
    local user_id=$(az entra user show --id "$USER_PRINCIPAL_NAME" --query id -o tsv)
    
    # Check for owned applications
    local owned_apps=$(az entra app list --filter "owners/any(o:o/id eq '$user_id')" --query "[].{displayName:displayName,appId:appId}" -o json 2>/dev/null || echo "[]")
    local app_count=$(echo "$owned_apps" | jq '. | length')
    
    if [[ "$app_count" -gt 0 ]]; then
        log "WARN" "User owns $app_count application(s) that may need ownership transfer:"
        echo "$owned_apps" | jq -r '.[] | "  - \(.displayName) (\(.appId))"' | while read -r line; do
            log "WARN" "$line"
        done
    fi
    
    local owned_objects=$(az entra user show --id "$USER_PRINCIPAL_NAME" --query "ownedObjects[].{displayName:displayName, objectType:['@odata.type']}" -o json 2>/dev/null || echo "[]")
    local owned_count=$(echo "$owned_objects" | jq '. | length' 2>/dev/null || echo "0")
    
    if [[ "$owned_count" -gt 0 ]]; then
        echo -e "   ${YELLOW}⚠️  Warning: User owns $owned_count resources that may need reassignment:${NC}"
        echo "$owned_objects" | jq -r '.[] | "      - \(.displayName) (\(.objectType))"' 2>/dev/null || true
        log "WARN" "User owns $owned_count resources that may need manual reassignment"
    else
        echo -e "   ${GREEN}✅ User does not own any resources requiring reassignment${NC}"
    fi
}

# Remove SSH keys from Azure VMs (azroot account only)
remove_vm_ssh_access() {
    if [[ "$MANAGE_VMS" != "true" ]]; then
        print_operation_status "VM SSH Access Removal" "skip" "--manage-vms not specified"
        return 0
    fi
    
    print_operation_status "VM SSH Access Removal" "start" "Preparing to clean SSH keys from azroot accounts"
    
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
    
    # Process each VM
    local success_count=0
    local total_vms=${#VM_NAMES[@]}
    
    for vm_name in "${VM_NAMES[@]}"; do
        log "INFO" "Processing VM: $vm_name"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "INFO" "[DRY RUN] Would remove SSH keys from azroot account on VM: $vm_name"
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
            log "INFO" "Attempting to remove SSH keys anyway..."
        fi
        
        # Remove SSH keys using Azure VM extension
        if remove_ssh_keys_from_vm "$vm_name"; then
            ((success_count++))
        fi
    done
    
    local failed_vms=$((total_vms - success_count))
    
    if [[ "$failed_vms" -eq 0 ]]; then
        print_operation_status "VM SSH Access Removal" "success" "SSH keys cleaned from ${#VM_NAMES[@]} VMs"
    else
        print_operation_status "VM SSH Access Removal" "error" "SSH key removal failed on $failed_vms out of ${#VM_NAMES[@]} VMs"
        log "WARN" "SSH key removal failed on $failed_vms VMs"
    fi
    
    return 0
}

# Remove SSH keys from azroot account on a specific VM
remove_ssh_keys_from_vm() {
    local vm_name="$1"
    
    log "INFO" "Removing SSH keys from azroot account on VM: $vm_name"
    
    # Create a temporary script for VM execution
    local temp_script=$(mktemp)
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

log_vm "INFO" "Removing SSH keys from azroot account"

# Check if authorized_keys exists
if [[ ! -f "\$AUTHORIZED_KEYS" ]]; then
    log_vm "INFO" "No authorized_keys file found for azroot account"
    exit 0
fi

# Backup authorized_keys before modification
cp "\$AUTHORIZED_KEYS" "\$AUTHORIZED_KEYS.backup.\$(date +%Y%m%d_%H%M%S)"
log_vm "INFO" "Backed up authorized_keys file"

# Clear the authorized_keys file (remove all SSH keys)
> "\$AUTHORIZED_KEYS"
chown azroot:azroot "\$AUTHORIZED_KEYS"
chmod 600 "\$AUTHORIZED_KEYS"

log_vm "INFO" "Cleared all SSH keys from azroot authorized_keys"
log_vm "INFO" "SSH key removal completed for azroot account"
EOF

    # Execute the script on the VM using Azure VM extension
    local extension_name="ssh-remove-$(date +%s)"
    
    log "INFO" "Executing SSH key removal script on VM: $vm_name"
    
    if az vm extension set \
        --resource-group "$VM_RESOURCE_GROUP" \
        --vm-name "$vm_name" \
        --name CustomScript \
        --publisher Microsoft.Azure.Extensions \
        --settings "{\"fileUris\": [], \"commandToExecute\": \"bash -s\"}" \
        --protected-settings "{\"script\": \"$(base64 -i "$temp_script")\"}" \
        --no-wait &>/dev/null; then
        
        log "INFO" "SSH key removal script deployed to VM: $vm_name"
        
        # Wait a moment for execution
        sleep 5
        
        # Check extension status
        local extension_status=$(az vm extension show \
            --resource-group "$VM_RESOURCE_GROUP" \
            --vm-name "$vm_name" \
            --name CustomScript \
            --query "provisioningState" -o tsv 2>/dev/null || echo "Unknown")
        
        if [[ "$extension_status" == "Succeeded" ]]; then
            log "INFO" "Successfully removed SSH keys from VM: $vm_name"
            rm -f "$temp_script"
            return 0
        else
            log "WARN" "Extension status unclear for VM: $vm_name (status: $extension_status)"
            log "INFO" "SSH key removal may still be in progress"
        fi
    else
        log "ERROR" "Failed to deploy SSH key removal script to VM: $vm_name"
        rm -f "$temp_script"
        return 1
    fi
    
    rm -f "$temp_script"
    return 0
}

# Generate offboarding summary
generate_summary() {
    echo -e "${BLUE}┌──────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│                        OFFBOARDING SUMMARY                      │${NC}"
    echo -e "${BLUE}├──────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│ User:         $USER_PRINCIPAL_NAME${NC}"
    echo -e "${BLUE}│ Subscription: $SUBSCRIPTION_ID${NC}"
    echo -e "${BLUE}│ Date:         $(date)${NC}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${BLUE}│ Mode:         ${YELLOW}DRY RUN (no changes made)${BLUE}${NC}"
    else
        echo -e "${BLUE}│ Mode:         ${GREEN}EXECUTION (changes applied)${BLUE}${NC}"
    fi
    
    echo -e "${BLUE}├──────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│                           OPERATIONS                            │${NC}"
    echo -e "${BLUE}├──────────────────────────────────────────────────────────────────┤${NC}"
    
    [[ "$ENTRA_OPERATIONS" == "true" && "$REMOVE_FROM_GROUPS" == "true" ]] && echo -e "${BLUE}│ ✓ Group membership removal $(if [[ "$DRY_RUN" == "true" ]]; then echo "[DRY RUN]"; else echo "[EXECUTED]"; fi)${NC}"
    [[ "$REVOKE_RBAC_ROLES" == "true" ]] && echo -e "${BLUE}│ ✓ RBAC role revocation     $(if [[ "$DRY_RUN" == "true" ]]; then echo "[DRY RUN]"; else echo "[EXECUTED]"; fi)${NC}"
    [[ "$ENTRA_OPERATIONS" == "true" && "$DISABLE_USER" == "true" ]] && echo -e "${BLUE}│ ✓ User account disabling   $(if [[ "$DRY_RUN" == "true" ]]; then echo "[DRY RUN]"; else echo "[EXECUTED]"; fi)${NC}"
    [[ "$MANAGE_VMS" == "true" ]] && echo -e "${BLUE}│ ✓ VM SSH key removal      $(if [[ "$DRY_RUN" == "true" ]]; then echo "[DRY RUN]"; else echo "[EXECUTED]"; fi)${NC}"
    
    echo -e "${BLUE}└──────────────────────────────────────────────────────────────────┘${NC}"
    echo
}

# Confirmation prompt
confirm_execution() {
    if [[ "$FORCE_EXECUTION" == "true" || "$DRY_RUN" == "true" ]]; then
        return 0
    fi
    
    echo
    echo -e "${YELLOW}WARNING: This will permanently remove the user's access to Azure resources.${NC}"
    echo -e "${YELLOW}User: $USER_PRINCIPAL_NAME${NC}"
    echo -e "${YELLOW}Subscription: $SUBSCRIPTION_ID${NC}"
    echo
    echo "Actions to be performed:"
    [[ "$DISABLE_USER" == "true" ]] && echo "  ✓ Disable user account"
    [[ "$REMOVE_FROM_GROUPS" == "true" ]] && echo "  ✓ Remove from Microsoft Entra ID groups"
    [[ "$REVOKE_RBAC_ROLES" == "true" ]] && echo "  ✓ Revoke RBAC role assignments"
    [[ "$BACKUP_DATA" == "true" ]] && echo "  ✓ Create backup of user access data"
    if [[ "$MANAGE_VMS" == "true" ]]; then
        echo "  ✓ Clear SSH keys from azroot account on VMs"
    fi
    echo
    
    read -p "Do you want to proceed? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log "INFO" "Offboarding cancelled by user"
        exit 0
    fi
}

# Main execution function
main() {
    echo
    echo -e "${BLUE}╭═══════════════════════════════════════════════════════════════════╮${NC}"
    echo -e "${BLUE}│                    Azure User Offboarding Script                 │${NC}"
    echo -e "${BLUE}╰═══════════════════════════════════════════════════════════════════╯${NC}"
    echo
    
    # Phase 1: Prerequisites and Validation
    print_section "🔍 PHASE 1: Prerequisites & Validation" "$BLUE"
    
    print_progress "1" "7" "Checking prerequisites"
    check_prerequisites
    
    print_progress "2" "7" "Verifying permissions"
    check_permissions
    
    print_progress "3" "7" "Validating input parameters"
    validate_input
    
    print_progress "4" "7" "Verifying user exists"
    if ! check_user_exists; then
        echo -e "${RED}❌ Error: User $USER_PRINCIPAL_NAME does not exist in Microsoft Entra ID${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ User found in Microsoft Entra ID${NC}"
    
    # Phase 2: Information Gathering
    print_section "📊 PHASE 2: Information Gathering" "$BLUE"
    
    print_progress "5" "7" "Gathering user information"
    get_user_info
    
    print_progress "6" "7" "Checking owned resources"
    check_owned_resources
    
    print_progress "7" "7" "Confirming execution"
    confirm_execution
    
    # Phase 3: Offboarding Operations
    print_section "🚀 PHASE 3: Offboarding Operations" "$YELLOW"
    
    echo -e "${YELLOW}👤 Processing user: $USER_PRINCIPAL_NAME${NC}"
    echo -e "${YELLOW}🔧 Subscription: $SUBSCRIPTION_ID${NC}"
    echo
    
    # Execute offboarding steps
    remove_from_groups
    echo
    
    revoke_rbac_roles
    echo
    
    remove_vm_ssh_access
    echo
    
    disable_user_account
    echo
    
    # Phase 4: Summary and Cleanup
    print_section "📋 PHASE 4: Summary & Results" "$GREEN"
    
    generate_summary
    
    echo
    echo -e "${GREEN}╭═══════════════════════════════════════════════════════════════════╮${NC}"
    echo -e "${GREEN}│                    ✅ OFFBOARDING COMPLETED                        │${NC}"
    echo -e "${GREEN}╰═══════════════════════════════════════════════════════════════════╯${NC}"
    echo
    echo -e "${BLUE}📁 Log file: ${LOG_FILE}${NC}"
    
    if [[ "$BACKUP_DATA" == "true" && "$DRY_RUN" != "true" ]]; then
        echo -e "${BLUE}💾 User data backup: ${SCRIPT_DIR}${NC}"
    fi
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
        --no-disable-user)
            DISABLE_USER=false
            shift
            ;;
        --no-remove-groups)
            REMOVE_FROM_GROUPS=false
            shift
            ;;
        --no-revoke-roles)
            REVOKE_RBAC_ROLES=false
            shift
            ;;
        --no-backup)
            BACKUP_DATA=false
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
        -f|--force)
            FORCE_EXECUTION=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
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

# Execute main function
main "$@"