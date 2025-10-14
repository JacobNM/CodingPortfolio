#!/usr/bin/env python3
"""
Debug Column Mapping Script
This script helps debug column mapping issues between CSV and Google Sheets.
"""

import csv
import json
import sys
import os
from typing import List, Dict, Any

def read_csv_debug(csv_file: str) -> tuple:
    """Read CSV file and return header and sample data for debugging."""
    if not os.path.exists(csv_file):
        print(f"❌ CSV file not found: {csv_file}")
        return None, None
    
    try:
        with open(csv_file, 'r', encoding='utf-8') as file:
            csv_reader = csv.reader(file)
            rows = list(csv_reader)
            
        if not rows:
            print("❌ CSV file is empty")
            return None, None
        
        header = rows[0]
        sample_data = rows[1:6] if len(rows) > 1 else []  # First 5 data rows
        
        return header, sample_data
    
    except Exception as e:
        print(f"❌ Error reading CSV: {e}")
        return None, None

def read_gsheet_debug(spreadsheet_id: str, sheet_name: str) -> tuple:
    """Read Google Sheet and return header and sample data for debugging."""
    try:
        from update_gsheet_service_account import GoogleSheetsServiceAccountUpdater
        
        updater = GoogleSheetsServiceAccountUpdater()
        
        if not updater.authenticate():
            print("❌ Google Sheets authentication failed")
            return None, None
        
        # Read sheet data
        range_name = f"{sheet_name}!A:Z"
        sheet_result = updater.service.spreadsheets().values().get(
            spreadsheetId=spreadsheet_id,
            range=range_name
        ).execute()
        
        existing_data = sheet_result.get('values', [])
        if not existing_data:
            print("❌ No data found in Google Sheet")
            return None, None
        
        header = existing_data[0]
        sample_data = existing_data[1:6] if len(existing_data) > 1 else []  # First 5 data rows
        
        return header, sample_data
    
    except ImportError:
        print("❌ Could not import update_gsheet_service_account.py")
        return None, None
    except Exception as e:
        print(f"❌ Error reading Google Sheet: {e}")
        return None, None

def find_column_index_debug(header_row: List[str], search_terms: List[str], case_sensitive: bool = True) -> Dict:
    """Debug version of column finding function."""
    results = {
        'found': False,
        'index': None,
        'matched_term': None,
        'matched_column': None,
        'search_details': []
    }
    
    for term in search_terms:
        for idx, col_name in enumerate(header_row):
            search_detail = {
                'term': term,
                'column_index': idx,
                'column_name': col_name,
                'comparison': f"'{term}' vs '{col_name}'",
                'case_sensitive': case_sensitive
            }
            
            if case_sensitive:
                match = col_name.strip() == term
                search_detail['match_method'] = 'exact (case-sensitive)'
            else:
                match = col_name.strip().lower() == term.lower()
                search_detail['match_method'] = 'exact (case-insensitive)'
            
            search_detail['match'] = match
            results['search_details'].append(search_detail)
            
            if match and not results['found']:
                results['found'] = True
                results['index'] = idx
                results['matched_term'] = term
                results['matched_column'] = col_name
    
    return results

