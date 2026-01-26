# Azure VM SSH Key Management Scripts

This repository contains two Bash scripts designed to automate the management of SSH keys on Azure Virtual Machines. These scripts focus specifically on adding and removing SSH public keys from the `azroot` account on Azure VMs, supporting both individual command-line operations and batch processing via CSV files.

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

## Usage Modes

Both scripts support two operation modes:

### 1. Command Line Mode

Direct parameter specification for single or multiple operations.

### 2. CSV File Mode  

Batch processing using CSV files containing multiple operations.

## 🔑 SSH Onboarding Script Usage

### Basic Syntax

```bash
# Command line mode
./azure_vm_ssh_onboarding.sh -u <username> -s <subscription_id> -k <ssh_public_key> -g <vm_resource_group> -v <vm_name> [OPTIONS]

# CSV file mode
./azure_vm_ssh_onboarding.sh -f <csv_file> [OPTIONS]
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-u <username>` | ✅* | Username for identification |
| `-s <subscription_id>` | ✅* | Azure subscription ID |
| `-k <ssh_public_key>` | ✅* | SSH public key file path or key content |
| `-g <vm_resource_group>` | ✅* | Resource group containing VMs |
| `-v <vm_name>` | ✅* | VM name (can be specified multiple times) |
| `-f <csv_file>` | ✅** | CSV file for batch operations |
| `-d` | ❌ | Dry run mode (show what would be done) |
| `-h` | ❌ | Display help message |

*Required for command line mode  
**Required for CSV file mode (replaces command line parameters)

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

#### Batch processing with CSV file

```bash
./azure_vm_ssh_onboarding.sh -f onboarding_batch.csv
```

#### CSV file with dry run

```bash
./azure_vm_ssh_onboarding.sh -f onboarding_batch.csv -d
```

### CSV File Format for Onboarding

Create a CSV file with the following header and format:

```csv
username,subscription_id,ssh_public_key,vm_resource_group,vm_names
john.doe,12345678-1234-1234-1234-123456789012,~/.ssh/id_rsa.pub,prod-rg,"vm01,vm02,vm03"
jane.smith,87654321-4321-4321-4321-210987654321,~/.ssh/jane_key.pub,test-rg,vm04
mike.wilson,11111111-2222-3333-4444-555555555555,"ssh-rsa AAAAB3Nz...",dev-rg,"vm05,vm06"
```

**CSV Requirements:**

- Header row is required and must match exactly
- Multiple VM names should be comma-separated and quoted
- SSH keys can be file paths or direct key content
- Direct key content should be quoted to handle spaces

## 🗑️ SSH Offboarding Script Usage

### Basic Syntax

```bash
# Command line mode
./azure_vm_ssh_offboarding.sh -u <username> -s <subscription_id> -g <vm_resource_group> -v <vm_name> [OPTIONS]

# CSV file mode
./azure_vm_ssh_offboarding.sh -f <csv_file> [OPTIONS]
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-u <username>` | ✅* | Username for identification |
| `-s <subscription_id>` | ✅* | Azure subscription ID |
| `-g <vm_resource_group>` | ✅* | Resource group containing VMs |
| `-v <vm_name>` | ✅* | VM name (can be specified multiple times) |
| `-k <ssh_public_key>` | ❌* | Specific SSH public key to remove (file path or key content) |
| `-a` | ❌* | Remove ALL SSH keys from azroot account |
| `-f <csv_file>` | ✅** | CSV file for batch operations |
| `-n` | ❌ | No backup (skip backup of authorized_keys) |
| `-d` | ❌ | Dry run mode (show what would be done) |
| `-h` | ❌ | Display help message |

*Required for command line mode (must specify either `-k` or `-a`)  
**Required for CSV file mode (replaces command line parameters)

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

#### Batch processing with CSV file

```bash
./azure_vm_ssh_offboarding.sh -f offboarding_batch.csv
```

#### CSV file with dry run

```bash
./azure_vm_ssh_offboarding.sh -f offboarding_batch.csv -d
```

### CSV File Format for Offboarding

Create a CSV file with the following header and format:

