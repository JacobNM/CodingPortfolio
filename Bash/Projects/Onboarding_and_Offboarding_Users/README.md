# Azure User Onboarding and Offboarding Scripts

This repository contains two comprehensive Bash scripts for automating Azure user lifecycle management using Microsoft Entra ID:

- **`azure_user_onboarding.sh`** - Automates the process of onboarding new users to Azure resources
- **`azure_user_offboarding.sh`** - Automates the process of offboarding users from Azure resources

## Prerequisites

> **Note**: These scripts use the modern `az entra` commands instead of the deprecated `az ad` commands. Microsoft rebranded Azure Active Directory to Microsoft Entra ID, and the Azure CLI now provides dedicated Entra ID commands for better clarity and functionality.

1. **Azure CLI** - Both scripts require the Azure CLI to be installed
   ```bash
   # Install Azure CLI (macOS)
   brew install azure-cli
   
   # Login to Azure
   az login
   ```

2. **Required Permissions** - Your account needs the following roles:
   - **User Access Administrator** - For managing RBAC role assignments
   - **Privileged Role Administrator** - For managing Microsoft Entra ID users and groups

3. **Additional Tools** (for certain features):
   - `jq` - For JSON processing (used in offboarding script)
   - `openssl` - For password generation (used in onboarding script)

## Onboarding Script (`azure_user_onboarding.sh`)

