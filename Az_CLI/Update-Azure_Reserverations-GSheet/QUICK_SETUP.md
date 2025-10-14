# Quick Service Account Setup - 5 Minutes Total

## Step 1: Google Cloud Console (3 minutes)

1. **Go to [Google Cloud Console](https://console.cloud.google.com/)**

2. **Create/Select Project**:
   - Click project dropdown → "New Project"
   - Name: `azure-inventory` (or anything you like)
   - Click "Create"

3. **Enable Google Sheets API**:
   - Go to "APIs & Services" → "Library"
   - Search "Google Sheets API"
   - Click on it → Click "Enable"

4. **Create Service Account**:
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "Service Account"
   - Name: `azure-inventory-updater`
   - Click "Create and Continue" → Skip roles → Click "Done"

5. **Download Key**:
   - Click on your service account name
   - Go to "Keys" tab
   - Click "Add Key" → "Create New Key" → "JSON"
   - **Save the downloaded file as `service-account-key.json` in this directory**

## Step 2: Prepare Your Google Sheet (1 minute)

1. **Create or open your Google Sheet**
2. **Note the Spreadsheet ID** from URL:
   ```
   https://docs.google.com/spreadsheets/d/[SPREADSHEET_ID]/edit
                                        ^^^^^^^^^^^^
                                        Copy this part
   ```

## Step 3: Share Sheet with Service Account (1 minute)

1. **Open your downloaded `service-account-key.json`**
2. **Copy the `client_email` value** (looks like: `azure-inventory-updater@project-name.iam.gserviceaccount.com`)
3. **In your Google Sheet, click "Share"**
4. **Paste the service account email**
5. **Set permissions to "Editor"**
6. **Click "Send"** (no notification needed)

## Step 4: Test It! 

```bash
# Test the setup
./update_gsheet_with_azure_vm_vmss_inventory.sh -g "YOUR_SPREADSHEET_ID" -s "Azure Inventory"
```

That's it! The service account will now automatically authenticate without any browser popups.