```csv
username,subscription_id,ssh_public_key,vm_resource_group,vm_names,remove_all_keys,backup_keys
john.doe,12345678-1234-1234-1234-123456789012,~/.ssh/id_rsa.pub,prod-rg,"vm01,vm02",false,true
jane.smith,87654321-4321-4321-4321-210987654321,,test-rg,vm03,true,false
mike.wilson,11111111-2222-3333-4444-555555555555,"ssh-rsa AAAAB3Nz...",dev-rg,"vm04,vm05",false,true
```

**CSV Requirements:**

- Header row is required and must match exactly
- Multiple VM names should be comma-separated and quoted
- `ssh_public_key` can be empty if `remove_all_keys` is true
- `remove_all_keys`: true/false - whether to remove all SSH keys
- `backup_keys`: true/false - whether to backup authorized_keys before changes
- Direct key content should be quoted to handle spaces

## How It Works

### Onboarding Process

1. **Input Processing** - Parses command line parameters or CSV file content
2. **Prerequisites Check** - Verifies Azure CLI installation and login status
3. **Input Validation** - Validates all parameters and SSH key format
4. **Azure Authentication** - Sets active subscription and verifies resource group access
5. **Batch Processing** - For each row (CSV mode) or single operation (command line):
   - **VM Status Check** - Verifies each VM exists and has `PowerState/running` status
   - **Progress Tracking** - Displays real-time progress with colored status indicators
   - **SSH Key Management** - Uses `az vm run-command` to execute secure scripts on VMs
   - **Directory Creation** - Ensures `/home/azroot/.ssh/` exists with correct permissions (700)
   - **Key Installation** - Adds SSH key to `authorized_keys` with proper permissions (600)
   - **Duplicate Prevention** - Checks if key already exists before adding
   - **Operation Summary** - Provides detailed success/failure reporting

### Offboarding Process

1. **Input Processing** - Parses command line parameters or CSV file content
2. **Prerequisites Check** - Verifies Azure CLI installation and login status
3. **Input Validation** - Validates parameters and SSH key format (if specific key removal)
4. **Azure Authentication** - Sets active subscription and verifies resource group access
5. **Batch Processing** - For each row (CSV mode) or single operation (command line):
   - **VM Status Check** - Verifies each VM exists and has `PowerState/running` status
   - **Progress Tracking** - Displays real-time progress with colored status indicators
   - **Backup Creation** - Creates timestamped backup of `authorized_keys` (unless disabled)
   - **SSH Key Removal** - Uses `az vm run-command` to execute secure removal scripts
   - **Selective or Complete Removal** - Removes specific keys or clears all keys based on parameters
   - **File Integrity** - Maintains proper file permissions and ownership
   - **Operation Summary** - Provides detailed success/failure reporting

### Key Technical Features

- **Real-time Progress Indicators** - Visual feedback during multi-VM operations
- **Colored Status Output** - Green for success, red for errors, yellow for warnings
- **Comprehensive Logging** - Timestamped logs for all operations and errors
- **Error Recovery** - Continues processing remaining VMs even if some fail
- **Dry Run Support** - Preview mode shows what would be done without making changes
- **VM State Validation** - Only processes VMs that are currently running
- **Azure Integration** - Uses official Azure CLI commands and ARM queries

## Advanced Features

### 📊 Progress Tracking & Visual Feedback

- **Real-time Progress Bars** - Visual indicators for multi-VM operations
- **Color-coded Status Updates** - Green (success), red (error), yellow (warning), blue (info)
- **Operation Summaries** - Detailed reports of successful/failed operations per batch
- **Row-by-row Processing** - Individual status tracking for CSV file operations

### 🔄 Batch Processing Capabilities

- **CSV File Validation** - Comprehensive validation of file format and content
- **Mixed Parameter Support** - Different configurations per row in CSV files
- **Error Isolation** - Failed operations don't stop processing of remaining rows
- **Batch Summary Reports** - Complete overview of all operations performed

### 🛡️ Robust Error Handling

