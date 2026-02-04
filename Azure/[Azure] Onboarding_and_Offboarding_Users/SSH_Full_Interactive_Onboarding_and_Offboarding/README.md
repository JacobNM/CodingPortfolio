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

## 🚀 Getting Started - Interactive Mode (Recommended)

**The easiest way to use these scripts is to simply run them without any parameters:**

```bash
# For onboarding (adding SSH access)
./interactive_vm_ssh_onboarding.sh

# For offboarding (removing SSH access)  
./interactive_vm_ssh_offboarding.sh
```

### Why Interactive Mode?

**🎯 Perfect for All Skill Levels**
- **No Azure expertise required** - the script guides you through everything
- **No memorizing command-line parameters** - all options presented clearly
- **Visual confirmation** of selections before execution
- **Error prevention** through validation and smart defaults

**⚡ Faster and More Reliable**
- **Auto-discovery** of subscriptions, resource groups, and VMs
- **Real-time validation** of inputs and Azure resources  
- **Multi-select capabilities** for batch operations on multiple VMs
- **Progress tracking** with visual feedback during operations

**🛡️ Safer Operations**
- **Preview mode** shows exactly what will be done before execution
- **Confirmation prompts** prevent accidental changes
- **Intelligent filtering** shows only relevant resources (running VMs, etc.)
- **Backup management** with guided prompts for offboarding operations

---

## 🎯 Interactive Mode (Easiest Way to Get Started)

Both scripts are designed to be **fully interactive** when run without parameters. This is the recommended approach for most users:

```bash
# Simply run the script without any parameters
./interactive_vm_ssh_onboarding.sh

# Or for offboarding
./interactive_vm_ssh_offboarding.sh
```

### What Interactive Mode Provides:

**🔍 Intelligent Azure Discovery**
- Automatically lists your available Azure subscriptions
- Filters and displays only resource groups containing VMs
- Shows VM status, power state, and key details for informed selection

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

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-u, --username <username>` | ✅* | Username for identification |
| `-s, --subscription <subscription_id>` | ✅* | Azure subscription ID |
| `-k, --key <ssh_public_key>` | ✅* | SSH public key file path or key content |
| `-g, --resource-group <vm_resource_group>` | ✅* | Resource group containing VMs |
| `-v, --vm <vm_name>` | ❌* | VM name (can be specified multiple times, or omit for auto-discovery) |
| `-f, --file <csv_file>` | ✅** | CSV file for batch operations |
| `-d, --dry-run` | ❌ | Dry run mode (show what would be done) |
| `-h, --help` | ❌ | Display help message |

*Required for command line mode (except `-v` which enables auto-discovery when omitted)  
**Required for CSV file mode (replaces command line parameters)

### Usage Examples

#### Add SSH key to a single VM

```bash
./interactive_vm_ssh_onboarding.sh \
  -u john.doe \
  -s "12345678-1234-1234-1234-123456789012" \
  -k ~/.ssh/id_rsa.pub \
  -g "production-vms-rg" \
  -v "web-server-01"
```

#### Add SSH key to multiple VMs

```bash
./interactive_vm_ssh_onboarding.sh \
  -u jane.smith \
  -s "12345678-1234-1234-1234-123456789012" \
  -k ~/.ssh/id_rsa.pub \
  -g "production-vms-rg" \
  -v "web-server-01" -v "web-server-02" -v "db-server-01"
```

#### Add SSH key to all VMs in resource group (auto-discovery)

```bash
./interactive_vm_ssh_onboarding.sh \
  -u jane.smith \
  -s "87654321-4321-4321-4321-210987654321" \
  -k ~/.ssh/jane_key.pub \
  -g "production-rg"
  # No -v parameter = discovers all VMs automatically
```

#### Dry run to preview changes

```bash
./interactive_vm_ssh_onboarding.sh \
  -u john.doe \
  -s "12345678-1234-1234-1234-123456789012" \
  -k ~/.ssh/id_rsa.pub \
  -g "production-vms-rg" \
  -v "web-server-01" \
  -d
```

*Note: Dry run mode bypasses confirmation prompts and shows what changes would be made*

#### Using SSH key content directly

```bash
./interactive_vm_ssh_onboarding.sh \
  -u john.doe \
  -s "12345678-1234-1234-1234-123456789012" \
  -k "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC..." \
  -g "production-vms-rg" \
  -v "web-server-01"
```

#### Batch processing with CSV file

```bash
./interactive_vm_ssh_onboarding.sh -f onboarding_batch.csv
```

#### CSV file with dry run

```bash
./interactive_vm_ssh_onboarding.sh -f onboarding_batch.csv -d
```

### CSV File Format for Onboarding

Create a CSV file with the following header and format:

```csv
username,subscription_id,ssh_public_key,vm_resource_group,vm_names
john.doe,12345678-1234-1234-1234-123456789012,~/.ssh/id_rsa.pub,prod-rg,"vm01,vm02,vm03"
jane.smith,87654321-4321-4321-4321-210987654321,~/.ssh/jane_key.pub,test-rg,vm04
mike.wilson,11111111-2222-3333-4444-555555555555,"ssh-rsa AAAAB3Nz...",dev-rg,"vm05,vm06"
# Empty vm_names field enables auto-discovery of all VMs in the resource group:
sara.jones,22222222-3333-4444-5555-666666666666,~/.ssh/sara_key.pub,staging-rg,
```

**CSV Requirements:**

- Header row is required and must match exactly
- Multiple VM names should be comma-separated within a quoted field (for example: `"vm01,vm02,vm03"`)
- Leave vm_names empty for auto-discovery of all VMs in the resource group
- SSH keys can be file paths or direct key content
- Direct key content should be quoted to handle spaces

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

# CSV file mode for batch operations
./interactive_vm_ssh_onboarding.sh -f <csv_file> [OPTIONS]
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-u, --username <username>` | ✅* | Username for identification |
| `-s, --subscription <subscription_id>` | ✅* | Azure subscription ID |
| `-k, --key <ssh_public_key>` | ✅* | SSH public key to remove (file path or key content) |
| `-g, --resource-group <vm_resource_group>` | ✅* | Resource group containing VMs |
| `-v, --vm <vm_name>` | ❌* | VM name (can be specified multiple times, or omit for auto-discovery) |
| `-f, --file <csv_file>` | ✅** | CSV file for batch operations |
| `-n, --no-backup` | ❌ | No backup (skip backup of authorized_keys) |
| `-d, --dry-run` | ❌ | Dry run mode (show what would be done) |
| `-h, --help` | ❌ | Display help message |

