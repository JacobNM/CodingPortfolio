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
    
    def update_sheet_selective(self, spreadsheet_id: str, sheet_name: str, csv_file: str) -> bool:
        """Selectively update Google Sheet with data from CSV file - only update specific columns where values differ."""
        
        if not self.service:
            self.logger.error("Google Sheets service not initialized. Call authenticate() first.")
            return False
        
        # Read CSV data
        csv_data = self.read_csv_data(csv_file)
        if not csv_data:
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
            
            # Read existing sheet data
            self.logger.info(f"Reading existing data from sheet '{sheet_name}'")
            range_name = f"{sheet_name}!A:Z"  # Read all columns
            sheet_result = self.service.spreadsheets().values().get(
                spreadsheetId=spreadsheet_id,
                range=range_name
            ).execute()
            
            existing_data = sheet_result.get('values', [])
            if not existing_data:
                self.logger.error("No existing data found in sheet")
                return False
            
            # Find column indices in both CSV and GSheet
            csv_header = csv_data[0] if csv_data else []
            gsheet_header = existing_data[0] if existing_data else []
            
            self.logger.info(f"CSV columns: {csv_header}")
            self.logger.info(f"GSheet columns: {gsheet_header}")
            
            # Map CSV columns to indices
            csv_indices = {
                'name': self._find_column_index(csv_header, ['Name']),
                'sku': self._find_column_index(csv_header, ['SKU']),
                'subscription': self._find_column_index(csv_header, ['Subscription']),
                'resource_group': self._find_column_index(csv_header, ['ResourceGroup']),
                'location': self._find_column_index(csv_header, ['Location']),
                'resource_type': self._find_column_index(csv_header, ['ResourceType']),
                'autoscale_min': self._find_column_index(csv_header, ['AutoscaleMinCapacity']),
                'autoscale_max': self._find_column_index(csv_header, ['AutoscaleMaxCapacity']),
                'autoscale_current': self._find_column_index(csv_header, ['AutoscaleDefaultCapacity'])
            }
            
            # Map GSheet columns to indices (case-insensitive search)
            gsheet_indices = {
                'group': self._find_column_index(gsheet_header, ['Group'], case_sensitive=False),
                'sku': self._find_column_index(gsheet_header, ['SKU'], case_sensitive=False),
                'subscription': self._find_column_index(gsheet_header, ['Subscription'], case_sensitive=False),
                'current': self._find_column_index(gsheet_header, ['current'], case_sensitive=False),
                'min': self._find_column_index(gsheet_header, ['min'], case_sensitive=False),
                'max': self._find_column_index(gsheet_header, ['max'], case_sensitive=False)
            }
            
            self.logger.info(f"CSV column mapping: {csv_indices}")
            self.logger.info(f"GSheet column mapping: {gsheet_indices}")
            
            # Validate that required columns exist
            if csv_indices['name'] is None:
                self.logger.error("CSV 'Name' column not found")
                return False
            if gsheet_indices['group'] is None:
                self.logger.error("GSheet 'Group' column not found")
                return False
            
            # Process updates
            changes_made = []
            new_resources = []
            
            # Skip CSV header row
            for csv_row_idx, csv_row in enumerate(csv_data[1:], start=2):
                if not csv_row or len(csv_row) <= csv_indices['name']:
                    continue
                
                resource_name = csv_row[csv_indices['name']].strip()
                if not resource_name:
                    continue
                
                self.logger.info(f"Processing CSV resource: {resource_name}")
                
                # Find matching row in GSheet (exact match only, case-insensitive)
                gsheet_row_idx = None
                for idx, gsheet_row in enumerate(existing_data[1:], start=2):  # Skip header
                    if len(gsheet_row) <= gsheet_indices['group']:
                        continue
                        
                    gsheet_group = gsheet_row[gsheet_indices['group']].strip()
                    if not gsheet_group:
                        continue
                    
                    # Only exact match (case-insensitive)
                    if gsheet_group.lower() == resource_name.lower():
                        gsheet_row_idx = idx
                        self.logger.info(f"Exact match found: '{resource_name}' = '{gsheet_group}'")
                        break
                
                if gsheet_row_idx is not None:
                    # Resource found - check for updates
                    gsheet_row = existing_data[gsheet_row_idx - 1]  # Adjust for 0-based indexing
                    updates_needed = []
                    
                    # Check SKU
                    if (csv_indices['sku'] is not None and 
                        gsheet_indices['sku'] is not None and 
                        len(csv_row) > csv_indices['sku']):
                        
                        csv_sku = csv_row[csv_indices['sku']].strip()
                        gsheet_sku = gsheet_row[gsheet_indices['sku']].strip() if len(gsheet_row) > gsheet_indices['sku'] else ""
                        
                        if csv_sku and (not gsheet_sku or csv_sku != gsheet_sku):
                            updates_needed.append({
                                'column': gsheet_indices['sku'],
                                'value': csv_sku,
                                'field': 'SKU',
                                'old_value': gsheet_sku
                            })
                    
                    # Check Subscription
                    if (csv_indices['subscription'] is not None and 
                        gsheet_indices['subscription'] is not None and 
                        len(csv_row) > csv_indices['subscription']):
                        
                        csv_subscription = csv_row[csv_indices['subscription']].strip()
                        gsheet_subscription = gsheet_row[gsheet_indices['subscription']].strip() if len(gsheet_row) > gsheet_indices['subscription'] else ""
                        
                        if csv_subscription and (not gsheet_subscription or csv_subscription != gsheet_subscription):
                            updates_needed.append({
                                'column': gsheet_indices['subscription'],
                                'value': csv_subscription,
                                'field': 'Subscription',
                                'old_value': gsheet_subscription
                            })
                    
                    # Check autoscale values
                    autoscale_mappings = [
                        ('autoscale_current', 'current', 'Current Capacity'),
                        ('autoscale_min', 'min', 'Min Capacity'),
                        ('autoscale_max', 'max', 'Max Capacity')
                    ]
                    
                    for csv_key, gsheet_key, field_name in autoscale_mappings:
                        if (csv_indices[csv_key] is not None and 
                            gsheet_indices[gsheet_key] is not None and 
                            len(csv_row) > csv_indices[csv_key]):
                            
                            csv_value = csv_row[csv_indices[csv_key]].strip()
                            gsheet_value = gsheet_row[gsheet_indices[gsheet_key]].strip() if len(gsheet_row) > gsheet_indices[gsheet_key] else ""
                            
                            # Only update if CSV has a meaningful value and it's different
                            if csv_value and csv_value.lower() not in ['n/a', '', 'null']:
                                if not gsheet_value or csv_value != gsheet_value:
                                    updates_needed.append({
                                        'column': gsheet_indices[gsheet_key],
                                        'value': csv_value,
                                        'field': field_name,
                                        'old_value': gsheet_value
                                    })
                    
                    # Apply updates if needed
                    if updates_needed:
                        for update in updates_needed:
                            cell_address = f"{sheet_name}!{self._column_number_to_letter(update['column'] + 1)}{gsheet_row_idx}"
                            
                            self.service.spreadsheets().values().update(
                                spreadsheetId=spreadsheet_id,
                                range=cell_address,
                                valueInputOption='RAW',
                                body={'values': [[update['value']]]}
                            ).execute()
                            
                            change_msg = f"Updated {resource_name} -> {update['field']}: '{update['old_value']}' → '{update['value']}'"
                            changes_made.append(change_msg)
                            self.logger.info(change_msg)
                
                else:
                    # Resource not found - provide more detailed logging
                    self.logger.warning(f"No matching row found for CSV resource: '{resource_name}'")
                    self.logger.info(f"Available Google Sheet groups: {[row[gsheet_indices['group']].strip() for row in existing_data[1:] if len(row) > gsheet_indices['group'] and row[gsheet_indices['group']].strip()][:10]}...")
                    
                    # Add to new resources list
                    new_resources.append(csv_row)
                    self.logger.info(f"Will add as new resource: {resource_name}")
            
            # Append new resources at the bottom of the sheet with proper formatting
            if new_resources:
                last_row = len(existing_data) + 1
                formatted_new_resources = []
                
                for resource in new_resources:
                    # Create a new row with the same structure as the Google Sheet
                    new_row = [''] * len(gsheet_header)  # Initialize with empty values
                    
                    # Extract data from CSV row
                    resource_type = resource[0] if len(resource) > 0 else ''
                    resource_name = resource[csv_indices['name']] if len(resource) > csv_indices['name'] else ''
                    resource_sku = resource[csv_indices['sku']] if len(resource) > csv_indices['sku'] else ''
                    resource_subscription = resource[csv_indices['subscription']] if (csv_indices['subscription'] is not None and len(resource) > csv_indices['subscription']) else ''
                    
                    # Fill in the common columns
                    if gsheet_indices['group'] is not None:
                        new_row[gsheet_indices['group']] = resource_name
                    if gsheet_indices['sku'] is not None:
                        new_row[gsheet_indices['sku']] = resource_sku
                    if gsheet_indices['subscription'] is not None:
                        new_row[gsheet_indices['subscription']] = resource_subscription
                    
                    # Find Resource Type column index
                    resource_type_idx = self._find_column_index(gsheet_header, ['Resource Type'], case_sensitive=False)
                    if resource_type_idx is not None:
                        new_row[resource_type_idx] = resource_type
                    
                    # If it's a VMSS, fill in the capacity columns
                    if resource_type.upper() == 'VMSS':
                        if (csv_indices['autoscale_current'] is not None and 
                            len(resource) > csv_indices['autoscale_current'] and
                            resource[csv_indices['autoscale_current']] not in ['N/A', '', 'null']):
                            
                            current_capacity = resource[csv_indices['autoscale_current']].strip()
                            min_capacity = resource[csv_indices['autoscale_min']].strip() if (csv_indices['autoscale_min'] is not None and len(resource) > csv_indices['autoscale_min']) else current_capacity
                            max_capacity = resource[csv_indices['autoscale_max']].strip() if (csv_indices['autoscale_max'] is not None and len(resource) > csv_indices['autoscale_max']) else current_capacity
                            
                            # Clean up N/A values
                            if min_capacity in ['N/A', '', 'null']:
                                min_capacity = current_capacity
                            if max_capacity in ['N/A', '', 'null']:
                                max_capacity = current_capacity
                            
                            if gsheet_indices['current'] is not None:
                                new_row[gsheet_indices['current']] = current_capacity
                            if gsheet_indices['min'] is not None:
                                new_row[gsheet_indices['min']] = min_capacity
                            if gsheet_indices['max'] is not None:
                                new_row[gsheet_indices['max']] = max_capacity
                    
                    formatted_new_resources.append(new_row)
                    
                    # Log what we're adding
                    resource_info = f"{resource_type}: {resource_name}"
                    if resource_type.upper() == 'VMSS' and gsheet_indices['current'] is not None:
                        capacity_info = new_row[gsheet_indices['current']] if new_row[gsheet_indices['current']] else 'N/A'
                        resource_info += f" (capacity: {capacity_info})"
                    change_msg = f"Added new resource: {resource_info}"
                    changes_made.append(change_msg)
                    self.logger.info(change_msg)
                
                # Add the formatted resources to the sheet
                if formatted_new_resources:
                    new_data_range = f"{sheet_name}!A{last_row}"
                    
                    self.service.spreadsheets().values().update(
                        spreadsheetId=spreadsheet_id,
                        range=new_data_range,
                        valueInputOption='RAW',
                        body={'values': formatted_new_resources}
                    ).execute()
                    
                    self.logger.info(f"Added {len(formatted_new_resources)} new resources to the bottom of the sheet")
            
            # Summary
            self.logger.info(f"\n=== UPDATE SUMMARY ===")
            self.logger.info(f"Total changes made: {len(changes_made)}")
            self.logger.info(f"Resources updated: {len(changes_made) - len(new_resources)}")
            self.logger.info(f"New resources added: {len(new_resources)}")
            
            if changes_made:
                self.logger.info("\nDetailed changes:")
                for change in changes_made:
                    self.logger.info(f"  • {change}")
            else:
                self.logger.info("No changes were needed - all data is already up to date!")
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error updating sheet: {e}")
            if "does not have permission" in str(e):
                self.logger.error("Permission denied. Please check:")
                self.logger.error("1. Is the Google Sheet shared with the service account?")
                self.logger.error("2. Does the service account have 'Editor' permissions?")
            return False
    
    def _find_column_index(self, header_row: List[str], search_terms: List[str], case_sensitive: bool = True) -> int:
        """Find column index by searching for terms in header row."""
        for term in search_terms:
            for idx, col_name in enumerate(header_row):
                if case_sensitive:
                    if col_name.strip() == term:
                        return idx
                else:
                    if col_name.strip().lower() == term.lower():
                        return idx
        return None
    
    def _column_number_to_letter(self, column_number: int) -> str:
        """Convert column number to Excel-style letter (1=A, 2=B, etc.)."""
        column_letter = ""
        while column_number > 0:
            column_number -= 1
            column_letter = chr(column_number % 26 + ord('A')) + column_letter
            column_number //= 26
        return column_letter
    
    def update_sheet(self, spreadsheet_id: str, sheet_name: str, csv_file: str, 
                    start_cell: str = 'A1', clear_existing: bool = True) -> bool:
        """Update Google Sheet with data from CSV file - wrapper that chooses update method."""
        
        # Always use selective update method (ignore clear_existing parameter)
        return self.update_sheet_selective(spreadsheet_id, sheet_name, csv_file)
    
    def create_summary_stats(self, csv_file: str) -> Dict[str, int]:
        """Create summary statistics from CSV data."""
        stats = {
            'total_resources': 0,
            'vms': 0,
            'vmss': 0,
            'autoscale_enabled': 0,
            'mysql': 0,
            'postgresql': 0,
            'cosmosdb': 0,
            'sqldb': 0,
            'redis': 0,
            'subscriptions': set()
        }
        
        try:
            with open(csv_file, 'r', encoding='utf-8') as file:
                csv_reader = csv.DictReader(file)
                for row in csv_reader:
                    stats['total_resources'] += 1
                    
                    resource_type = row.get('ResourceType', '').upper()
                    
                    # Handle VM/VMSS resources (for backward compatibility)
                    if resource_type == 'VM':
                        stats['vms'] += 1
                    elif resource_type == 'VMSS':
                        stats['vmss'] += 1
                        if row.get('AutoscaleEnabled', '').lower() == 'true':
                            stats['autoscale_enabled'] += 1
                    
                    # Handle database resources
                    elif resource_type == 'MYSQL':
                        stats['mysql'] += 1
                    elif resource_type == 'POSTGRESQL':
                        stats['postgresql'] += 1
                    elif resource_type == 'COSMOSDB':
                        stats['cosmosdb'] += 1
                    elif resource_type == 'SQLDB':
                        stats['sqldb'] += 1
                    elif resource_type == 'REDIS':
                        stats['redis'] += 1
                    
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
        
        # Show database statistics if any database resources are found
        db_total = stats['mysql'] + stats['postgresql'] + stats['cosmosdb'] + stats['sqldb'] + stats['redis']
        if db_total > 0:
            print(f"MySQL: {stats['mysql']}")
            print(f"PostgreSQL: {stats['postgresql']}")
            print(f"Cosmos DB: {stats['cosmosdb']}")
            print(f"SQL Database: {stats['sqldb']}")
            print(f"Redis: {stats['redis']}")
        
        # Show VM statistics if any VM resources are found (for backward compatibility)
        vm_total = stats['vms'] + stats['vmss']
        if vm_total > 0:
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