- **Fail-Safe Processing** - Uses `set -euo pipefail` for strict error handling
- **VM State Verification** - Checks `PowerState/running` before attempting operations
- **Connection Validation** - Verifies Azure CLI authentication and permissions
- **Resource Validation** - Confirms subscription and resource group access
- **Graceful Degradation** - Continues processing valid VMs when some are unavailable

### 📋 Comprehensive Logging

- **Timestamped Operations** - Every action logged with precise timestamps
- **Detailed Error Messages** - Specific error details for troubleshooting
- **CSV Processing Logs** - Row-by-row processing status and outcomes
- **VM-level Logging** - Individual VM operation results and status

### 🔧 Flexible SSH Key Handling

- **Multiple Input Methods** - File paths or direct key content
- **Key Format Validation** - Supports RSA, DSS, Ed25519, and ECDSA keys
- **Duplicate Prevention** - Automatically detects and skips existing keys
- **Selective Removal** - Target specific keys or remove all keys

## Security Features

### ✅ Safety Measures

- **Dry Run Mode** - Preview changes before execution (`-d` flag)
- **Automatic Backups** - Offboarding script backs up `authorized_keys` before modification
- **Input Validation** - Validates SSH key format and required parameters
- **Permission Checks** - Verifies Azure access before making changes
- **VM Status Verification** - Only processes running VMs
- **Secure Script Execution** - Uses Azure's `run-command` feature for safe remote execution

### 🔒 Security Considerations

- SSH keys are added only to the `azroot` account
- Scripts require appropriate Azure permissions
- All operations are logged with timestamps
- Backup files are created with timestamps to prevent overwrites
- No direct SSH connections required - uses Azure's secure command execution

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
# Verify login status
az account show
```

#### "Cannot access subscription"

```bash
# Solution: Verify subscription ID and access
az account list --output table
az account set --subscription "your-subscription-id"
# Check current subscription
az account show --query "name"
```

#### "VM not found or not running"

```bash
# Solution: Check VM status and power state
az vm list -g "resource-group-name" -d --output table
# Check specific VM power state
az vm show -g "resource-group-name" -n "vm-name" -d --query "powerState"
# Start VM if needed
az vm start -g "resource-group-name" -n "vm-name"
```

#### "Invalid SSH public key format"

```bash
# Solution: Verify SSH key format and generate if needed
ssh-keygen -l -f ~/.ssh/id_rsa.pub
# Generate new key if needed
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "your_email@example.com"
```

#### "CSV file validation errors"

```bash
# Check CSV file format
head -5 your_file.csv
# Ensure proper header format
echo "username,subscription_id,ssh_public_key,vm_resource_group,vm_names" > header.csv
```

#### "az vm run-command execution failed"

```bash
# Check VM agent status
az vm show -g "resource-group-name" -n "vm-name" --query "osProfile.linuxConfiguration.provisionVMAgent"
# Verify VM has network connectivity
az vm show -g "resource-group-name" -n "vm-name" -d --query "privateIps"
```

### Debug Mode & Log Analysis

For detailed troubleshooting:

1. **Check Log Files** - Both scripts create timestamped log files:

   ```bash
   # Find recent log files
   ls -lt ssh_*boarding_*.log | head -5
   # View detailed logs
   tail -f ssh_onboarding_20240126_143022.log
   ```

2. **Use Dry Run Mode** - Test operations without making changes:

   ```bash
   ./azure_vm_ssh_onboarding.sh -f batch.csv -d
   ```

3. **Verbose Azure CLI Output** - Enable detailed Azure CLI logging:

   ```bash
   export AZURE_CLI_DIAGNOSTICS_TELEMETRY=0
   az config set core.only_show_errors=false
   ```

4. **Check Azure Permissions** - Verify required roles:

   ```bash
   az role assignment list --assignee $(az account show --query user.name -o tsv) --all
   ```

### Performance Optimization

- **Parallel Processing** - Scripts process multiple VMs concurrently where possible
- **Connection Reuse** - Single Azure CLI session for all operations
- **Efficient Queries** - Minimal API calls to reduce execution time
- **Batch Validation** - Pre-validates all inputs before processing begins

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
