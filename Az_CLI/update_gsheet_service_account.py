#!/usr/bin/env python3
"""
Google Sheets Updater using Service Account Authentication
This script updates a Google Sheet with Azure VM and VMSS data using service account credentials.
No interactive OAuth flow required - just download service account key and share the sheet.
"""

import os
import sys
import csv
import argparse
from typing import List, Dict, Any
import json
import logging

try:
    from googleapiclient.discovery import build
    from google.oauth2 import service_account
except ImportError as e:
    print(f"Error: Required Google API libraries not installed. Run: pip install -r requirements.txt")
    print(f"Missing: {e}")
    sys.exit(1)

# Google Sheets API scope
SCOPES = ['https://www.googleapis.com/auth/spreadsheets']
SERVICE_ACCOUNT_FILE = 'service-account-key.json'

class GoogleSheetsServiceAccountUpdater:
    def __init__(self, service_account_file: str = SERVICE_ACCOUNT_FILE):
        """Initialize the Google Sheets updater with service account."""
        self.service_account_file = service_account_file
        self.service = None
        self.logger = self._setup_logging()
    
    def _setup_logging(self) -> logging.Logger:
        """Set up logging configuration."""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[logging.StreamHandler()]
        )
        return logging.getLogger(__name__)
    
    def authenticate(self) -> bool:
        """Authenticate with Google Sheets API using service account."""
        if not os.path.exists(self.service_account_file):
            self.logger.error(f"Service account file '{self.service_account_file}' not found.")
            self.logger.info("Please follow the service account setup guide:")
            self.logger.info("1. Go to Google Cloud Console")
            self.logger.info("2. Create a service account")
            self.logger.info("3. Download the JSON key file")
            self.logger.info("4. Save as 'service-account-key.json' in this directory")
            self.logger.info("5. Share your Google Sheet with the service account email")
            return False
        
        try:
            # Load service account credentials
            credentials = service_account.Credentials.from_service_account_file(
                self.service_account_file, scopes=SCOPES)
            
            # Build the service
            self.service = build('sheets', 'v4', credentials=credentials)
            
            # Get service account email for user reference
            with open(self.service_account_file, 'r') as f:
                service_info = json.load(f)
                service_email = service_info.get('client_email', 'unknown')
            
            self.logger.info(f"Google Sheets API service initialized successfully")
            self.logger.info(f"Service account: {service_email}")
            return True
            
        except Exception as e:
            self.logger.error(f"Authentication failed: {e}")
            return False
    
    def get_sheet_info(self, spreadsheet_id: str) -> Dict[str, Any]:
        """Get information about the spreadsheet."""
        try:
            sheet_metadata = self.service.spreadsheets().get(spreadsheetId=spreadsheet_id).execute()
            return sheet_metadata
        except Exception as e:
            self.logger.error(f"Error getting sheet info: {e}")
            if "does not have permission" in str(e) or "not found" in str(e):
                self.logger.error("Make sure you've shared the Google Sheet with the service account email!")
            return {}
    
    def read_csv_data(self, csv_file: str) -> List[List[str]]:
        """Read data from CSV file."""
        data = []
        try:
            with open(csv_file, 'r', encoding='utf-8') as file:
                csv_reader = csv.reader(file)
                for row in csv_reader:
                    data.append(row)
            self.logger.info(f"Read {len(data)} rows from {csv_file}")
            return data
        except Exception as e:
            self.logger.error(f"Error reading CSV file: {e}")
            return []
    
    def update_sheet(self, spreadsheet_id: str, sheet_name: str, csv_file: str, 
                    start_cell: str = 'A1', clear_existing: bool = True) -> bool:
        """Update Google Sheet with data from CSV file."""
        
        if not self.service:
            self.logger.error("Google Sheets service not initialized. Call authenticate() first.")
            return False
        
        # Read CSV data
        data = self.read_csv_data(csv_file)
        if not data:
            self.logger.error("No data to update")
            return False
        
        try:
            # Get sheet info to verify sheet exists and access
            sheet_metadata = self.get_sheet_info(spreadsheet_id)
            if not sheet_metadata:
                return False
                
            sheet_names = [sheet['properties']['title'] for sheet in sheet_metadata.get('sheets', [])]
            
            if sheet_name not in sheet_names:
                self.logger.error(f"Sheet '{sheet_name}' not found. Available sheets: {sheet_names}")
                return False
            
            # Clear existing data if requested
            if clear_existing:
                self.logger.info(f"Clearing existing data in sheet '{sheet_name}'")
                clear_range = f"{sheet_name}!A:Z"  # Clear columns A through Z
                self.service.spreadsheets().values().clear(
                    spreadsheetId=spreadsheet_id,
                    range=clear_range
                ).execute()
            
            # Update with new data
            range_name = f"{sheet_name}!{start_cell}"
            body = {
                'values': data
            }
            
            result = self.service.spreadsheets().values().update(
                spreadsheetId=spreadsheet_id,
                range=range_name,
                valueInputOption='RAW',
                body=body
            ).execute()
            
            updated_cells = result.get('updatedCells', 0)
            self.logger.info(f"Successfully updated {updated_cells} cells in '{sheet_name}'")
            return True
            
        except Exception as e:
            self.logger.error(f"Error updating sheet: {e}")
            if "does not have permission" in str(e):
                self.logger.error("Permission denied. Please check:")
                self.logger.error("1. Is the Google Sheet shared with the service account?")
                self.logger.error("2. Does the service account have 'Editor' permissions?")
            return False
    
    def create_summary_stats(self, csv_file: str) -> Dict[str, int]:
        """Create summary statistics from CSV data."""
        stats = {
            'total_resources': 0,
            'vms': 0,
            'vmss': 0,
            'autoscale_enabled': 0,
            'subscriptions': set()
        }
        
        try:
            with open(csv_file, 'r', encoding='utf-8') as file:
                csv_reader = csv.DictReader(file)
                for row in csv_reader:
                    stats['total_resources'] += 1
                    
                    if row.get('ResourceType') == 'VM':
                        stats['vms'] += 1
                    elif row.get('ResourceType') == 'VMSS':
                        stats['vmss'] += 1
                        if row.get('AutoscaleEnabled', '').lower() == 'true':
                            stats['autoscale_enabled'] += 1
                    
                    if row.get('Subscription'):
                        stats['subscriptions'].add(row['Subscription'])
            
            stats['subscriptions'] = len(stats['subscriptions'])
            
        except Exception as e:
            self.logger.error(f"Error creating summary stats: {e}")
        
        return stats

