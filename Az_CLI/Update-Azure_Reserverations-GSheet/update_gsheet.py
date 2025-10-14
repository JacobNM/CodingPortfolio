#!/usr/bin/env python3
"""
Google Sheets Updater for Azure VM and VMSS Inventory
This script updates a Google Sheet with Azure VM and VMSS data including autoscaling configurations.
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
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
except ImportError as e:
    print(f"Error: Required Google API libraries not installed. Run: pip install -r requirements.txt")
    print(f"Missing: {e}")
    sys.exit(1)

# Google Sheets API scope
SCOPES = ['https://www.googleapis.com/auth/spreadsheets']

class GoogleSheetsUpdater:
    def __init__(self, credentials_file: str = 'credentials.json', token_file: str = 'token.json'):
        """Initialize the Google Sheets updater."""
        self.credentials_file = credentials_file
        self.token_file = token_file
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
        """Authenticate with Google Sheets API."""
        creds = None
        
        # Load existing token
        if os.path.exists(self.token_file):
            try:
                creds = Credentials.from_authorized_user_file(self.token_file, SCOPES)
            except Exception as e:
                self.logger.warning(f"Error loading existing token: {e}")
        
        # Refresh or get new credentials
        if not creds or not creds.valid:
            if creds and creds.expired and creds.refresh_token:
                try:
                    creds.refresh(Request())
                    self.logger.info("Token refreshed successfully")
                except Exception as e:
                    self.logger.error(f"Error refreshing token: {e}")
                    creds = None
            
            if not creds:
                if not os.path.exists(self.credentials_file):
                    self.logger.error(f"Credentials file '{self.credentials_file}' not found.")
                    self.logger.info("Please download credentials.json from Google Cloud Console:")
                    self.logger.info("1. Go to https://console.cloud.google.com/")
                    self.logger.info("2. Enable Google Sheets API")
                    self.logger.info("3. Create credentials (Desktop Application)")
                    self.logger.info("4. Download and save as 'credentials.json'")
                    return False
                
                try:
                    flow = InstalledAppFlow.from_client_secrets_file(self.credentials_file, SCOPES)
                    creds = flow.run_local_server(port=0)
                    self.logger.info("New authentication completed")
                except Exception as e:
                    self.logger.error(f"Authentication failed: {e}")
                    return False
            
            # Save credentials for next run
            try:
                with open(self.token_file, 'w') as token:
                    token.write(creds.to_json())
                self.logger.info(f"Token saved to {self.token_file}")
            except Exception as e:
                self.logger.warning(f"Could not save token: {e}")
        
        try:
            self.service = build('sheets', 'v4', credentials=creds)
            self.logger.info("Google Sheets API service initialized successfully")
            return True
        except Exception as e:
            self.logger.error(f"Failed to initialize Google Sheets service: {e}")
            return False
    
    def get_sheet_info(self, spreadsheet_id: str) -> Dict[str, Any]:
        """Get information about the spreadsheet."""
        try:
            sheet_metadata = self.service.spreadsheets().get(spreadsheetId=spreadsheet_id).execute()
            return sheet_metadata
        except Exception as e:
            self.logger.error(f"Error getting sheet info: {e}")
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
            # Get sheet info to verify sheet exists
            sheet_metadata = self.get_sheet_info(spreadsheet_id)
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
        description='Update Google Sheets with Azure VM and VMSS inventory data'
    )
    parser.add_argument('csv_file', help='Path to CSV file with inventory data')
    parser.add_argument('spreadsheet_id', help='Google Sheets spreadsheet ID')
    parser.add_argument('--sheet-name', '-s', default='Azure Inventory', 
                       help='Name of the sheet to update (default: Azure Inventory)')
    parser.add_argument('--start-cell', '-c', default='A1', 
                       help='Starting cell for data (default: A1)')
    parser.add_argument('--no-clear', action='store_true', 
                       help='Don\'t clear existing data before updating')
    parser.add_argument('--credentials', default='credentials.json',
                       help='Path to Google API credentials file (default: credentials.json)')
    parser.add_argument('--token', default='token.json',
                       help='Path to token file (default: token.json)')
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
    updater = GoogleSheetsUpdater(
        credentials_file=args.credentials,
        token_file=args.token
    )
    
    # Authenticate
    if not updater.authenticate():
        print("Authentication failed. Exiting.")
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
