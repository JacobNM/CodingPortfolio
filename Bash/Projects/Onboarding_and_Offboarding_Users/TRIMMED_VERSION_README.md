# Azure User Onboarding and Offboarding Scripts

## Overview

These Bash scripts automate Azure resource access management for existing users. They focus on RBAC role assignments and VM access management, requiring only Azure subscription Owner permissions.

## Prerequisites

- Azure CLI installed and configured
- Azure subscription Owner role or equivalent permissions
- Existing users in Microsoft Entra ID
- Bash shell environment (Linux, macOS, or WSL)

## Scripts

### Onboarding Script (`azure_user_onboarding.sh`)

Grants Azure resource access to existing users by assigning RBAC roles and configuring VM SSH access.

**Core Features:**
- Verifies user exists in Microsoft Entra ID
- Assigns RBAC roles at subscription or resource group level
- Manages SSH public keys on Azure Linux VMs
- Supports dry-run mode for testing
- Comprehensive logging and error handling

**Usage Examples:**
```bash
# Basic role assignment
./azure_user_onboarding.sh -u john.doe@company.com -s "12345678-1234-1234-1234-123456789012" -R "Contributor"

# Resource group specific access
./azure_user_onboarding.sh -u jane.smith@company.com -s "12345678-1234-1234-1234-123456789012" \
    -R "Contributor,Storage Blob Data Reader" -r "production-rg"

# Include VM SSH access
./azure_user_onboarding.sh -u dev.user@company.com -s "12345678-1234-1234-1234-123456789012" \
    --manage-vms --vm-resource-group "vm-rg" --vm-names "web01,web02" \
    --ssh-public-key "~/.ssh/id_rsa.pub" -R "Virtual Machine Contributor"
```

### Offboarding Script (`azure_user_offboarding.sh`)

Removes Azure resource access from users by revoking RBAC roles and cleaning up VM access.

**Core Features:**
- Creates backup of current user permissions
- Revokes RBAC role assignments
- Removes SSH keys from Azure VMs
- Supports selective role/resource filtering
- Force and dry-run execution modes

**Usage Examples:**
```bash
# Complete access removal
./azure_user_offboarding.sh -u john.doe@company.com -s "12345678-1234-1234-1234-123456789012"

# Remove specific roles from resource group
./azure_user_offboarding.sh -u user@company.com -s "12345678-1234-1234-1234-123456789012" \
    -r "Production" -R "Reader,Contributor"

# Include VM SSH cleanup
./azure_user_offboarding.sh -u dev.user@company.com -s "12345678-1234-1234-1234-123456789012" \
    --manage-vms --vm-resource-group "vm-rg" --vm-names "web01,web02"
```

## Key Features

### RBAC Management
- Assign/revoke Azure roles at subscription or resource group scope
- Support for multiple roles per user
- Built-in role validation and conflict detection
- Comprehensive permission checking

### VM Access Control
- SSH public key management on Linux VMs
- Automatic VM discovery within resource groups
- Support for azroot account configuration
- VM state validation before operations

### Safety & Reliability
- Dry-run mode for testing changes
- Comprehensive backup creation before modifications
- Detailed logging with timestamps
- Progressive execution with clear status reporting
- Force mode for automated scenarios

### Flexibility
- Works with any existing Entra ID user
- Supports both subscription and resource group scopes
- Configurable role sets and VM targets
- Extensive command-line options

## Command Line Options

### Common Parameters
- `-u, --user-principal`: User Principal Name (email address)
- `-s, --subscription`: Azure subscription ID
- `-r, --resource-group`: Target resource group (optional)
- `-n, --dry-run`: Preview changes without execution
- `-h, --help`: Display usage information

### Onboarding Specific
- `-R, --rbac-roles`: Comma-separated list of RBAC roles
- `--manage-vms`: Enable VM SSH key management
- `--vm-resource-group`: Resource group containing VMs
- `--vm-names`: Specific VM names to manage
- `--ssh-public-key`: SSH public key (file path or content)

### Offboarding Specific
- `-R, --roles`: Specific roles to remove (default: all)
- `--no-revoke-roles`: Skip RBAC role revocation
- `--no-backup`: Skip creating access backup
- `-f, --force`: Execute without confirmation prompts

## Security Considerations

- Follows principle of least privilege
- Only requires Azure subscription Owner permissions
- No special Entra ID administrative roles needed
- Creates audit trails through comprehensive logging
- Validates permissions before making changes

## Integration

These scripts are designed for:
- Manual administrative tasks
- Integration with CI/CD pipelines
- Automated onboarding/offboarding workflows
- Compliance and audit scenarios
- Team access management processes