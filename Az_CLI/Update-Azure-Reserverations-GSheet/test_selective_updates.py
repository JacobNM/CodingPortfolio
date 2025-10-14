#!/usr/bin/env python3
"""
Test script for selective Google Sheets updates
This script helps test the selective update functionality with sample data.
"""

import csv
import os
import tempfile

def create_test_scenarios():
    """Create test CSV files for different update scenarios."""
    
    # Scenario 1: Updates to existing resources
    scenario1_data = [
        ['ResourceType', 'Name', 'ResourceGroup', 'Subscription', 'Location', 'SKU', 'Capacity', 'PowerState', 'OsType', 'AutoscaleEnabled', 'AutoscaleMinCapacity', 'AutoscaleMaxCapacity', 'AutoscaleDefaultCapacity'],
        ['VM', 'web-server-01', 'rg-production', 'subscription-prod', 'East US', 'Standard_D4s_v3', '', 'Running', 'Linux', 'N/A', 'N/A', 'N/A', 'N/A'],  # Changed SKU from D2s to D4s
        ['VMSS', 'api-scaleset', 'rg-production', 'subscription-prod', 'East US', 'Standard_D2s_v3', '5', 'Running', 'Linux', 'true', '3', '15', '5'],  # Changed min from 2->3, max from 10->15
        ['VM', 'db-server-02', 'rg-production', 'subscription-prod', 'West US', 'Standard_E8s_v3', '', 'Running', 'Windows', 'N/A', 'N/A', 'N/A', 'N/A']  # New resource
    ]
    
    # Write scenario 1 to temp file
    with tempfile.NamedTemporaryFile(mode='w', suffix='_test_updates.csv', delete=False, encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerows(scenario1_data)
        scenario1_file = f.name
    
    # Scenario 2: Only new resources
    scenario2_data = [
        ['ResourceType', 'Name', 'ResourceGroup', 'Subscription', 'Location', 'SKU', 'Capacity', 'PowerState', 'OsType', 'AutoscaleEnabled', 'AutoscaleMinCapacity', 'AutoscaleMaxCapacity', 'AutoscaleDefaultCapacity'],
        ['VMSS', 'new-web-scaleset', 'rg-staging', 'subscription-dev', 'Central US', 'Standard_B2s', '2', 'Running', 'Linux', 'true', '1', '8', '2'],
        ['VM', 'test-vm-03', 'rg-testing', 'subscription-test', 'East US 2', 'Standard_D2s_v3', '', 'Running', 'Ubuntu', 'N/A', 'N/A', 'N/A', 'N/A']
    ]
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='_test_new_resources.csv', delete=False, encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerows(scenario2_data)
        scenario2_file = f.name
    
    return scenario1_file, scenario2_file

def run_test_scenarios(spreadsheet_id: str, sheet_name: str = "Sheet1"):
    """Run test scenarios against the Google Sheet."""
    
    print("🧪 Creating test scenarios...")
    scenario1_file, scenario2_file = create_test_scenarios()
    
    print(f"📁 Test files created:")
    print(f"  Scenario 1 (Updates): {scenario1_file}")
    print(f"  Scenario 2 (New Resources): {scenario2_file}")
    
    try:
        from update_gsheet_service_account import GoogleSheetsServiceAccountUpdater
        
        updater = GoogleSheetsServiceAccountUpdater()
        
        if not updater.authenticate():
            print("❌ Authentication failed")
            return False
        
        print("\n🔄 Running Scenario 1: Testing updates to existing resources...")
        success1 = updater.update_sheet_selective(
            spreadsheet_id=spreadsheet_id,
            sheet_name=sheet_name,
            csv_file=scenario1_file
        )
        
        if success1:
            print("✅ Scenario 1 completed successfully!")
        else:
            print("❌ Scenario 1 failed")
            return False
        
        input("\n⏸️  Press Enter after reviewing the changes in your Google Sheet to continue with Scenario 2...")
        
        print("\n🔄 Running Scenario 2: Testing new resource additions...")
        success2 = updater.update_sheet_selective(
            spreadsheet_id=spreadsheet_id,
            sheet_name=sheet_name,
            csv_file=scenario2_file
        )
        
        if success2:
            print("✅ Scenario 2 completed successfully!")
            print(f"🎉 All tests completed! Check your Google Sheet: https://docs.google.com/spreadsheets/d/{spreadsheet_id}")
            return True
        else:
            print("❌ Scenario 2 failed")
            return False
            
    except ImportError:
        print("❌ Could not import update_gsheet_service_account.py")
        return False
    except Exception as e:
        print(f"❌ Test failed with error: {e}")
        return False
    
    finally:
        # Clean up temp files
        try:
            os.unlink(scenario1_file)
            os.unlink(scenario2_file)
            print("🧹 Cleaned up test files")
        except:
            pass

def main():
    import sys
    
    print("🔧 Google Sheets Selective Update Test")
    print("=" * 50)
    
    if len(sys.argv) < 2:
        print("Usage: python3 test_selective_updates.py <SPREADSHEET_ID> [SHEET_NAME]")
        print("\nThis script tests the selective update functionality by:")
        print("1. Creating test CSV data with updates and new resources")
        print("2. Running selective updates against your Google Sheet")
        print("3. Logging all changes made")
        print("\nMake sure you have a backup of your Google Sheet before running!")
        sys.exit(1)
    
    spreadsheet_id = sys.argv[1]
    sheet_name = sys.argv[2] if len(sys.argv) > 2 else "Sheet1"
    
    print(f"📊 Target Sheet: {spreadsheet_id}")
    print(f"📋 Sheet Name: {sheet_name}")
    
    confirm = input("\n⚠️  This will modify your Google Sheet. Continue? (y/N): ")
    if confirm.lower() != 'y':
        print("Test cancelled.")
        sys.exit(0)
    
    success = run_test_scenarios(spreadsheet_id, sheet_name)
    
    if success:
        print("\n✅ All tests passed!")
        sys.exit(0)
    else:
        print("\n❌ Tests failed!")
        sys.exit(1)

if __name__ == '__main__':
    main()