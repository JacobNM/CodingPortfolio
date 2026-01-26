# Azure VM SSH Key Onboarding Script - CSV Import Feature

This script now supports importing parameters from a CSV file for batch processing of SSH key onboarding operations.

## Usage Modes

### 1. Command Line Mode (Original)
```bash
./azure_vm_ssh_onboarding.sh -u john.doe -s "12345678-1234-1234-1234-123456789012" \
    -k ~/.ssh/id_rsa.pub -g "myvm-rg" -v "myvm01" -v "myvm02"
```

### 2. CSV File Mode (New)
```bash
./azure_vm_ssh_onboarding.sh -f sample_onboarding.csv
```

## CSV File Format

The CSV file must have the following columns in this exact order:

| Column | Description | Required | Example |
|--------|-------------|----------|---------|
| username | User identifier | Yes | john.doe |
| subscription_id | Azure subscription ID | Yes | 12345678-1234-1234-1234-123456789012 |
| ssh_public_key | SSH key file path or key content | Yes | ~/.ssh/id_rsa.pub |
| vm_resource_group | Resource group containing VMs | Yes | prod-vm-rg |
| vm_names | VM names (comma-separated for multiple) | Yes | "vm01,vm02" |
| dry_run | Dry run mode (true/false) | Yes | false |

### CSV Format Notes:
- Use quotes around values containing commas (e.g., VM names: "vm01,vm02")
- SSH public key can be either a file path or the actual key content
- dry_run values: "true", "false", "True", "False" (case insensitive)
- Empty rows are automatically skipped
- First row must be the header

### Example CSV Content:
```csv
username,subscription_id,ssh_public_key,vm_resource_group,vm_names,dry_run
john.doe,12345678-1234-1234-1234-123456789012,~/.ssh/id_rsa.pub,prod-vm-rg,"vm01,vm02",false
jane.smith,87654321-4321-4321-4321-210987654321,~/.ssh/jane_key.pub,test-vm-rg,vm03,true
mike.wilson,11111111-2222-3333-4444-555555555555,"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQ...",dev-vm-rg,"vm04,vm05,vm06",false
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
- Format: `ssh_onboarding_YYYYMMDD_HHMMSS.log`
- Contains all operations, validations, and error details
- Useful for troubleshooting and audit purposes