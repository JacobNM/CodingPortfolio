#!/bin/bash

#################################################################################
# Azure User Onboarding Script
# Description: Automates the onboarding process for new users to Azure resources using Microsoft Entra ID
#################################################################################

set -euo pipefail  # Exit on any error, undefined variable, or pipe failure

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/onboarding_$(date +%Y%m%d_%H%M%S).log"
REQUIRED_ROLES=("User Access Administrator" "Privileged Role Administrator")

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
DISPLAY_NAME=""
ENTRA_ID_GROUPS=()
RBAC_ROLES=()
DRY_RUN=false
SEND_WELCOME_EMAIL=false
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

# Print usage information
usage() {
    cat << EOF
Usage: $0 -u <user_principal_name> -d <display_name> -s <subscription_id> [OPTIONS]

Required Parameters:
    -u, --user-principal     User Principal Name (UPN) - email address of the user
    -d, --display-name       Display name for the user
    -s, --subscription       Azure subscription ID

Optional Parameters:
    -r, --resource-group     Specific resource group to grant access to
    -g, --entra-groups       Comma-separated list of Microsoft Entra ID groups to add user to
    -R, --rbac-roles         Comma-separated list of RBAC roles to assign
    -n, --dry-run           Preview changes without executing them
    -e, --send-email        Send welcome email with access details
    --manage-vms            Enable VM SSH key management
    --vm-resource-group     Resource group containing the VMs (required if --manage-vms)
    --vm-names              Comma-separated list of VM names to manage
    --ssh-public-key        SSH public key to add to azroot account (file path or key string)
    -h, --help              Display this help message

Examples:
    # Basic onboarding with default permissions
    $0 -u john.doe@company.com -d "John Doe" -s "12345678-1234-1234-1234-123456789012"
    
    # Full onboarding with custom groups and roles
    $0 -u jane.smith@company.com -d "Jane Smith" -s "12345678-1234-1234-1234-123456789012" \\
       -g "IT-Team,Project-Alpha" -R "Contributor,Storage Blob Data Reader" \\
       -r "production-rg" -e

    # Onboarding with VM SSH access
    $0 -u dev.user@company.com -d "Dev User" -s "12345678-1234-1234-1234-123456789012" \\
       --manage-vms --vm-resource-group "vm-rg" --vm-names "web01,web02,db01" \\
       --ssh-public-key "~/.ssh/id_rsa.pub"

    # Dry run to preview changes
    $0 -u test.user@company.com -d "Test User" -s "12345678-1234-1234-1234-123456789012" -n

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

# Check if user already exists in Microsoft Entra ID
check_user_exists() {
    log "INFO" "Checking if user already exists in Microsoft Entra ID..."
    
    local existing_user=$(az entra user show --id "$USER_PRINCIPAL_NAME" --query id -o tsv 2>/dev/null || echo "")
    
    if [[ -n "$existing_user" ]]; then
        log "INFO" "User already exists in Microsoft Entra ID: $existing_user"
        return 0
    else
        log "INFO" "User does not exist in Microsoft Entra ID"
        return 1
    fi
}

# Create user in Microsoft Entra ID (if needed)
create_entra_id_user() {
    if check_user_exists; then
        log "INFO" "Skipping user creation - user already exists"
        return 0
    fi
    
    log "INFO" "Creating new user in Microsoft Entra ID..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would create user: $USER_PRINCIPAL_NAME with display name: $DISPLAY_NAME"
        return 0
    fi
    
    # Generate a temporary password (user will be forced to change on first login)
    local temp_password=$(openssl rand -base64 12)
    
    # Create the user
    local user_id=$(az entra user create \
        --user-principal-name "$USER_PRINCIPAL_NAME" \
        --display-name "$DISPLAY_NAME" \
        --password "$temp_password" \
        --force-change-password-next-login true \
        --query id -o tsv)
    
    if [[ -n "$user_id" ]]; then
        log "INFO" "Successfully created user: $user_id"
        log "INFO" "Temporary password: $temp_password (user must change on first login)"
    else
        log "ERROR" "Failed to create user"
        exit 1
    fi
}

# Add user to Microsoft Entra ID groups
add_to_entra_groups() {
    if [[ ${#ENTRA_ID_GROUPS[@]} -eq 0 ]]; then
        log "INFO" "No Microsoft Entra ID groups specified, skipping group assignments"
        return 0
    fi
    
    log "INFO" "Adding user to Microsoft Entra ID groups..."
    
    local user_id=$(az entra user show --id "$USER_PRINCIPAL_NAME" --query id -o tsv)
    
    for group_name in "${ENTRA_ID_GROUPS[@]}"; do
        log "INFO" "Processing group: $group_name"
        
        # Find the group
        local group_id=$(az entra group show --group "$group_name" --query id -o tsv 2>/dev/null || echo "")
        
        if [[ -z "$group_id" ]]; then
            log "WARN" "Group '$group_name' not found, skipping"
            continue
        fi
        
        # Check if user is already a member
        local is_member=$(az entra group member check --group "$group_id" --member-id "$user_id" --query value -o tsv)
        
        if [[ "$is_member" == "true" ]]; then
            log "INFO" "User already member of group: $group_name"
            continue
        fi
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "INFO" "[DRY RUN] Would add user to group: $group_name ($group_id)"
        else
            az entra group member add --group "$group_id" --member-id "$user_id"
            log "INFO" "Successfully added user to group: $group_name"
        fi
    done
}

# Assign RBAC roles
assign_rbac_roles() {
    if [[ ${#RBAC_ROLES[@]} -eq 0 ]]; then
        log "INFO" "No RBAC roles specified, skipping role assignments"
        return 0
    fi
    
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
}

# Generate onboarding summary
generate_summary() {
    log "INFO" "=== ONBOARDING SUMMARY ==="
    log "INFO" "User Principal Name: $USER_PRINCIPAL_NAME"
    log "INFO" "Display Name: $DISPLAY_NAME"
    log "INFO" "Subscription: $SUBSCRIPTION_ID"
    
    if [[ -n "$RESOURCE_GROUP" ]]; then
        log "INFO" "Resource Group: $RESOURCE_GROUP"
    fi
    
    if [[ ${#ENTRA_ID_GROUPS[@]} -gt 0 ]]; then
        log "INFO" "Microsoft Entra ID Groups: ${ENTRA_ID_GROUPS[*]}"
    fi
    
    if [[ ${#RBAC_ROLES[@]} -gt 0 ]]; then
        log "INFO" "RBAC Roles: ${RBAC_ROLES[*]}"
    fi
    
    if [[ "$MANAGE_VMS" == "true" ]]; then
        log "INFO" "VM Management: ENABLED"
        log "INFO" "VM Resource Group: $VM_RESOURCE_GROUP"
        log "INFO" "SSH Key Target: azroot account"
        if [[ ${#VM_NAMES[@]} -gt 0 ]]; then
            log "INFO" "Target VMs: ${VM_NAMES[*]}"
        fi
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "Mode: DRY RUN (no changes made)"
    else
        log "INFO" "Mode: EXECUTION (changes applied)"
    fi
    
    log "INFO" "Log file: $LOG_FILE"
    log "INFO" "=========================="
}

# Send welcome email (placeholder - integrate with your email system)
send_welcome_email() {
    if [[ "$SEND_WELCOME_EMAIL" != "true" ]]; then
        return 0
    fi
    
    log "INFO" "Sending welcome email..."
    
    # This is a placeholder - replace with your organization's email system
    # You might integrate with:
    # - Microsoft Graph API
    # - SendGrid
    # - Organization's SMTP server
    # - PowerShell Send-MailMessage (if available)
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would send welcome email to: $USER_PRINCIPAL_NAME"
    else
        log "INFO" "Welcome email functionality not implemented - please send manually"
        log "INFO" "Email should include: login instructions, temporary password, and resource access details"
    fi
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
        log "INFO" "VM management disabled, skipping SSH access setup"
        return 0
    fi
    
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
    
    log "INFO" "VM SSH key management completed: $success_count/$total_vms VMs processed successfully"
    
    if [[ $success_count -lt $total_vms ]]; then
        log "WARN" "Some VMs failed to configure. Check the logs above for details."
        return 1
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
    echo -e "${BLUE}=== Azure User Onboarding Script ===${NC}"
    echo
    
    check_prerequisites
    check_permissions
    validate_input
    
    echo -e "${YELLOW}Starting onboarding process for: $USER_PRINCIPAL_NAME${NC}"
    
    create_entra_id_user
    add_to_entra_groups
    assign_rbac_roles
    manage_vm_ssh_access
    send_welcome_email
    
    generate_summary
    
    echo -e "${GREEN}✓ Onboarding process completed successfully!${NC}"
    echo -e "Check the log file for detailed information: ${LOG_FILE}"
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
        -d|--display-name)
            DISPLAY_NAME="$2"
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
        -g|--entra-groups)
            IFS=',' read -ra ENTRA_ID_GROUPS <<< "$2"
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
        -e|--send-email)
            SEND_WELCOME_EMAIL=true
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
if [[ -z "$USER_PRINCIPAL_NAME" || -z "$DISPLAY_NAME" || -z "$SUBSCRIPTION_ID" ]]; then
    echo -e "${RED}Error: Missing required parameters${NC}"
    echo
    usage
    exit 1
fi

# Set default values if not specified
if [[ ${#ENTRA_ID_GROUPS[@]} -eq 0 ]]; then
    # Add default groups here if desired
    ENTRA_ID_GROUPS=()
fi

if [[ ${#RBAC_ROLES[@]} -eq 0 ]]; then
    # Set default roles - adjust based on your organization's needs
    RBAC_ROLES=("Reader")
fi

# Execute main function
main "$@"