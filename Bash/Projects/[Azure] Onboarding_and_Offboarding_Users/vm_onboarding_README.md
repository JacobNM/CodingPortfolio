# Azure VM SSH Key Management Scripts

This repository contains two Bash scripts designed to automate the management of SSH keys on Azure Virtual Machines. These scripts focus specifically on adding and removing SSH public keys from the `azroot` account on Azure VMs.

## Scripts Overview

### 🔑 `azure_vm_ssh_onboarding.sh`
Adds SSH public keys to the `azroot` account on specified Azure VMs, enabling secure SSH access for users.

### 🗑️ `azure_vm_ssh_offboarding.sh`  
Removes SSH public keys from the `azroot` account on specified Azure VMs, revoking SSH access for users.

## Prerequisites

Before using these scripts, ensure you have:

1. **Azure CLI installed** - [Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Azure CLI logged in** - Run `az login` to authenticate
3. **Appropriate Azure permissions** - VM Contributor role or VM Administrator Login role for the target VMs
4. **SSH public key** - A valid SSH public key for onboarding operations
5. **Bash environment** - The scripts require Bash shell

#### Option B: Enhanced with Entra ID Permissions
For full functionality including user/group management, add:

## 🔑 SSH Onboarding Script Usage

### Basic Syntax
```bash
./azure_vm_ssh_onboarding.sh -u <username> -s <subscription_id> -k <ssh_public_key> -g <vm_resource_group> -v <vm_name> [OPTIONS]
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-u <username>` | ✅ | Username for identification |
| `-s <subscription_id>` | ✅ | Azure subscription ID |
| `-k <ssh_public_key>` | ✅ | SSH public key file path or key content |
| `-g <vm_resource_group>` | ✅ | Resource group containing VMs |
| `-v <vm_name>` | ✅ | VM name (can be specified multiple times) |
| `-d` | ❌ | Dry run mode (show what would be done) |
| `-h` | ❌ | Display help message |

### Usage Examples

#### Add SSH key to a single VM
```bash
./azure_vm_ssh_onboarding.sh \
  -u john.doe \
  -s "12345678-1234-1234-1234-123456789012" \
  -k ~/.ssh/id_rsa.pub \
  -g "production-vms-rg" \
  -v "web-server-01"
```

#### Add SSH key to multiple VMs
```bash
./azure_vm_ssh_onboarding.sh \
  -u jane.smith \
  -s "12345678-1234-1234-1234-123456789012" \
  -k ~/.ssh/id_rsa.pub \
  -g "production-vms-rg" \
  -v "web-server-01" -v "web-server-02" -v "db-server-01"
```

#### Dry run to preview changes
```bash
./azure_vm_ssh_onboarding.sh \
  -u john.doe \
  -s "12345678-1234-1234-1234-123456789012" \
  -k ~/.ssh/id_rsa.pub \
  -g "production-vms-rg" \
  -v "web-server-01" \
  -d
```

#### Using SSH key content directly
```bash
./azure_vm_ssh_onboarding.sh \
  -u john.doe \
  -s "12345678-1234-1234-1234-123456789012" \
  -k "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC..." \
  -g "production-vms-rg" \
  -v "web-server-01"
```

## 🗑️ SSH Offboarding Script Usage

### Basic Syntax
```bash
./azure_vm_ssh_offboarding.sh -u <username> -s <subscription_id> -g <vm_resource_group> -v <vm_name> [OPTIONS]
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-u <username>` | ✅ | Username for identification |
| `-s <subscription_id>` | ✅ | Azure subscription ID |
| `-g <vm_resource_group>` | ✅ | Resource group containing VMs |
| `-v <vm_name>` | ✅ | VM name (can be specified multiple times) |
| `-k <ssh_public_key>` | ❌ | Specific SSH public key to remove (file path or key content) |
| `-a` | ❌ | Remove ALL SSH keys from azroot account |
| `-n` | ❌ | No backup (skip backup of authorized_keys) |
| `-d` | ❌ | Dry run mode (show what would be done) |
| `-h` | ❌ | Display help message |

### Usage Examples

#### Remove specific SSH key from a single VM
```bash
./azure_vm_ssh_offboarding.sh \
  -u john.doe \
  -s "12345678-1234-1234-1234-123456789012" \
  -k ~/.ssh/id_rsa.pub \
  -g "production-vms-rg" \
  -v "web-server-01"
```

#### Remove ALL SSH keys from multiple VMs
```bash
./azure_vm_ssh_offboarding.sh \
  -u jane.smith \
  -s "12345678-1234-1234-1234-123456789012" \
  -g "production-vms-rg" \
  -v "web-server-01" -v "web-server-02" -v "db-server-01" \
  -a
```

#### Remove specific key without backup
```bash
./azure_vm_ssh_offboarding.sh \
  -u john.doe \
  -s "12345678-1234-1234-1234-123456789012" \
  -k ~/.ssh/id_rsa.pub \
  -g "production-vms-rg" \
  -v "web-server-01" \
  -n
```

#### Dry run to preview changes
```bash
./azure_vm_ssh_offboarding.sh \
  -u john.doe \
  -s "12345678-1234-1234-1234-123456789012" \
  -k ~/.ssh/id_rsa.pub \
  -g "production-vms-rg" \
  -v "web-server-01" \
  -d
```

## How It Works

### Onboarding Process
1. **Validation** - Validates input parameters and SSH key format
2. **Prerequisites Check** - Verifies Azure CLI installation and login status
3. **Permission Check** - Confirms access to subscription and resource group
4. **VM Processing** - For each specified VM:
   - Checks if VM exists and is running
   - Creates SSH directory structure if needed (`/home/azroot/.ssh/`)
   - Adds SSH key to `authorized_keys` file
   - Sets appropriate permissions and ownership
   - Avoids duplicate key entries

### Offboarding Process
1. **Validation** - Validates input parameters and SSH key format (if provided)
2. **Prerequisites Check** - Verifies Azure CLI installation and login status  
3. **Permission Check** - Confirms access to subscription and resource group
4. **VM Processing** - For each specified VM:
   - Checks if VM exists and is running
   - Creates backup of `authorized_keys` file (unless disabled with `-n`)
   - Removes specific SSH key OR clears all keys (based on parameters)
   - Maintains file permissions and ownership

## Security Features

### ✅ Safety Measures
- **Dry Run Mode** - Preview changes before execution (`-d` flag)
- **Automatic Backups** - Offboarding script backs up `authorized_keys` before modification
- **Input Validation** - Validates SSH key format and required parameters
- **Permission Checks** - Verifies Azure access before making changes
- **VM Status Verification** - Only processes running VMs

### 🔒 Security Considerations
- SSH keys are added only to the `azroot` account
- Scripts require appropriate Azure permissions
- All operations are logged with timestamps
- Backup files are created with timestamps to prevent overwrites

## Logging

Both scripts create detailed log files in the same directory:
- **Onboarding**: `ssh_onboarding_YYYYMMDD_HHMMSS.log`
- **Offboarding**: `ssh_offboarding_YYYYMMDD_HHMMSS.log`

Log entries include:
- Timestamp for each operation
- Success/failure status
- Detailed error messages
- VM processing results

## Best Practices

### 🎯 Operational Best Practices
1. **Always test first** - Use dry run mode (`-d`) before actual execution
2. **Keep logs** - Review log files for operation status and troubleshooting
3. **Backup strategy** - Keep backups enabled for offboarding operations
4. **Principle of least privilege** - Use minimal required Azure permissions
5. **Regular audits** - Periodically review SSH access on VMs

### 🛠️ Technical Best Practices
1. **SSH Key Management**
   - Use strong SSH key algorithms (RSA 2048+ bits, Ed25519 recommended)
   - Regularly rotate SSH keys
   - Use different keys for different environments (dev/staging/prod)

2. **Azure Resource Organization**
   - Group related VMs in logical resource groups
   - Use consistent naming conventions
   - Tag resources appropriately for easier management

3. **Access Control**
   - Limit Azure subscription access
   - Use Azure AD groups for team-based access management
   - Implement monitoring and alerting for VM access

## Error Handling

The scripts include comprehensive error handling:
- **Invalid parameters** - Clear error messages for missing or incorrect inputs
- **Azure authentication** - Checks for proper Azure CLI login
- **Resource access** - Validates subscription and resource group access
- **VM state** - Only processes running VMs, skips stopped/deallocated VMs
- **SSH key format** - Validates SSH public key format before processing

## Troubleshooting

### Common Issues

#### "Not logged in to Azure"
```bash
# Solution: Login to Azure CLI
az login
```

#### "Cannot access subscription"
```bash
# Solution: Verify subscription ID and access
az account list
az account set --subscription "your-subscription-id"
```

#### "VM not found or not running"
```bash
# Solution: Check VM status
az vm list -g "resource-group-name" -d --output table
```

#### "Invalid SSH public key format"
```bash
# Solution: Verify SSH key format
ssh-keygen -l -f ~/.ssh/id_rsa.pub
```

### Debug Mode
For detailed troubleshooting, examine the log files created in the script directory. Each operation is logged with timestamps and detailed status information.

## Requirements

- **Operating System**: Linux, macOS, or Windows with WSL/Git Bash
- **Azure CLI**: Version 2.0 or higher
- **Bash**: Version 4.0 or higher
- **Network**: Internet connectivity to Azure endpoints
- **Permissions**: VM Contributor or VM Administrator Login role

## Support

For issues or questions:
1. Check the generated log files for detailed error information
2. Verify Azure permissions and VM status
3. Ensure SSH key format is valid
4. Test with dry run mode first

---

**Note**: These scripts operate exclusively on the `azroot` account. They do not modify other user accounts or system configurations on the target VMs.