### Features
- Creates new Microsoft Entra ID users (if they don't exist)
- Adds users to specified Microsoft Entra ID groups
- Assigns RBAC roles at subscription or resource group level
- **Manages SSH keys on Azure Linux VMs (azroot account)**
- **Adds SSH public keys to existing azroot authorized_keys**
- Comprehensive logging and audit trail
- Dry-run mode for testing
- Input validation and error handling
- Optional welcome email functionality (placeholder)

### Usage

#### Basic Onboarding
```bash
./azure_user_onboarding.sh \
  -u john.doe@company.com \
  -d "John Doe" \
  -s "12345678-1234-1234-1234-123456789012"
```

#### Advanced Onboarding with Custom Groups and Roles
```bash
./azure_user_onboarding.sh \
  -u jane.smith@company.com \
  -d "Jane Smith" \
  -s "12345678-1234-1234-1234-123456789012" \
  -g "IT-Team,Project-Alpha" \
  -R "Contributor,Storage Blob Data Reader" \
  -r "production-rg" \
  -e
```

#### Onboarding with VM SSH Access
```bash
./azure_user_onboarding.sh \
  -u dev.user@company.com \
  -d "Dev User" \
  -s "12345678-1234-1234-1234-123456789012" \
  --manage-vms \
  --vm-resource-group "vm-rg" \
  --vm-names "web01,web02,db01" \
  --ssh-public-key "~/.ssh/id_rsa.pub"
```

### Parameters

| Parameter | Description | Required |
|-----------|-------------|----------|
| `-u, --user-principal` | User Principal Name (email address) | Yes |
| `-d, --display-name` | Display name for the user | Yes |
| `-s, --subscription` | Azure subscription ID | Yes |
| `-r, --resource-group` | Specific resource group to grant access to | No |
| `-g, --entra-groups` | Comma-separated list of Microsoft Entra ID groups | No |
| `-R, --rbac-roles` | Comma-separated list of RBAC roles to assign | No |
| `-n, --dry-run` | Preview changes without executing them | No |
| `-e, --send-email` | Send welcome email with access details | No |
| `--manage-vms` | Enable VM SSH key management | No |
| `--vm-resource-group` | Resource group containing the VMs | No* |
| `--vm-names` | Comma-separated list of VM names (auto-discover if empty) | No |
| `--ssh-public-key` | SSH public key to add to azroot account (file path or key string) | No* |
| `-h, --help` | Display help message | No |

*Required when `--manage-vms` is enabled

## Offboarding Script (`azure_user_offboarding.sh`)

### Features
- Disables Microsoft Entra ID user accounts
- Removes users from all Microsoft Entra ID groups
- Revokes all RBAC role assignments
- **Clears SSH keys from Azure Linux VMs (azroot account)**
- **Backs up authorized_keys before clearing**
- Creates comprehensive backup of user's access data
- Identifies owned resources that need reassignment
- Comprehensive logging and audit trail
- Dry-run mode for testing
- Confirmation prompts with override options

### Usage

#### Full Offboarding (Default)
```bash
./azure_user_offboarding.sh \
  -u john.doe@company.com \
  -s "12345678-1234-1234-1234-123456789012"
```

#### Selective Offboarding (Keep Account Active)
```bash
./azure_user_offboarding.sh \
  -u jane.smith@company.com \
  -s "12345678-1234-1234-1234-123456789012" \
  --no-disable-user
```

#### Offboarding with VM SSH Removal
```bash
./azure_user_offboarding.sh \
  -u dev.user@company.com \
  -s "12345678-1234-1234-1234-123456789012" \
  --manage-vms \
  --vm-resource-group "vm-rg" \
  --vm-names "web01,web02,db01"
```

#### Dry Run (Preview Changes)
```bash
./azure_user_offboarding.sh \
  -u test.user@company.com \
  -s "12345678-1234-1234-1234-123456789012" \
  -n
```

### Parameters

| Parameter | Description | Required |
|-----------|-------------|----------|
| `-u, --user-principal` | User Principal Name (email address) | Yes |
| `-s, --subscription` | Azure subscription ID | Yes |
| `--no-disable-user` | Skip disabling the user account | No |
| `--no-remove-groups` | Skip removing user from Microsoft Entra ID groups | No |
| `--no-revoke-roles` | Skip revoking RBAC role assignments | No |
| `--no-backup` | Skip creating backup of user's access | No |
| `--manage-vms` | Enable VM SSH key management | No |
| `--vm-resource-group` | Resource group containing the VMs | No* |
| `--vm-names` | Comma-separated list of VM names (auto-discover if empty) | No |
| `-f, --force` | Force execution without confirmation prompts | No |
| `-n, --dry-run` | Preview changes without executing them | No |
| `-h, --help` | Display help message | No |

*Required when `--manage-vms` is enabled

## VM SSH Key Management

Both scripts now support managing SSH keys on Azure Linux VMs for the **azroot account** as part of the user lifecycle process. This simplified approach focuses on key management rather than user account creation.

### How It Works

The VM management functionality uses **Azure VM Extensions** (specifically the CustomScript extension) to execute commands on your Linux VMs without requiring direct SSH access to the machines. This approach:

- ✅ Works with VMs that don't have public IPs
- ✅ Doesn't require opening SSH ports to the internet  
- ✅ Uses Azure's secure communication channels
- ✅ Maintains audit logs through Azure Activity Log
- ✅ Focuses on existing `azroot` account only

### Onboarding VM Features

**SSH Key Management:**
- Adds SSH public keys to the `azroot` account's `authorized_keys` file
- Creates SSH directory structure if it doesn't exist (`/home/azroot/.ssh/`)
- Sets proper permissions (700 for `.ssh`, 600 for `authorized_keys`)
- Prevents duplicate key entries
- Supports all common SSH key types (RSA, DSA, Ed25519, ECDSA)

**Auto-Discovery:**
- If no VM names are specified, discovers all Linux VMs in the resource group
- Skips Windows VMs automatically
- Handles VM power states gracefully

### Offboarding VM Features

**SSH Key Removal:**
- Backs up existing `authorized_keys` files before modification (timestamped backup)
- **Clears ALL SSH keys** from the `azroot` account's `authorized_keys` file
- Maintains proper file ownership and permissions
- Does NOT remove the `azroot` user account

### VM Management Examples

#### Onboard user with SSH access to specific VMs
```bash
./azure_user_onboarding.sh \
  -u alice@company.com \
  -d "Alice Smith" \
  -s "your-subscription-id" \
  --manage-vms \
  --vm-resource-group "production-vms" \
  --vm-names "web01,web02,api01" \
  --ssh-public-key "ssh-rsa AAAAB3NzaC1yc2E..."
```

#### Onboard user with auto-discovery of VMs
```bash
./azure_user_onboarding.sh \
  -u bob@company.com \
  -d "Bob Johnson" \
  -s "your-subscription-id" \
  --manage-vms \
  --vm-resource-group "development-vms" \
  --ssh-public-key "~/.ssh/id_ed25519.pub"
```

#### Offboard user and clear SSH keys from azroot
```bash
./azure_user_offboarding.sh \
  -u alice@company.com \
  -s "your-subscription-id" \
  --manage-vms \
  --vm-resource-group "production-vms"
```

#### Offboard with specific VMs and auto-discovery disabled
```bash
./azure_user_offboarding.sh \
  -u bob@company.com \
  -s "your-subscription-id" \
  --manage-vms \
  --vm-resource-group "development-vms" \
  --vm-names "dev01,dev02,test01"
```

### VM Management Prerequisites

1. **VM Requirements:**
   - Linux VMs only (Windows VMs are skipped)
   - Azure VM Agent must be installed and running
   - VMs must be in a running state (or the script will attempt anyway)
   - `azroot` account must exist on the VMs

2. **Azure Permissions:**
   - `Virtual Machine Contributor` role on the resource group containing VMs
   - `Virtual Machine Extension Contributor` for installing VM extensions

3. **Network Requirements:**
   - No special network configuration required
   - Works with VMs behind NAT gateways or without public IPs
   - Uses Azure's internal communication channels

### VM Management Best Practices

**Security:**
- Always use dry-run mode first to preview changes
- Use strong SSH keys (Ed25519 recommended)
- Regularly rotate SSH keys
- Monitor VM extension execution logs
- Remember that offboarding **clears ALL keys** from azroot account

**Operational:**
- Group VMs by environment/purpose in separate resource groups
- Use consistent naming conventions for VMs
- Document which users have keys added to which VMs
- Test VM management in development environments first
- Consider the impact of clearing all keys during offboarding

**Key Management:**
- Keep track of which keys are added to which VMs
- Offboarding removes **ALL** keys from azroot, not just the specific user's key
- Consider using separate service accounts if you need more granular control
- Backup `authorized_keys` files before offboarding (script does this automatically)

**Troubleshooting:**
- Check Azure Activity Log for VM extension execution details
- Verify VM Agent is running: `az vm get-instance-view`
- Ensure VMs are in running state for best results
- Check VM extension logs on the VM: `/var/log/azure/`

## Security Best Practices

### Authentication
- Both scripts use Azure CLI authentication (no hardcoded credentials)
- Support for Managed Identity when running in Azure environments
- Credential validation before script execution

### Permissions
- Scripts validate required permissions before execution
- Follow principle of least privilege
- Comprehensive logging for audit purposes

### Data Protection
- User data backup created before offboarding
- Sensitive information handling with appropriate logging levels
- Secure temporary password generation for new users

## Logging and Auditing

Both scripts create detailed log files with timestamps:
- **Onboarding logs**: `onboarding_YYYYMMDD_HHMMSS.log`
- **Offboarding logs**: `offboarding_YYYYMMDD_HHMMSS.log`
- **User backups**: `user_backup_username_YYYYMMDD_HHMMSS.json`

Log levels include:
- `INFO` - General information and successful operations
- `WARN` - Warnings and non-critical issues
- `ERROR` - Errors that prevent successful completion

## Customization

### Default Roles
The onboarding script assigns the `Reader` role by default if no roles are specified. You can modify this in the script:

```bash
# Set default roles - adjust based on your organization's needs
RBAC_ROLES=("Reader")
```

### Email Integration
The onboarding script includes a placeholder for welcome email functionality. Integrate with your organization's email system:

- Microsoft Graph API
- SendGrid
- Organization's SMTP server
- PowerShell Send-MailMessage

### Group Templates
You can modify the scripts to include organization-specific default groups or role templates.

## Error Handling

Both scripts include comprehensive error handling:
- Input validation with detailed error messages
- Azure CLI command validation
- Graceful handling of missing resources
- Rollback capabilities where appropriate

## Integration

These scripts can be integrated into:
- CI/CD pipelines
- HR systems
- Identity management workflows
- Automated provisioning systems
- PowerShell DSC or Ansible playbooks

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Verify your account has the required Microsoft Entra ID and RBAC roles
   - Check if you're logged into the correct Azure tenant

2. **User Already Exists**
   - The onboarding script will skip user creation if the user already exists
   - It will still process group and role assignments

3. **Subscription Not Found**
   - Verify the subscription ID format (must be a valid GUID)
   - Ensure you have access to the specified subscription

4. **Group Not Found**
   - The scripts will log warnings for non-existent groups
   - Verify group names are correct and exist in your tenant

### Debug Mode
Run scripts with bash debug mode for detailed troubleshooting:
```bash
bash -x ./azure_user_onboarding.sh [parameters]
```

## License

These scripts are provided as-is for educational and operational purposes. Please review and test thoroughly before using in production environments.

## Contributing

1. Test all changes thoroughly in a development environment
2. Follow existing code style and documentation patterns
3. Update this README for any new features or changes
4. Ensure all security best practices are maintained