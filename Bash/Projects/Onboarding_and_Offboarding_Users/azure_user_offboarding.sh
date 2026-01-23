#!/bin/bash

#################################################################################
# Azure User Offboarding Script
# Description: Automates the offboarding process for users from Azure resources
# Author: Your Organization
# Version: 1.0
# Last Modified: $(date)
#################################################################################

set -euo pipefail  # Exit on any error, undefined variable, or pipe failure

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/offboarding_$(date +%Y%m%d_%H%M%S).log"
REQUIRED_ROLES=("User Access Administrator" "Privileged Role Administrator")

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

# Print usage information
usage() {
    cat << EOF
Usage: $0 -u <user_principal_name> -s <subscription_id> [OPTIONS]

Required Parameters:
    -u, --user-principal     User Principal Name (UPN) - email address of the user
    -s, --subscription       Azure subscription ID

Optional Parameters:
    --no-disable-user       Skip disabling the user account (default: disable user)
    --no-remove-groups      Skip removing user from Azure AD groups (default: remove)
    --no-revoke-roles       Skip revoking RBAC role assignments (default: revoke)
    --no-backup            Skip creating backup of user's access (default: create backup)
    -f, --force            Force execution without confirmation prompts
    -n, --dry-run          Preview changes without executing them
    -h, --help             Display this help message

Examples:
    # Full offboarding with all default actions
    $0 -u john.doe@company.com -s "12345678-1234-1234-1234-123456789012"
    
    # Offboarding but keep user account active (just remove access)
    $0 -u jane.smith@company.com -s "12345678-1234-1234-1234-123456789012" --no-disable-user
    
    # Dry run to preview changes
    $0 -u test.user@company.com -s "12345678-1234-1234-1234-123456789012" -n
    
    # Force execution without prompts (for automation)
    $0 -u automated.user@company.com -s "12345678-1234-1234-1234-123456789012" -f

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

# Verify user has required permissions
check_permissions() {
    log "INFO" "Checking user permissions..."
    
    local current_user=$(az account show --query user.name -o tsv)
    log "INFO" "Current user: $current_user"
    
    # Check if user has required roles at subscription level
    for role in "${REQUIRED_ROLES[@]}"; do
        local has_role=$(az role assignment list --assignee "$current_user" --subscription "$SUBSCRIPTION_ID" \
                        --query "[?roleDefinitionName=='$role']" -o tsv)
        if [[ -z "$has_role" ]]; then
            log "WARN" "Missing required role: $role. Some operations may fail."
        else
            log "INFO" "Confirmed role: $role"
        fi
    done
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
    
    log "INFO" "Input validation completed successfully"
}

# Check if user exists in Azure AD
check_user_exists() {
    log "INFO" "Checking if user exists in Azure AD..."
    
    local existing_user=$(az ad user show --id "$USER_PRINCIPAL_NAME" --query id -o tsv 2>/dev/null || echo "")
    
    if [[ -n "$existing_user" ]]; then
        log "INFO" "User found in Azure AD: $existing_user"
        return 0
    else
        log "WARN" "User does not exist in Azure AD: $USER_PRINCIPAL_NAME"
        return 1
    fi
}

# Get comprehensive user information
get_user_info() {
    log "INFO" "Gathering user information for audit trail..."
    
    local user_info_file="${SCRIPT_DIR}/user_backup_${USER_PRINCIPAL_NAME//[@.]/_}_$(date +%Y%m%d_%H%M%S).json"
    
    if ! check_user_exists; then
        log "WARN" "Cannot gather user info - user does not exist"
        return 1
    fi
    
    if [[ "$BACKUP_DATA" != "true" ]]; then
        log "INFO" "Skipping user data backup per configuration"
        return 0
    fi
    
    log "INFO" "Creating user data backup..."
    
    # Get basic user information
    local user_details=$(az ad user show --id "$USER_PRINCIPAL_NAME" --output json 2>/dev/null || echo "{}")
    
    # Get user's group memberships
    local group_memberships=$(az ad user get-member-groups --id "$USER_PRINCIPAL_NAME" --output json 2>/dev/null || echo "[]")
    
    # Get user's role assignments across all scopes
    local role_assignments=$(az role assignment list --assignee "$USER_PRINCIPAL_NAME" --all --output json 2>/dev/null || echo "[]")
    
    # Get user's owned applications (if any)
    local owned_apps=$(az ad app list --filter "owners/any(o:o/id eq '$(az ad user show --id "$USER_PRINCIPAL_NAME" --query id -o tsv)')" --output json 2>/dev/null || echo "[]")
    
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

# Remove user from Azure AD groups
remove_from_groups() {
    if [[ "$REMOVE_FROM_GROUPS" != "true" ]]; then
        log "INFO" "Skipping group removal per configuration"
        return 0
    fi
    
    log "INFO" "Removing user from Azure AD groups..."
    
    if ! check_user_exists; then
        log "WARN" "Cannot remove from groups - user does not exist"
        return 1
    fi
    
    local user_id=$(az ad user show --id "$USER_PRINCIPAL_NAME" --query id -o tsv)
    local groups=$(az ad user get-member-groups --id "$USER_PRINCIPAL_NAME" --query "[]" -o tsv 2>/dev/null || echo "")
    
    if [[ -z "$groups" ]]; then
        log "INFO" "User is not a member of any groups"
        return 0
    fi
    
    local group_count=0
    while IFS= read -r group_id; do
        if [[ -n "$group_id" ]]; then
            local group_name=$(az ad group show --group "$group_id" --query displayName -o tsv 2>/dev/null || echo "Unknown")
            
            if [[ "$DRY_RUN" == "true" ]]; then
                log "INFO" "[DRY RUN] Would remove user from group: $group_name ($group_id)"
            else
                if az ad group member remove --group "$group_id" --member-id "$user_id" &>/dev/null; then
                    log "INFO" "Removed user from group: $group_name"
                    ((group_count++))
                else
                    log "ERROR" "Failed to remove user from group: $group_name"
                fi
            fi
        fi
    done <<< "$groups"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        log "INFO" "Removed user from $group_count groups"
    fi
}

# Revoke RBAC role assignments
revoke_rbac_roles() {
    if [[ "$REVOKE_RBAC_ROLES" != "true" ]]; then
        log "INFO" "Skipping RBAC role revocation per configuration"
        return 0
    fi
    
    log "INFO" "Revoking RBAC role assignments..."
    
    local role_assignments=$(az role assignment list --assignee "$USER_PRINCIPAL_NAME" --all --output json 2>/dev/null || echo "[]")
    local role_count=$(echo "$role_assignments" | jq '. | length' 2>/dev/null || echo "0")
    
    if [[ "$role_count" -eq 0 ]]; then
        log "INFO" "User has no RBAC role assignments"
        return 0
    fi
    
    log "INFO" "Found $role_count role assignments to revoke"
    
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
        log "INFO" "Revoked $revoked_count role assignments"
    fi
}

# Disable user account
disable_user_account() {
    if [[ "$DISABLE_USER" != "true" ]]; then
        log "INFO" "Skipping user account disable per configuration"
        return 0
    fi
    
    log "INFO" "Disabling user account..."
    
    if ! check_user_exists; then
        log "WARN" "Cannot disable user - user does not exist"
        return 1
    fi
    
    # Check if user is already disabled
    local account_enabled=$(az ad user show --id "$USER_PRINCIPAL_NAME" --query accountEnabled -o tsv 2>/dev/null)
    
    if [[ "$account_enabled" == "false" ]]; then
        log "INFO" "User account is already disabled"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would disable user account: $USER_PRINCIPAL_NAME"
    else
        if az ad user update --id "$USER_PRINCIPAL_NAME" --account-enabled false &>/dev/null; then
            log "INFO" "Successfully disabled user account: $USER_PRINCIPAL_NAME"
        else
            log "ERROR" "Failed to disable user account: $USER_PRINCIPAL_NAME"
            return 1
        fi
    fi
}

# Check for owned resources that need reassignment
check_owned_resources() {
    log "INFO" "Checking for resources owned by the user..."
    
    if ! check_user_exists; then
        return 1
    fi
    
    local user_id=$(az ad user show --id "$USER_PRINCIPAL_NAME" --query id -o tsv)
    
    # Check for owned applications
    local owned_apps=$(az ad app list --filter "owners/any(o:o/id eq '$user_id')" --query "[].{displayName:displayName,appId:appId}" -o json 2>/dev/null || echo "[]")
    local app_count=$(echo "$owned_apps" | jq '. | length')
    
    if [[ "$app_count" -gt 0 ]]; then
        log "WARN" "User owns $app_count application(s) that may need ownership transfer:"
        echo "$owned_apps" | jq -r '.[] | "  - \(.displayName) (\(.appId))"' | while read -r line; do
            log "WARN" "$line"
        done
    fi
    
    # Check for owned service principals
    local owned_sps=$(az ad sp list --filter "owners/any(o:o/id eq '$user_id')" --query "[].{displayName:displayName,appId:appId}" -o json 2>/dev/null || echo "[]")
    local sp_count=$(echo "$owned_sps" | jq '. | length')
    
    if [[ "$sp_count" -gt 0 ]]; then
        log "WARN" "User owns $sp_count service principal(s) that may need ownership transfer:"
        echo "$owned_sps" | jq -r '.[] | "  - \(.displayName) (\(.appId))"' | while read -r line; do
            log "WARN" "$line"
        done
    fi
    
    # Note: Checking for other resource types would require additional permissions and scope
    log "INFO" "Resource ownership check completed"
}

# Generate offboarding summary
generate_summary() {
    log "INFO" "=== OFFBOARDING SUMMARY ==="
    log "INFO" "User Principal Name: $USER_PRINCIPAL_NAME"
    log "INFO" "Subscription: $SUBSCRIPTION_ID"
    
    if [[ "$DISABLE_USER" == "true" ]]; then
        log "INFO" "User account: DISABLED"
    else
        log "INFO" "User account: LEFT ACTIVE"
    fi
    
    if [[ "$REMOVE_FROM_GROUPS" == "true" ]]; then
        log "INFO" "Group memberships: REMOVED"
    else
        log "INFO" "Group memberships: LEFT INTACT"
    fi
    
    if [[ "$REVOKE_RBAC_ROLES" == "true" ]]; then
        log "INFO" "RBAC roles: REVOKED"
    else
        log "INFO" "RBAC roles: LEFT INTACT"
    fi
    
    if [[ "$BACKUP_DATA" == "true" ]]; then
        log "INFO" "User data: BACKED UP"
    else
        log "INFO" "User data: NOT BACKED UP"
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "Mode: DRY RUN (no changes made)"
    else
        log "INFO" "Mode: EXECUTION (changes applied)"
    fi
    
    log "INFO" "Log file: $LOG_FILE"
    log "INFO" "=========================="
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
    [[ "$REMOVE_FROM_GROUPS" == "true" ]] && echo "  ✓ Remove from Azure AD groups"
    [[ "$REVOKE_RBAC_ROLES" == "true" ]] && echo "  ✓ Revoke RBAC role assignments"
    [[ "$BACKUP_DATA" == "true" ]] && echo "  ✓ Create backup of user access data"
    echo
    
    read -p "Do you want to proceed? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log "INFO" "Offboarding cancelled by user"
        exit 0
    fi
}

# Main execution function
main() {
    echo -e "${BLUE}=== Azure User Offboarding Script ===${NC}"
    echo
    
    check_prerequisites
    check_permissions
    validate_input
    
    if ! check_user_exists; then
        echo -e "${RED}Error: User $USER_PRINCIPAL_NAME does not exist in Azure AD${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Starting offboarding process for: $USER_PRINCIPAL_NAME${NC}"
    
    # Get user info before making changes
    get_user_info
    
    # Check for resources that might need attention
    check_owned_resources
    
    # Confirm before proceeding
    confirm_execution
    
    # Execute offboarding steps
    remove_from_groups
    revoke_rbac_roles
    disable_user_account
    
    generate_summary
    
    echo -e "${GREEN}✓ Offboarding process completed successfully!${NC}"
    echo -e "Check the log file for detailed information: ${LOG_FILE}"
    
    if [[ "$BACKUP_DATA" == "true" && "$DRY_RUN" != "true" ]]; then
        echo -e "User data backup available in: ${SCRIPT_DIR}"
    fi
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