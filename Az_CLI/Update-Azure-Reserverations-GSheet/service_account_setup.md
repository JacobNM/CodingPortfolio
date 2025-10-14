# Service Account Setup Guide (No OAuth Required)

## Why Service Accounts are Easier
- ✅ No browser authentication required
- ✅ No interactive OAuth flow
- ✅ Works in automated environments
- ✅ Just download one JSON file
- ✅ Share sheet with service account email - done!

## Quick Setup (5 minutes)

### 1. Create Service Account
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create new project or select existing one
3. Enable **Google Sheets API**:
   - Go to "APIs & Services" → "Library" 
   - Search "Google Sheets API" → Enable
4. Create Service Account:
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "Service Account"
   - Enter name (e.g., "azure-inventory-updater")
   - Click "Create and Continue" → "Done"

### 2. Download Key File
1. Click on your service account name
2. Go to "Keys" tab
3. Click "Add Key" → "Create New Key"
4. Choose "JSON" format
5. Download and save as `service-account-key.json` in your script directory

### 3. Share Google Sheet
1. Open your Google Sheet
2. Click "Share" button
3. Copy the service account email from the JSON file (looks like: `azure-inventory-updater@project-name.iam.gserviceaccount.com`)
4. Add this email with "Editor" permissions
5. Click "Send" (no notification needed)

### 4. Test It
```bash
# Generate CSV
./update_gsheet_azure_vm_vmss_inventory.sh -f test.csv --no-gsheet

# Test service account update
python3 update_gsheet_service_account.py test.csv "YOUR_SPREADSHEET_ID" -s "Test Sheet"
```

## File Structure After Setup
```
Az_CLI/
├── service-account-key.json          # ← Your downloaded key file
├── update_gsheet_service_account.py  # ← Service account updater
├── update_gsheet_azure_vm_vmss_inventory.sh
└── ... other files
```

## Usage
The main script will automatically detect and use the service account method:
```bash
# This will use service account if service-account-key.json exists
./update_gsheet_azure_vm_vmss_inventory.sh -g "YOUR_SPREADSHEET_ID"
```

## Security Notes
- The service account key file contains credentials - keep it secure
- Don't commit `service-account-key.json` to version control
- The service account only has access to sheets you explicitly share with it
- You can revoke access anytime by unsharing the sheet or deleting the key