*Required for command line mode (except `-v` which enables auto-discovery when omitted)  
**Required for CSV file mode (replaces command line parameters)

### Usage Examples

#### Remove specific SSH key from a single VM

```bash
./interactive_vm_ssh_offboarding.sh \
  -u john.doe \
  -s "12345678-1234-1234-1234-123456789012" \
  -k ~/.ssh/id_rsa.pub \
  -g "production-vms-rg" \
  -v "web-server-01"
```

#### Remove specific key from multiple VMs

```bash
./interactive_vm_ssh_offboarding.sh \
  -u jane.smith \
  -s "12345678-1234-1234-1234-123456789012" \
  -k ~/.ssh/jane_key.pub \
  -g "production-vms-rg" \
  -v "web-server-01" -v "web-server-02" -v "db-server-01"
```

#### Remove specific key from all VMs in resource group (auto-discovery)

```bash
./interactive_vm_ssh_offboarding.sh \
  -u jane.smith \
  -s "87654321-4321-4321-4321-210987654321" \
  -k ~/.ssh/jane_key.pub \
  -g "production-rg"
  # No -v parameter = discovers all VMs automatically
```

#### Remove specific key without backup

```bash
./interactive_vm_ssh_offboarding.sh \
  -u john.doe \
  -s "12345678-1234-1234-1234-123456789012" \
  -k ~/.ssh/id_rsa.pub \
  -g "production-vms-rg" \
  -v "web-server-01" \
  -n
```

#### Dry run to preview changes

```bash
./interactive_vm_ssh_offboarding.sh \
  -u john.doe \
  -s "12345678-1234-1234-1234-123456789012" \
  -k ~/.ssh/id_rsa.pub \
  -g "production-vms-rg" \
  -v "web-server-01" \
  -d
```

#### Batch processing with CSV file

```bash
./interactive_vm_ssh_offboarding.sh -f offboarding_batch.csv
```

#### CSV file with dry run

```bash
./interactive_vm_ssh_offboarding.sh -f offboarding_batch.csv -d
```

*Note: Dry run mode bypasses confirmation prompts and shows what changes would be made*

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

### Interactive Mode Process (Recommended)

**🎮 User-Driven Workflow:**
1. **Script Launch** - Simply run without parameters for guided experience
2. **Azure Discovery** - Automatic detection of subscriptions and Azure resources
3. **Interactive Selection** - User-friendly menus for subscription, resource group, and VM selection
4. **Smart Configuration** - Flexible SSH key input with validation and auto-detection
5. **Operation Preview** - Clear summary of planned actions with user confirmation
6. **Execution with Feedback** - Real-time progress tracking and visual status updates
7. **Result Summary** - Detailed report of successful/failed operations

**Key Interactive Features:**
- **Auto-Discovery**: Finds and lists your Azure resources automatically
- **Smart Filtering**: Shows only relevant options (running VMs, resource groups with VMs)
- **Multi-Select Support**: Handle multiple VMs with simple y/n/a prompts
- **Input Validation**: Real-time checking of SSH keys and Azure resources
- **Visual Feedback**: Color-coded progress indicators and status updates

### Command Line Mode Process (Advanced)

**⚙️ Automated Workflow:**

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

### 🎯 **Interactive Mode Features** (Primary Strength)

**✨ Zero-Configuration Setup**
- No command-line parameters required - just run the script
- Automatically detects and lists your Azure subscriptions
- Smart filtering shows only relevant resources (resource groups with VMs)
- Auto-discovery of SSH keys in common locations (`~/.ssh/`)

**🧠 Intelligent User Guidance**
- **Context-Aware Prompts**: Only shows options relevant to your environment
- **Multi-Select Support**: Handle multiple VMs with simple `y/n/a` (yes/no/all) selections
- **Visual Status Indicators**: See VM power state, size, and availability at a glance
- **Smart Defaults**: Common choices pre-selected to speed up workflow

**🎮 User Experience Excellence**
- **Guided Workflows**: Step-by-step process eliminates guesswork
- **Error Prevention**: Validates inputs before execution
- **Operation Preview**: Shows exactly what will be done before making changes
- **Flexible Input Methods**: Support for file paths, direct paste, or auto-detection
- **Progressive Disclosure**: Advanced options available when needed

**📊 Real-Time Feedback**
- **Live Progress Tracking**: Visual progress bars for multi-VM operations
- **Instant Validation**: SSH key format and Azure resource validation
- **Status Updates**: Real-time success/failure indicators during processing
- **Operation Summaries**: Clear reports of what was accomplished

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