def debug_column_mappings(csv_header: List[str], gsheet_header: List[str]) -> Dict:
    """Create detailed debug information about column mappings."""
    
    print("🔍 DEBUGGING COLUMN MAPPINGS")
    print("=" * 60)
    
    # CSV column mappings
    csv_mappings = {
        'name': ['Name'],
        'sku': ['SKU'],
        'autoscale_min': ['AutoscaleMinCapacity'],
        'autoscale_max': ['AutoscaleMaxCapacity'],
        'autoscale_current': ['AutoscaleDefaultCapacity']
    }
    
    # GSheet column mappings  
    gsheet_mappings = {
        'group': ['Group', 'group'],
        'sku': ['SKU', 'sku'],
        'current': ['current', 'Current', 'curr'],
        'min': ['min', 'Min', 'minimum', 'Minimum'],
        'max': ['max', 'Max', 'maximum', 'Maximum']
    }
    
    print(f"\n📄 CSV HEADER ({len(csv_header)} columns):")
    for i, col in enumerate(csv_header):
        print(f"  [{i:2d}] '{col}'")
    
    print(f"\n📊 GOOGLE SHEET HEADER ({len(gsheet_header)} columns):")
    for i, col in enumerate(gsheet_header):
        print(f"  [{i:2d}] '{col}'")
    
    print(f"\n🔍 CSV COLUMN SEARCHES:")
    csv_results = {}
    for key, search_terms in csv_mappings.items():
        result = find_column_index_debug(csv_header, search_terms, case_sensitive=True)
        csv_results[key] = result
        
        status = "✅ FOUND" if result['found'] else "❌ NOT FOUND"
        print(f"\n  {key.upper()}: {status}")
        if result['found']:
            print(f"    Index: {result['index']}")
            print(f"    Matched: '{result['matched_term']}' → '{result['matched_column']}'")
        else:
            print(f"    Searched for: {search_terms}")
            print(f"    Available columns: {csv_header}")
    
    print(f"\n🔍 GOOGLE SHEET COLUMN SEARCHES:")
    gsheet_results = {}
    for key, search_terms in gsheet_mappings.items():
        result = find_column_index_debug(gsheet_header, search_terms, case_sensitive=False)
        gsheet_results[key] = result
        
        status = "✅ FOUND" if result['found'] else "❌ NOT FOUND"
        print(f"\n  {key.upper()}: {status}")
        if result['found']:
            print(f"    Index: {result['index']}")
            print(f"    Matched: '{result['matched_term']}' → '{result['matched_column']}'")
        else:
            print(f"    Searched for: {search_terms}")
            print(f"    Available columns: {gsheet_header}")
    
    return {
        'csv_results': csv_results,
        'gsheet_results': gsheet_results,
        'csv_header': csv_header,
        'gsheet_header': gsheet_header
    }

def analyze_sample_data(csv_header: List[str], csv_data: List[List[str]], 
                       gsheet_header: List[str], gsheet_data: List[List[str]],
                       mappings: Dict) -> None:
    """Analyze sample data to understand the mapping issues."""
    
    print(f"\n📋 SAMPLE DATA ANALYSIS")
    print("=" * 60)
    
    # Show CSV sample data
    print(f"\n📄 CSV SAMPLE DATA:")
    csv_results = mappings['csv_results']
    
    # Find name column for reference
    name_idx = csv_results['name']['index'] if csv_results['name']['found'] else None
    sku_idx = csv_results['sku']['index'] if csv_results['sku']['found'] else None
    min_idx = csv_results['autoscale_min']['index'] if csv_results['autoscale_min']['found'] else None
    max_idx = csv_results['autoscale_max']['index'] if csv_results['autoscale_max']['found'] else None
    current_idx = csv_results['autoscale_current']['index'] if csv_results['autoscale_current']['found'] else None
    
    for i, row in enumerate(csv_data[:3]):  # Show first 3 rows
        print(f"\n  Row {i+1}:")
        if name_idx is not None and len(row) > name_idx:
            print(f"    Name: '{row[name_idx]}'")
        if sku_idx is not None and len(row) > sku_idx:
            print(f"    SKU: '{row[sku_idx]}'")
        if min_idx is not None and len(row) > min_idx:
            print(f"    Min Capacity: '{row[min_idx]}'")
        if max_idx is not None and len(row) > max_idx:
            print(f"    Max Capacity: '{row[max_idx]}'")
        if current_idx is not None and len(row) > current_idx:
            print(f"    Current Capacity: '{row[current_idx]}'")
    
    # Show Google Sheet sample data
    print(f"\n📊 GOOGLE SHEET SAMPLE DATA:")
    gsheet_results = mappings['gsheet_results']
    
    group_idx = gsheet_results['group']['index'] if gsheet_results['group']['found'] else None
    gsheet_sku_idx = gsheet_results['sku']['index'] if gsheet_results['sku']['found'] else None
    gsheet_min_idx = gsheet_results['min']['index'] if gsheet_results['min']['found'] else None
    gsheet_max_idx = gsheet_results['max']['index'] if gsheet_results['max']['found'] else None
    gsheet_current_idx = gsheet_results['current']['index'] if gsheet_results['current']['found'] else None
    
    for i, row in enumerate(gsheet_data[:3]):  # Show first 3 rows
        print(f"\n  Row {i+1}:")
        if group_idx is not None and len(row) > group_idx:
            print(f"    Group: '{row[group_idx]}'")
        if gsheet_sku_idx is not None and len(row) > gsheet_sku_idx:
            print(f"    SKU: '{row[gsheet_sku_idx]}'")
        if gsheet_min_idx is not None and len(row) > gsheet_min_idx:
            print(f"    Min: '{row[gsheet_min_idx]}'")
        if gsheet_max_idx is not None and len(row) > gsheet_max_idx:
            print(f"    Max: '{row[gsheet_max_idx]}'")
        if gsheet_current_idx is not None and len(row) > gsheet_current_idx:
            print(f"    Current: '{row[gsheet_current_idx]}'")