def main():
    parser = argparse.ArgumentParser(
        description='Update Google Sheets with Azure VM and VMSS inventory data (Service Account)'
    )
    parser.add_argument('csv_file', help='Path to CSV file with inventory data')
    parser.add_argument('spreadsheet_id', help='Google Sheets spreadsheet ID')
    parser.add_argument('--sheet-name', '-s', default='Azure Inventory', 
                       help='Name of the sheet to update (default: Azure Inventory)')
    parser.add_argument('--start-cell', '-c', default='A1', 
                       help='Starting cell for data (default: A1)')
    parser.add_argument('--no-clear', action='store_true', 
                       help='Don\'t clear existing data before updating')
    parser.add_argument('--service-account', default=SERVICE_ACCOUNT_FILE,
                       help=f'Path to service account JSON file (default: {SERVICE_ACCOUNT_FILE})')
    parser.add_argument('--verbose', '-v', action='store_true', 
                       help='Enable verbose logging')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Verify CSV file exists
    if not os.path.exists(args.csv_file):
        print(f"Error: CSV file '{args.csv_file}' not found.")
        sys.exit(1)
    
    # Initialize updater
    updater = GoogleSheetsServiceAccountUpdater(
        service_account_file=args.service_account
    )
    
    # Authenticate
    if not updater.authenticate():
        print("Authentication failed. Please check service account setup.")
        sys.exit(1)
    
    # Update sheet
    success = updater.update_sheet(
        spreadsheet_id=args.spreadsheet_id,
        sheet_name=args.sheet_name,
        csv_file=args.csv_file,
        start_cell=args.start_cell,
        clear_existing=not args.no_clear
    )
    
    if success:
        # Show summary statistics
        stats = updater.create_summary_stats(args.csv_file)
        print("\n=== Update Summary ===")
        print(f"Total Resources: {stats['total_resources']}")
        print(f"VMs: {stats['vms']}")
        print(f"VMSS: {stats['vmss']}")
        print(f"VMSS with Autoscale: {stats['autoscale_enabled']}")
        print(f"Subscriptions: {stats['subscriptions']}")
        print(f"Google Sheet updated successfully!")
        
        # Extract spreadsheet ID for URL
        sheet_url = f"https://docs.google.com/spreadsheets/d/{args.spreadsheet_id}"
        print(f"View at: {sheet_url}")
        
        sys.exit(0)
    else:
        print("Failed to update Google Sheet.")
        sys.exit(1)

if __name__ == '__main__':
    main()
