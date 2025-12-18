# SRE Deadline Tracker

A Google Apps Script solution to automatically sync deadline tracking from Google Sheets to Google Calendar for SRE teams.

## Features

- Automatically creates calendar events for deadlines tracked in Google Sheets
- **Automatic status calculation** based on expiry dates and renewal settings
- **Smart event management** - preserves existing events and manual changes
- **Hyperlink processing** - extracts and preserves URLs from Google Sheets rich text
- Smart popup notification system based on priority and renewal type
- Differentiates between auto-renewing and manual action required items
- Daily automatic synchronization
- Customizable reminder schedules
- Efficient sync process that only updates changed items

## Setup Instructions

### 1. Create Google Calendar (If not already created)

1. Go to Google Calendar (calendar.google.com)
2. Create a new calendar named "SRE Deadlines"
3. Share with your SRE team with "Make changes to events" permission

### 2. Create Google Sheet (If not already created)

Create a new Google Sheet with these column headers:

| A | B | C | D | E | F | G | H | I | J |
|---|---|---|---|---|---|---|---|---|---|
| **Item Name** | **Type** | **Expiry/Due Date** | **Owner** | **Status** | **Needs Manual Action** | **Auto Renews** | **Renewal/Action Notes** | **Priority** | **Links/Hyperlinks** |

### 3. Install Google Apps Script

1. In your Google Sheet, go to Extensions → Apps Script
2. Replace the default code with the contents of `google_apps_script.js`
3. Update the configuration variables at the top:
   - `CALENDAR_NAME`: Name of your calendar (default: 'SRE Deadlines')
   - `SHEET_NAME`: Name of your sheet tab (default: 'Sheet1')

### 4. First Run

1. Run the `manualSync()` function to test the integration
2. Grant necessary permissions when prompted
3. Run `createDailyTrigger()` to set up automatic daily syncing at 9 AM

## Column Definitions

- **Item Name**: Descriptive name of the item (e.g., "example.com SSL", "Azure Storage Key")
- **Type**: Category of item (e.g., "SSL Certificate", "Azure Resource", "SSH Key")
- **Expiry/Due Date**: When the item expires or is due (format as date)
- **Owner**: Person responsible for renewal
- **Status**: Current status (automatically calculated based on expiry date and renewal settings)
- **Needs Manual Action**: Yes/No/N/A - requires manual intervention
- **Auto Renews**: Yes/No/N/A - automatically renews itself
- **Renewal/Action Notes**: Additional information about renewal process or required actions (supports hyperlinks which are copied to calendar events)
- **Priority**: High/Medium/Low - affects reminder frequency
- **Links/Hyperlinks**: Important URLs and resources related to the item (appears at the top of calendar events with preserved hyperlink formatting)

## Reminder Schedule

### Items Requiring Manual Action

- **High Priority**: 30, 14, 7, 3, 1 days before
- **Medium Priority**: 30, 14, 3 days before  
- **Low Priority**: 14, 7 days before

### Auto-Renewing Items

- **High Priority**: 7, 1 days before
- **Medium Priority**: 7 days before
- **Low Priority**: 3 days before

### Standard Items

- **High Priority**: 30, 14, 7, 1 days before
- **Medium Priority**: 14, 3 days before
- **Low Priority**: 7 days before

## Functions

- `syncDeadlinesToCalendar()`: Main sync function (runs automatically daily)
- `manualSync()`: Trigger manual sync for testing
- `updateStatusesOnly()`: Update only the status column without calendar sync
- `createDailyTrigger()`: Set up automatic daily sync
- `getUpcomingDeadlines()`: Get summary of deadlines in next 30 days

## Automatic Status Calculation

The script automatically calculates and updates the Status column based on:

- **Expired**: Past the expiry date
- **Action Required**: Expires within 7 days and needs manual action, OR expires within 30 days and needs manual action
- **Expiring Soon**: Expires within 7 days (auto-renewing items), OR expires within 30 days (non-auto-renewing items)
- **Monitoring**: Expires within 30 days (auto-renewing items), OR expires within 90 days (manual action items)
- **Active**: More than 30-90 days remaining (depending on renewal type)

## Smart Calendar Sync

The script uses intelligent event management to maximize efficiency:

- **Preserves Existing Events**: Only creates new events if they don't already exist
- **Non-Destructive Updates**: Updates event descriptions when data changes but preserves manual modifications (attendees, custom reminders, etc.)
- **Orphaned Event Cleanup**: Optionally removes calendar events for items no longer in the spreadsheet
- **Detailed Logging**: Reports exactly what actions were taken (created, updated, or skipped)

## Usage Examples

### SSL Certificate Example

- Item Name: "example.com SSL"
- Type: "SSL Certificate"
- Expiry/Due Date: "2025-03-15"
- Owner: "Jacob"
- Status: "Active"
- Needs Manual Action: No
- Auto Renews: Yes
- Renewal/Action Notes: "Let's Encrypt auto-renewal configured"
- Priority: "High"
- Links/Hyperlinks: "Certificate Portal: <https://portal.example.com>"

### Azure Key Example

- Item Name: "Production Storage Account Key"
- Type: "Azure Resource"
- Expiry/Due Date: "2025-02-01"
- Owner: "Sarah"
- Status: "Action Required" *(auto-calculated)*
- Needs Manual Action: Yes
- Auto Renews: No
- Renewal/Action Notes: "Manual rotation required, update app configs"
- Priority: "High"
- Links/Hyperlinks: "Azure Portal: <https://portal.azure.com> | Documentation: <https://docs.microsoft.com/azure-keys>"

## Troubleshooting

- Check the Apps Script logs for any errors and sync details
- Ensure calendar permissions are correctly set
- Verify date formats in the spreadsheet
- Make sure trigger is active in Apps Script console
- If you need to force recreate all events, comment out the orphaned event cleanup line in the sync function
- Review execution logs to see which events were created, updated, or skipped
