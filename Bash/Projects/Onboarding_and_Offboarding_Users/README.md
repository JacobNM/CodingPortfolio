# Azure User Onboarding and Offboarding Scripts

This repository contains two comprehensive Bash scripts for automating Azure user lifecycle management:

- **`azure_user_onboarding.sh`** - Automates the process of onboarding new users to Azure resources
- **`azure_user_offboarding.sh`** - Automates the process of offboarding users from Azure resources

## Prerequisites

1. **Azure CLI** - Both scripts require the Azure CLI to be installed
   ```bash
   # Install Azure CLI (macOS)
   brew install azure-cli
   
   # Login to Azure
   az login
   ```

2. **Required Permissions** - Your account needs the following roles:
   - **User Access Administrator** - For managing RBAC role assignments
   - **Privileged Role Administrator** - For managing Azure AD users and groups

3. **Additional Tools** (for certain features):
   - `jq` - For JSON processing (used in offboarding script)
   - `openssl` - For password generation (used in onboarding script)

## Onboarding Script (`azure_user_onboarding.sh`)

### Features
- Creates new Azure AD users (if they don't exist)
- Adds users to specified Azure AD groups
- Assigns RBAC roles at subscription or resource group level
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

#### Dry Run (Preview Changes)
```bash
./azure_user_onboarding.sh \
  -u test.user@company.com \
  -d "Test User" \
  -s "12345678-1234-1234-1234-123456789012" \
  -n
```

### Parameters

| Parameter | Description | Required |
|-----------|-------------|----------|
| `-u, --user-principal` | User Principal Name (email address) | Yes |
| `-d, --display-name` | Display name for the user | Yes |
| `-s, --subscription` | Azure subscription ID | Yes |
| `-r, --resource-group` | Specific resource group to grant access to | No |
| `-g, --azure-groups` | Comma-separated list of Azure AD groups | No |
| `-R, --rbac-roles` | Comma-separated list of RBAC roles to assign | No |
| `-n, --dry-run` | Preview changes without executing them | No |
| `-e, --send-email` | Send welcome email with access details | No |
| `-h, --help` | Display help message | No |

## Offboarding Script (`azure_user_offboarding.sh`)

### Features
- Disables Azure AD user accounts
- Removes users from all Azure AD groups
- Revokes all RBAC role assignments
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

#### Automated Offboarding (No Prompts)
```bash
./azure_user_offboarding.sh \
  -u automated.user@company.com \
  -s "12345678-1234-1234-1234-123456789012" \
  -f
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
| `--no-remove-groups` | Skip removing user from Azure AD groups | No |
| `--no-revoke-roles` | Skip revoking RBAC role assignments | No |
| `--no-backup` | Skip creating backup of user's access | No |
| `-f, --force` | Force execution without confirmation prompts | No |
| `-n, --dry-run` | Preview changes without executing them | No |
| `-h, --help` | Display help message | No |

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
   - Verify your account has the required Azure AD and RBAC roles
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