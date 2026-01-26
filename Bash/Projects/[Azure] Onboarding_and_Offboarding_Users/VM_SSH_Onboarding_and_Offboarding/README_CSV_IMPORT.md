# Azure VM SSH Key Management Scripts - CSV Import Feature

Both the onboarding and offboarding scripts now support importing parameters from CSV files for batch processing operations.

## Scripts with CSV Support

### 🔑 SSH Onboarding Script (`azure_vm_ssh_onboarding.sh`)
Adds SSH public keys to the `azroot` account on specified Azure VMs.

### 🗑️ SSH Offboarding Script (`azure_vm_ssh_offboarding.sh`)  
Removes SSH public keys from the `azroot` account on specified Azure VMs.

## Usage Modes

### 1. Command Line Mode (Original)
```bash
# Onboarding
./azure_vm_ssh_onboarding.sh -u john.doe -s "12345..." -k ~/.ssh/id_rsa.pub -g "myvm-rg" -v "myvm01"

# Offboarding  
./azure_vm_ssh_offboarding.sh -u john.doe -s "12345..." -k ~/.ssh/id_rsa.pub -g "myvm-rg" -v "myvm01"
```

### 2. CSV File Mode (New)
```bash
# Onboarding
./azure_vm_ssh_onboarding.sh --file sample_onboarding.csv

# Offboarding
./azure_vm_ssh_offboarding.sh --file sample_offboarding.csv

# Both support dry run mode via command line flag
./azure_vm_ssh_onboarding.sh --file sample_onboarding.csv --dry-run
./azure_vm_ssh_offboarding.sh --file sample_offboarding.csv --dry-run
```

## CSV File Formats

### SSH Onboarding CSV Format

The CSV file must have the following columns in this exact order:

| Column | Description | Required | Example |
|--------|-------------|----------|---------|
| username | User identifier | Yes | john.doe |
| subscription_id | Azure subscription ID | Yes | 12345678-1234-1234-1234-123456789012 |
| ssh_public_key | SSH key file path or key content | Yes | ~/.ssh/id_rsa.pub |
| vm_resource_group | Resource group containing VMs | Yes | prod-vm-rg |
| vm_names | VM names (comma-separated for multiple) | Yes | "vm01,vm02" |

### SSH Offboarding CSV Format

The CSV file must have the following columns in this exact order:

| Column | Description | Required | Example |
|--------|-------------|----------|---------|
| username | User identifier | Yes | john.doe |
| subscription_id | Azure subscription ID | Yes | 12345678-1234-1234-1234-123456789012 |
| ssh_public_key | SSH key file path or key content | No* | ~/.ssh/id_rsa.pub |
| vm_resource_group | Resource group containing VMs | Yes | prod-vm-rg |
| vm_names | VM names (comma-separated for multiple) | Yes | "vm01,vm02" |
| remove_all_keys | Remove all SSH keys (true/false) | Yes | false |
| backup_keys | Backup authorized_keys before changes (true/false) | Yes | true |

*SSH public key is required unless `remove_all_keys` is `true`

### CSV Format Notes:
- Use quotes around values containing commas (e.g., VM names: "vm01,vm02")
- SSH public key can be either a file path or the actual key content
- Boolean values: "true", "false", "True", "False" (case insensitive)
- Empty rows are automatically skipped
- First row must be the header
- For offboarding: SSH key can be empty if `remove_all_keys` is `true`
- **Dry run mode**: Controlled by command line flag (`--dry-run` or `-d`), not CSV content

### Example CSV Content:

**Onboarding CSV (sample_onboarding.csv):**
```csv
username,subscription_id,ssh_public_key,vm_resource_group,vm_names
john.doe,12345678-1234-1234-1234-123456789012,~/.ssh/id_rsa.pub,prod-rg,"vm01,vm02"
jane.smith,87654321-4321-4321-4321-210987654321,~/.ssh/jane_key.pub,test-rg,vm03
mike.wilson,11111111-2222-3333-4444-555555555555,"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQ...",dev-rg,"vm04,vm05,vm06"
```

**Offboarding CSV (sample_offboarding.csv):**
```csv
username,subscription_id,ssh_public_key,vm_resource_group,vm_names,remove_all_keys,backup_keys
john.doe,12345678-1234-1234-1234-123456789012,~/.ssh/id_rsa.pub,prod-rg,"vm01,vm02",false,true
jane.smith,87654321-4321-4321-4321-210987654321,,test-rg,vm03,true,false
mike.wilson,11111111-2222-3333-4444-555555555555,"ssh-rsa AAAAB3Nz...",dev-rg,"vm04,vm05",false,true
```

## Benefits of CSV Mode

1. **Batch Processing**: Handle multiple users, subscriptions, and VMs in one operation
2. **Easy Management**: Keep all onboarding parameters in a structured file
3. **Version Control**: Track changes to onboarding configurations
4. **Reusability**: Rerun the same set of operations easily
5. **Error Handling**: Individual row failures don't stop processing of other rows

## Features

- **Individual Row Processing**: Each CSV row is processed independently
- **Comprehensive Validation**: Each row is validated before processing
- **Detailed Logging**: All operations are logged with timestamps
- **Error Recovery**: Failed rows are reported but don't stop processing
- **Progress Reporting**: Clear progress indicators for each operation
- **Summary Report**: Final summary showing success/failure counts

## Error Handling

- Invalid CSV format or missing files are caught early
- Each row is validated before processing
- SSH key validation occurs per row
- VM permissions are checked per subscription/resource group
- Detailed error messages help identify issues
- Processing continues even if individual rows fail

## Log Files

Log files are automatically generated with timestamps:
- Onboarding: `ssh_onboarding_YYYYMMDD_HHMMSS.log`
- Offboarding: `ssh_offboarding_YYYYMMDD_HHMMSS.log`
- Contains all operations, validations, and error details
- Useful for troubleshooting and audit purposes

## Key Differences Between Onboarding and Offboarding

### Onboarding CSV Features:
- Simpler format with 6 columns
- Always requires SSH public key
- Focuses on adding access

### Offboarding CSV Features:
- Extended format with 8 columns
- Optional SSH public key (when removing all keys)
- `remove_all_keys` option for complete key removal
- `backup_keys` option for safety
- More granular control over removal operations

Both scripts share the same core benefits: batch processing, error recovery, detailed logging, and comprehensive validation.