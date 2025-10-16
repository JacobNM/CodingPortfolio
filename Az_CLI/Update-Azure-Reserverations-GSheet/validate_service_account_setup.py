#!/usr/bin/env python3
"""
Service Account Validation Script
This script validates your Google Sheets service account setup.
"""

import os
import json
import sys

def validate_service_account_file():
    """Validate the service account key file."""
    service_account_file = 'service-account-key.json'
    
    print("🔍 Validating service account setup...")
    print("=" * 50)
    
    # Check if file exists
    if not os.path.exists(service_account_file):
        print("❌ Service account file not found!")
        print(f"   Expected: {service_account_file}")
        print("   Please download the JSON key file from Google Cloud Console")
        print("   and save it as 'service-account-key.json' in this directory.")
        return False
    
    print("✅ Service account file found")
    
    # Validate JSON format
    try:
        with open(service_account_file, 'r') as f:
            service_data = json.load(f)
    except json.JSONDecodeError:
        print("❌ Invalid JSON format in service account file")
        return False
    except Exception as e:
        print(f"❌ Error reading service account file: {e}")
        return False
    
    print("✅ Service account file is valid JSON")
    
    # Check required fields
    required_fields = ['type', 'project_id', 'private_key_id', 'private_key', 'client_email', 'client_id']
    missing_fields = [field for field in required_fields if field not in service_data]
    
    if missing_fields:
        print(f"❌ Missing required fields: {', '.join(missing_fields)}")
        return False
    
    print("✅ All required fields present")
    
    # Validate service account type
    if service_data.get('type') != 'service_account':
        print(f"❌ Invalid type: {service_data.get('type')} (expected: service_account)")
        return False
    
    print("✅ Correct service account type")
    
    # Display service account info
    print("\n📋 Service Account Information:")
    print(f"   Email: {service_data.get('client_email')}")
    print(f"   Project: {service_data.get('project_id')}")
    print(f"   Key ID: {service_data.get('private_key_id', 'Unknown')}")
    
    print("\n🎯 Next Steps:")
    print("1. Copy this email:", service_data.get('client_email'))
    print("2. Share your Google Sheet with this email (Editor permissions)")
    print("3. Run the inventory script with your spreadsheet ID")
    
    return True

def test_google_api_import():
    """Test if Google API libraries are installed."""
    print("\n🔍 Testing Google API libraries...")
    print("=" * 50)
    
    try:
        from googleapiclient.discovery import build
        from google.oauth2 import service_account
        print("✅ Google API libraries installed correctly")
        return True
    except ImportError as e:
        print("❌ Google API libraries not installed")
        print(f"   Error: {e}")
        print("   Run: pip3 install -r requirements.txt")
        return False

def main():
    print("🚀 Azure VM/VMSS Inventory - Service Account Validator")
    print("=" * 60)
    
    # Test API libraries
    api_ok = test_google_api_import()
    
    # Test service account file
    sa_ok = validate_service_account_file()
    
    print("\n" + "=" * 60)
    if api_ok and sa_ok:
        print("🎉 VALIDATION SUCCESSFUL!")
        print("   Your service account setup is ready to use.")
        print("\n💡 Usage example:")
        print('   ./update_gsheet_azure_vm_vmss_inventory.sh -g "YOUR_SPREADSHEET_ID"')
    else:
        print("⚠️  VALIDATION FAILED!")
        print("   Please fix the issues above before proceeding.")
        sys.exit(1)

if __name__ == '__main__':
    main()