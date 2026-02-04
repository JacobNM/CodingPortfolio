# Azure VM SSH Key Management Scripts

This repository contains two Bash scripts designed to automate the management of SSH keys on Azure Virtual Machines. These scripts focus specifically on adding and removing SSH public keys from the `azroot` account on Azure VMs, with **fully interactive guided workflows** that make VM access management simple for both technical and non-technical users.

## Scripts Overview

### 🔑 `interactive_vm_ssh_onboarding.sh`

Adds SSH public keys to the `azroot` account on specified Azure VMs, enabling secure SSH access for users. Features **intelligent interactive mode** that guides users through subscription selection, resource group discovery, VM selection, and SSH key configuration.

### 🗑️ `interactive_vm_ssh_offboarding.sh`  

Removes specific SSH public keys from the `azroot` account on specified Azure VMs, revoking SSH access for users. Includes **interactive backup management** and **guided SSH key selection** for safe access removal.

## Prerequisites

Before using these scripts, ensure you have:

1. **Azure CLI installed** - [Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Azure CLI logged in** - Run `az login` to authenticate
3. **Appropriate Azure permissions** - VM Contributor role or VM Administrator Login role for the target VMs
4. **SSH public key** - A valid SSH public key for onboarding operations
5. **Bash environment** - The scripts require Bash shell

## Usage Modes

Both scripts support three flexible operation modes:

### 1. 🎯 **Interactive Mode** (Recommended)

**Run without any parameters** for a fully guided experience:
- **Smart subscription selection** from your available Azure subscriptions
- **Filtered resource group selection** (shows only groups containing VMs)
- **Multi-select VM management** with visual confirmation
- **Flexible SSH key input** (file path, direct paste, or auto-discovery)
- **Visual progress tracking** with real-time status updates
- **Intelligent confirmation prompts** with operation summaries

### 2. Command Line Mode

Direct parameter specification for scripted or advanced operations.

### 3. CSV File Mode  

Batch processing using CSV files for bulk user management operations.

## 🎯 Interactive Mode (Recommended - Easiest Way to Get Started)

**Simply run without parameters for a fully guided experience:**

```bash
# For onboarding (adding SSH access)
./interactive_vm_ssh_onboarding.sh

# For offboarding (removing SSH access)
./interactive_vm_ssh_offboarding.sh
```

### Why Interactive Mode?

**🎯 Perfect for All Users** - No Azure expertise required, visual confirmation, error prevention through validation

**⚡ Smart & Efficient** - Auto-discovery of resources, real-time validation, multi-select capabilities, progress tracking

**🛡️ Safe Operations** - Preview mode, confirmation prompts, intelligent filtering, guided backup management

### What You Get:

**🎮 User-Friendly Selection Process**
- **Subscription Selection**: Choose from a numbered list of your subscriptions
- **Resource Group Selection**: See only resource groups that actually contain VMs
- **VM Selection**: Multi-select interface with `[y/n/a]` options (Yes/No/All)
- **SSH Key Configuration**: Multiple input methods with smart defaults

**📋 Visual Progress and Confirmation**
- **Operation Summary**: Clear preview of what will be done before execution
- **Progress Indicators**: Real-time status updates during multi-VM operations
- **Color-coded Output**: Green for success, red for errors, yellow for warnings
- **Final Confirmation**: Detailed summary with confirmation prompt before execution

**🔧 Flexible SSH Key Handling**
- **File Path Input**: Browse to your SSH key file (`~/.ssh/id_rsa.pub`)
- **Direct Key Paste**: Copy and paste SSH key content directly
- **Auto-detection**: Script can find common SSH key locations
- **Key Validation**: Real-time validation of SSH key format and type

### Interactive Mode Flow Example:

```
🔐 Azure VM SSH Key Onboarding - Interactive Mode
================================================

✅ Step 1: Azure Subscription Selection
   Available subscriptions:
   [1] Production Environment (12345678-1234-1234-1234-123456789012)
   [2] Development Environment (87654321-4321-4321-4321-210987654321)
   [3] Staging Environment (11111111-2222-3333-4444-555555555555)
   
   Select subscription [1-3]: 1

✅ Step 2: Resource Group Selection  
   Resource groups with VMs:
   [1] web-servers-rg (3 VMs)
   [2] database-servers-rg (2 VMs) 
   [3] app-servers-rg (4 VMs)
   
   Select resource group [1-3]: 1

✅ Step 3: VM Selection
   Available VMs in 'web-servers-rg':
   [1] web-01 (Running) - Standard_B2s
   [2] web-02 (Running) - Standard_B2s  
   [3] web-03 (Stopped) - Standard_B2s [SKIPPED - Not Running]
   
   Select VMs:
   Process web-01? [y/n/a]: y
   Process web-02? [y/n/a]: y
   
   Selected VMs: web-01, web-02

✅ Step 4: SSH Key Configuration
   [1] Use default key (~/.ssh/id_rsa.pub)
   [2] Specify custom key file path
   [3] Paste SSH key content directly
   
   Choose SSH key method [1-3]: 1
   ✅ Found valid SSH key: ssh-rsa AAAAB3NzaC1... user@hostname

✅ Step 5: Operation Summary
   Username: john.doe
   Subscription: Production Environment
   Resource Group: web-servers-rg
   Target VMs: web-01, web-02
   SSH Key: ~/.ssh/id_rsa.pub (RSA 2048-bit)
   
   Proceed with onboarding? [y/N]: y

🚀 Processing VMs...
   ✅ web-01: SSH key added successfully
   ✅ web-02: SSH key added successfully
   
   Operation completed: 2/2 VMs processed successfully
```

## 🔧 Command Line Parameters (Advanced Usage)

When using command line mode instead of interactive mode:

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-u, --username <username>` | ✅* | Username for identification |
| `-s, --subscription <subscription_id>` | ✅* | Azure subscription ID |
| `-k, --key <ssh_public_key>` | ✅* | SSH public key file path or key content (for removal in offboarding) |
| `-g, --resource-group <vm_resource_group>` | ✅* | Resource group containing VMs |
| `-v, --vm <vm_name>` | ❌* | VM name (can be specified multiple times, or omit for auto-discovery) |
| `-f, --file <csv_file>` | ✅** | CSV file for batch operations |
| `-n, --no-backup` | ❌ | No backup (skip backup of authorized_keys - offboarding only) |
| `-d, --dry-run` | ❌ | Dry run mode (show what would be done) |
| `-h, --help` | ❌ | Display help message |

*Required for command line mode (except `-v` which enables auto-discovery when omitted)  
**Required for CSV file mode (replaces command line parameters)

### Command Line Usage Examples

#### Single VM operations

```bash
# Onboarding (add SSH key)
./interactive_vm_ssh_onboarding.sh -u john.doe -s "subscription-id" -k ~/.ssh/id_rsa.pub -g "rg-name" -v "vm-name"

# Offboarding (remove SSH key) 
./interactive_vm_ssh_offboarding.sh -u john.doe -s "subscription-id" -k ~/.ssh/id_rsa.pub -g "rg-name" -v "vm-name"
```

#### Multiple VMs

```bash
# Add to multiple VMs
./interactive_vm_ssh_onboarding.sh -u user -s "sub-id" -k ~/.ssh/key.pub -g "rg" -v "vm1" -v "vm2" -v "vm3"

# Remove from all VMs in resource group (auto-discovery)
./interactive_vm_ssh_offboarding.sh -u user -s "sub-id" -k ~/.ssh/key.pub -g "rg"
```

#### Batch processing and dry runs

```bash
# CSV batch processing
./interactive_vm_ssh_onboarding.sh -f onboarding_batch.csv
./interactive_vm_ssh_offboarding.sh -f offboarding_batch.csv

# Dry run mode (preview changes)
./interactive_vm_ssh_onboarding.sh -f batch.csv -d
```

## 📄 CSV File Formats for Batch Operations

### Onboarding CSV Format

```csv
username,subscription_id,ssh_public_key,vm_resource_group,vm_names
john.doe,12345678-1234-1234-1234-123456789012,~/.ssh/id_rsa.pub,prod-rg,"vm01,vm02,vm03"
jane.smith,87654321-4321-4321-4321-210987654321,~/.ssh/jane_key.pub,test-rg,vm04
# Empty vm_names field enables auto-discovery:
sara.jones,22222222-3333-4444-5555-666666666666,~/.ssh/sara_key.pub,staging-rg,
```

### Offboarding CSV Format

```csv
username,subscription_id,ssh_public_key,vm_resource_group,vm_names,backup_keys
john.doe,12345678-1234-1234-1234-123456789012,~/.ssh/id_rsa.pub,prod-rg,"vm01,vm02",true
jane.smith,87654321-4321-4321-4321-210987654321,~/.ssh/jane_key.pub,test-rg,vm03,false
# Empty vm_names field enables auto-discovery:
sara.jones,22222222-3333-4444-5555-666666666666,~/.ssh/sara_key.pub,staging-rg,,true
```

**CSV Requirements:**
- Header row is required and must match exactly
- Multiple VM names should be comma-separated within quotes: `"vm01,vm02,vm03"`
- Leave `vm_names` empty for auto-discovery of all VMs in the resource group
- SSH keys can be file paths or direct key content (quote content with spaces)
- Offboarding only: `backup_keys` field controls whether to backup authorized_keys before removal

## 🗑️ SSH Offboarding Script Usage

### Quick Start (Interactive Mode)

```bash
# Just run the script - no parameters needed!
./interactive_vm_ssh_offboarding.sh
```
The script will interactively guide you through:
- Subscription and resource group selection  
- VM selection with status validation
- SSH key identification (file or direct input)
- Backup confirmation (with smart defaults)
- Operation preview and confirmation

### Advanced: Command Line Mode

```bash
# Command line mode for scripting/automation
./interactive_vm_ssh_offboarding.sh -u <username> -s <subscription_id> -k <ssh_public_key> -g <vm_resource_group> -v <vm_name> [OPTIONS]

# CSV file mode for batch operations
./interactive_vm_ssh_offboarding.sh -f <csv_file> [OPTIONS]
```

*See [Command Line Parameters](#-command-line-parameters-advanced-usage) section above for full parameter details and examples.*

### CSV File Format for Offboarding

Create a CSV file with the following header and format:

```csv
username,subscription_id,ssh_public_key,vm_resource_group,vm_names,backup_keys
john.doe,12345678-1234-1234-1234-123456789012,~/.ssh/id_rsa.pub,prod-rg,"vm01,vm02",true
jane.smith,87654321-4321-4321-4321-210987654321,~/.ssh/jane_key.pub,test-rg,vm03,false
mike.wilson,11111111-2222-3333-4444-555555555555,"ssh-rsa AAAAB3Nz...",dev-rg,"vm04,vm05",true
# Empty vm_names field enables auto-discovery of all VMs in the resource group:
sara.jones,22222222-3333-4444-5555-666666666666,~/.ssh/sara_key.pub,staging-rg,,true
```

**CSV Requirements:**

- Header row is required and must match exactly
- Multiple VM names should be comma-separated within a quoted field (for example: `"vm01,vm02,vm03"`)
- Leave vm_names empty for auto-discovery of all VMs in the resource group
- `ssh_public_key` is required and must contain a valid SSH public key
- `backup_keys`: true/false - whether to backup authorized_keys before changes
- Direct key content should be quoted to handle spaces

## How It Works

### Script Processing Workflow

### Onboarding Process (Adding SSH Access)

1. **Input Processing** - Handles command line parameters, CSV file content, or interactive prompts
2. **Prerequisites Check** - Verifies Azure CLI installation and login status
3. **Input Validation** - Validates all parameters and SSH key format
4. **Azure Authentication** - Sets active subscription and verifies resource group access
5. **Resource Discovery** - Auto-discovers VMs when not explicitly specified (interactive + command line)
6. **Batch Processing** - For each target VM:
   - **VM Status Check** - Verifies each VM exists and has `PowerState/running` status
   - **Progress Tracking** - Displays real-time progress with colored status indicators
   - **SSH Key Management** - Uses `az vm run-command` to execute secure scripts on VMs
   - **Directory Creation** - Ensures `/home/azroot/.ssh/` exists with correct permissions (700)
   - **Key Installation** - Adds SSH key to `authorized_keys` with proper permissions (600)
   - **Duplicate Prevention** - Checks if key already exists before adding
   - **Operation Summary** - Provides success/failure reporting

### Offboarding Process (Removing SSH Access)

1. **Input Processing** - Handles command line parameters, CSV file content, or interactive prompts  
2. **Prerequisites Check** - Verifies Azure CLI installation and login status
3. **Input Validation** - Validates parameters and SSH key format (if specific key removal)
4. **Azure Authentication** - Sets active subscription and verifies resource group access
5. **Resource Discovery** - Auto-discovers VMs when not explicitly specified (interactive + command line)
6. **Batch Processing** - For each target VM:
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

- **Confirmation Prompts** - Interactive user confirmation required before making changes to VMs (bypassed in dry-run mode)
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
- **Confirmation Prompts** - Interactive prompts require user confirmation before making changes to VMs
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

1. **Start with Interactive Mode** - Use guided mode for learning and one-time operations
   - **New users**: Interactive mode eliminates learning curve and prevents mistakes
   - **Troubleshooting**: Interactive validation helps identify issues quickly
   - **Exploration**: Discover available resources without prior knowledge of structure
   - **Safety**: Built-in confirmations prevent accidental operations

2. **Choose the Right Mode for Your Task**
   - **Interactive Mode**: One-time operations, learning, troubleshooting, exploration
   - **Command Line Mode**: Scripting, automation, CI/CD integration
   - **CSV File Mode**: Bulk operations, user lifecycle management, regular batch processing

3. **Always test first** - Use dry run mode (`-d`) before actual execution
4. **Keep logs** - Review log files for operation status and troubleshooting
5. **Backup strategy** - Keep backups enabled for offboarding operations
6. **Principle of least privilege** - Use minimal required Azure permissions
7. **Regular audits** - Periodically review SSH access on VMs

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

## Requirements

- **Operating System**: Linux, macOS, or Windows with WSL/Git Bash
- **Azure CLI**: Version 2.0 or higher
- **Bash**: Version 4.0 or higher
- **Permissions**: VM Contributor or VM Administrator Login role

## Support

For issues or questions:

1. Check the generated log files for error information
2. Verify Azure permissions and VM status
3. Ensure SSH key format is valid
4. Test with dry run mode first

---

**Note**: These scripts operate exclusively on the `azroot` account. They do not modify other user accounts or system configurations on the target VMs.