def suggest_fixes(mappings: Dict) -> None:
    """Suggest fixes based on the mapping analysis."""
    
    print(f"\n🔧 SUGGESTED FIXES")
    print("=" * 60)
    
    csv_results = mappings['csv_results']
    gsheet_results = mappings['gsheet_results']
    
    issues_found = []
    
    # Check CSV mappings
    for key, result in csv_results.items():
        if not result['found']:
            issues_found.append(f"CSV column for '{key}' not found")
    
    # Check GSheet mappings
    for key, result in gsheet_results.items():
        if not result['found']:
            issues_found.append(f"Google Sheet column for '{key}' not found")
    
    if not issues_found:
        print("✅ All required columns found! The issue might be in the data matching logic.")
    else:
        print("❌ Issues found:")
        for issue in issues_found:
            print(f"  • {issue}")
        
        print(f"\n💡 Suggestions:")
        print("1. Check column names in your Google Sheet - they might have different names")
        print("2. Look for extra spaces or special characters in column headers")
        print("3. Consider if columns are grouped under a parent header")
        print("4. Verify the sheet name is correct")
    
    print(f"\n🎯 Next Steps:")
    print("1. Review the column mapping output above")
    print("2. Update your Google Sheet column names if needed")
    print("3. Or modify the search terms in the Python script")

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 debug_column_mapping.py <CSV_FILE> [SPREADSHEET_ID] [SHEET_NAME]")
        print("\nExamples:")
        print("  python3 debug_column_mapping.py inventory.csv")
        print("  python3 debug_column_mapping.py inventory.csv 1ABC...XYZ")
        print("  python3 debug_column_mapping.py inventory.csv 1ABC...XYZ 'Sheet1'")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    spreadsheet_id = sys.argv[2] if len(sys.argv) > 2 else None
    sheet_name = sys.argv[3] if len(sys.argv) > 3 else "Sheet1"
    
    print("🐛 GOOGLE SHEETS COLUMN MAPPING DEBUGGER")
    print("=" * 70)
    
    # Read CSV data
    print(f"\n📄 Reading CSV file: {csv_file}")
    csv_header, csv_data = read_csv_debug(csv_file)
    
    if csv_header is None:
        sys.exit(1)
    
    gsheet_header = None
    gsheet_data = None
    
    # Read Google Sheet data if provided
    if spreadsheet_id:
        print(f"\n📊 Reading Google Sheet: {spreadsheet_id} / {sheet_name}")
        gsheet_header, gsheet_data = read_gsheet_debug(spreadsheet_id, sheet_name)
        
        if gsheet_header is None:
            print("⚠️  Continuing with CSV analysis only...")
    
    # Debug column mappings
    if gsheet_header:
        mappings = debug_column_mappings(csv_header, gsheet_header)
        
        # Analyze sample data
        if csv_data and gsheet_data:
            analyze_sample_data(csv_header, csv_data, gsheet_header, gsheet_data, mappings)
        
        # Suggest fixes
        suggest_fixes(mappings)
    else:
        # CSV only analysis
        print(f"\n📄 CSV ONLY ANALYSIS")
        print("=" * 60)
        print(f"CSV Header ({len(csv_header)} columns):")
        for i, col in enumerate(csv_header):
            print(f"  [{i:2d}] '{col}'")
        
        if csv_data:
            print(f"\nSample CSV data (first 3 rows):")
            for i, row in enumerate(csv_data[:3]):
                print(f"  Row {i+1}: {row}")
    
    print(f"\n✅ Debug analysis complete!")

if __name__ == '__main__':
    main()
