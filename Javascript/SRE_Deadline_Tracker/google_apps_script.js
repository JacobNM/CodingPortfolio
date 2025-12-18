// SRE Deadline Tracker - Google Apps Script
// Configuration - Update these values
const CALENDAR_NAME = '<Your Calendar Name>'; // e.g., 'SRE Deadlines'
const SHEET_NAME = '<Your Sheet Name>'; // Change if your sheet has a different name

function syncDeadlinesToCalendar() {
  try {
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME);
    const calendar = getOrCreateCalendar();
    
    // First update all statuses based on expiry dates
    updateStatusColumn(sheet);
    
    // Clean up any duplicate events before processing
    const duplicatesRemoved = removeDuplicateEvents(calendar);
    if (duplicatesRemoved > 0) {
      Logger.log(`Removed ${duplicatesRemoved} duplicate events from calendar`);
    }
    
    // Get data from sheet (skip header row) - now 10 columns
    const data = sheet.getRange(2, 1, sheet.getLastRow() - 1, 10).getValues();
    
    // Get rich text data to extract hyperlinks from the notes column (column 8) and links column (column 10)
    const notesRichTextData = sheet.getRange(2, 8, sheet.getLastRow() - 1, 1).getRichTextValues();
    const linksRichTextData = sheet.getRange(2, 10, sheet.getLastRow() - 1, 1).getRichTextValues();
    
    // Get existing events to avoid duplicates (refresh after cleanup)
    const existingEvents = getExistingDeadlineEvents(calendar);
    
    // Create or update calendar events
    data.forEach((row, index) => {
      if (row[0] && row[2]) { // Check if item name and expiry date exist
        const notesRichTextValue = notesRichTextData[index] ? notesRichTextData[index][0] : null;
        const linksRichTextValue = linksRichTextData[index] ? linksRichTextData[index][0] : null;
        createOrUpdateDeadlineEvent(calendar, row, existingEvents, notesRichTextValue, linksRichTextValue);
      }
    });
    
    // Optional: Clean up events that are no longer in the sheet
    // Comment out the next line if you don't want to auto-delete orphaned events
    cleanupOrphanedEvents(existingEvents);
    
    Logger.log('Successfully synced deadlines to calendar');
    
  } catch (error) {
    Logger.log('Error syncing deadlines: ' + error.toString());
  }
}

function getOrCreateCalendar() {
  let calendar;
  const calendars = CalendarApp.getCalendarsByName(CALENDAR_NAME);
  
  if (calendars.length > 0) {
    calendar = calendars[0];
  } else {
    calendar = CalendarApp.createCalendar(CALENDAR_NAME);
    Logger.log('Created new calendar: ' + CALENDAR_NAME);
  }
  
  return calendar;
}

function updateStatusColumn(sheet) {
  const lastRow = sheet.getLastRow();
  Logger.log('Last row in sheet: ' + lastRow);
  
  if (lastRow <= 1) {
    Logger.log('No data rows found (only header row or empty sheet)');
    return;
  }
  
  const data = sheet.getRange(2, 1, lastRow - 1, 10).getValues();
  const now = new Date();
  const statusUpdates = [];
  
  Logger.log('Processing ' + data.length + ' data rows');
  
data.forEach((row, index) => {
  const [itemName, type, expiryDate, owner, currentStatus, needsManualAction, autoRenews, renewalActionNotes, priority] = row;
  
  if (expiryDate && expiryDate instanceof Date) {
    const newStatus = calculateStatus(expiryDate, needsManualAction, autoRenews, now);
    statusUpdates.push([newStatus]);
    Logger.log(`Row ${index + 2}: ${itemName} -> ${newStatus}`);
  } else {
    statusUpdates.push([currentStatus || 'Unknown']);
    Logger.log(`Row ${index + 2}: ${itemName} -> ${currentStatus || 'Unknown'} (invalid/missing date)`);
  }
});
  
  // Update the status column (column E, index 5)
  if (statusUpdates.length > 0) {
    sheet.getRange(2, 5, statusUpdates.length, 1).setValues(statusUpdates);
    Logger.log('Updated ' + statusUpdates.length + ' status values');
  }
}

function calculateStatus(expiryDate, needsManualAction, autoRenews, now) {
  const timeDiff = expiryDate.getTime() - now.getTime();
  const daysDiff = Math.ceil(timeDiff / (1000 * 60 * 60 * 24));
  
  // Normalize string values to boolean for logic
  const requiresManualAction = (needsManualAction && needsManualAction.toString().toLowerCase() === 'yes');
  const isAutoRenewing = (autoRenews && autoRenews.toString().toLowerCase() === 'yes');
  
  // If expired
  if (daysDiff < 0) {
    return 'Expired';
  }
  
    // If expiring within 7 days
    if (daysDiff <= 7) {
      if (requiresManualAction) {
        return 'Action Required';
      } else {
        return 'Expiring Soon';
      }
    }
    
    // If expiring within 30 days
    if (daysDiff <= 30) {
      if (requiresManualAction) {
        return 'Action Required';
      } else if (isAutoRenewing) {
        return 'Monitoring';
      } else {
        return 'Expiring Soon';
      }
    }
    
    // If expiring within 90 days and needs manual action
    if (daysDiff <= 90 && requiresManualAction) {
      return 'Monitoring';
    }
    
    // Default status for items with plenty of time
    return 'Active';
}

function createOrUpdateDeadlineEvent(calendar, row, existingEvents, notesRichTextValue = null, linksRichTextValue = null) {
  const [itemName, type, expiryDate, owner, status, needsManualAction, autoRenews, renewalActionNotes, priority, links] = row;
  
  if (!expiryDate instanceof Date) {
    Logger.log('Invalid date for item: ' + itemName);
    return;
  }
  
  // Create more descriptive title based on renewal type
  const isAutoRenewing = (autoRenews && autoRenews.toString().toLowerCase() === 'yes');
  const requiresManualAction = (needsManualAction && needsManualAction.toString().toLowerCase() === 'yes');
  const renewalType = isAutoRenewing ? '(Auto-Renewing)' : requiresManualAction ? '(MANUAL ACTION REQUIRED)' : '';
  const title = `${type}: ${itemName} EXPIRES ${renewalType}`;
  const normalizedTitle = normalizeEventTitle(title);
  const eventKey = `${normalizedTitle}_${expiryDate.toDateString()}`;  // Use normalized title for key
  
  let description = '';
  
  // Add links at the beginning if they exist, preserving hyperlinks
  if (links && links.toString().trim()) {
    const processedLinks = extractLinksFromRichText(linksRichTextValue, links);
    description += `🔗 LINKS & RESOURCES:\n${processedLinks}\n\n`;
  }
  
  description += `
Item: ${itemName}
Type: ${type}
Expiry/Due Date: ${expiryDate.toDateString()}
Owner: ${owner}
Status: ${status}
Priority: ${priority}

Renewal Information:
• Auto Renews: ${autoRenews || 'N/A'}
• Needs Manual Action: ${needsManualAction || 'N/A'}
• Renewal/Action Notes: ${notesRichTextValue ? extractLinksFromRichText(notesRichTextValue, renewalActionNotes) : (renewalActionNotes || 'None')}

This is an automated reminder from the SRE Deadlines tracker.
${requiresManualAction && !isAutoRenewing ? '\n⚠️  MANUAL ACTION REQUIRED - This will not auto-renew!' : ''}
  `.trim();
  
  // Check if event already exists
  if (existingEvents.has(eventKey)) {
    const existingEvent = existingEvents.get(eventKey);
    
    // Smart sync: preserve manual additions while updating generated content
    const currentDescription = existingEvent.getDescription();
    const finalDescription = preserveManualAdditions(currentDescription, description);
    
    if (currentDescription !== finalDescription) {
      existingEvent.setDescription(finalDescription);
      Logger.log('Updated existing event with preserved manual additions: ' + title);
    } else {
      Logger.log('No changes needed for existing event: ' + title);
    }
    
    // Remove from map so we know it's been processed
    existingEvents.delete(eventKey);
  } else {
    // Double-check for duplicates before creating (safety net)
    if (isDuplicateEvent(calendar, title, expiryDate)) {
      Logger.log('Skipping creation of duplicate event: ' + title);
      return;
    }
    
    // Create new event
    const event = calendar.createAllDayEvent(title, expiryDate, {
      description: description
    });
    
    // Add reminders based on priority and renewal type
    addSmartReminders(event, priority, needsManualAction, autoRenews);
    
    Logger.log('Created new event: ' + title);
    Logger.log('Event description set to: ' + description.substring(0, 200) + '...');
  }
}

// Helper function to preserve manual additions while updating generated content
function preserveManualAdditions(currentDescription, newGeneratedDescription) {
  if (!currentDescription) {
    return newGeneratedDescription;
  }
  
  // Look for the end of our generated content - it ends with either:
  // "This is an automated reminder from the SRE Deadlines tracker." or
  // "⚠️  MANUAL ACTION REQUIRED - This will not auto-renew!"
  const generatedEndMarkers = [
    '⚠️  MANUAL ACTION REQUIRED - This will not auto-renew!',
    'This is an automated reminder from the SRE Deadlines tracker.'
  ];
  
  let generatedEndIndex = -1;
  
  for (const marker of generatedEndMarkers) {
    const markerIndex = currentDescription.indexOf(marker);
    if (markerIndex !== -1) {
      // Find the end of this line
      generatedEndIndex = markerIndex + marker.length;
      break;
    }
  }
  
  // If we found the end of generated content, extract any manual additions after it
  let manualAdditions = '';
  if (generatedEndIndex > -1 && generatedEndIndex < currentDescription.length) {
    manualAdditions = currentDescription.substring(generatedEndIndex);
    
    // Clean up: remove leading whitespace but preserve intentional formatting
    manualAdditions = manualAdditions.replace(/^\s*\n/, '\n\n--- Manual Notes ---\n');
    
    // Only keep manual additions if they contain meaningful content
    if (manualAdditions.trim().length > '--- Manual Notes ---'.length) {
      Logger.log('Preserving manual additions: ' + manualAdditions.trim().substring(0, 100) + '...');
      return newGeneratedDescription + manualAdditions;
    }
  }
  
  // No manual additions found, return just the new generated content
  return newGeneratedDescription;
}

// Helper function to extract URLs from Google Sheets hyperlinks
function extractLinksFromRichText(richTextValue, originalText) {
  if (!richTextValue) {
    return originalText || 'None';
  }
  
  let result = originalText || richTextValue.getText();
  const runs = richTextValue.getRuns();
  
  Logger.log('Processing rich text with ' + runs.length + ' runs');
  Logger.log('Original text: ' + result);
  
  runs.forEach((run, index) => {
    const linkUrl = run.getLinkUrl();
    const runText = run.getText();
    
    if (linkUrl) {
      Logger.log(`Found hyperlink in run ${index}: "${runText}" -> ${linkUrl}`);
      
      // Append the URL to the display text if it's not already there
      if (!result.includes(linkUrl)) {
        // Format hyperlinks nicely: "Display Text: URL" or just "URL" if no display text
        const linkFormat = runText.trim() ? `${runText}: ${linkUrl}` : linkUrl;
        result = result.replace(runText, linkFormat);
      }
    }
  });
  
  Logger.log('Final processed text: ' + result);
  return result;
}

// Optional: Clean up events that are no longer in the sheet
function cleanupOrphanedEvents(existingEvents) {
  let removedCount = 0;
  existingEvents.forEach((event, key) => {
    // These events exist in calendar but not in sheet anymore
    event.deleteEvent();
    removedCount++;
    Logger.log('Removed orphaned event: ' + event.getTitle());
  });
  
  if (removedCount > 0) {
    Logger.log('Cleaned up ' + removedCount + ' orphaned events');
  }
}

function addSmartReminders(event, priority, needsManualAction, autoRenews) {
  // Clear default reminders
  event.removeAllReminders();
  
  // Normalize string values to boolean for logic
  const requiresManualAction = (needsManualAction && needsManualAction.toString().toLowerCase() === 'yes');
  const isAutoRenewing = (autoRenews && autoRenews.toString().toLowerCase() === 'yes');
  
  // More aggressive reminders for manual actions
  if (requiresManualAction) {
    switch (priority?.toLowerCase()) {
      case 'high':
        event.addEmailReminder(60 * 24 * 60); // 60 days
        event.addEmailReminder(30 * 24 * 60); // 30 days
        event.addEmailReminder(14 * 24 * 60); // 14 days
        event.addEmailReminder(7 * 24 * 60);  // 7 days
        event.addEmailReminder(3 * 24 * 60);  // 3 days
        event.addEmailReminder(1 * 24 * 60);  // 1 day
        break;
      case 'medium':
        event.addEmailReminder(30 * 24 * 60); // 30 days
        event.addEmailReminder(14 * 24 * 60); // 14 days
        event.addEmailReminder(3 * 24 * 60);  // 3 days
        break;
      case 'low':
      default:
        event.addEmailReminder(14 * 24 * 60); // 14 days
        event.addEmailReminder(7 * 24 * 60);  // 7 days
        break;
    }
  } else if (isAutoRenewing) {
    // Fewer reminders for auto-renewing items (just for awareness)
    switch (priority?.toLowerCase()) {
      case 'high':
        event.addEmailReminder(7 * 24 * 60);  // 7 days
        event.addEmailReminder(1 * 24 * 60);  // 1 day
        break;
      case 'medium':
        event.addEmailReminder(7 * 24 * 60);  // 7 days
        break;
      case 'low':
      default:
        event.addEmailReminder(3 * 24 * 60);  // 3 days
        break;
    }
  } else {
    // Standard reminders for items that don't specify renewal type
    switch (priority?.toLowerCase()) {
      case 'high':
        event.addEmailReminder(30 * 24 * 60); // 30 days
        event.addEmailReminder(14 * 24 * 60); // 14 days
        event.addEmailReminder(7 * 24 * 60);  // 7 days
        event.addEmailReminder(1 * 24 * 60);  // 1 day
        break;
      case 'medium':
        event.addEmailReminder(14 * 24 * 60); // 14 days
        event.addEmailReminder(3 * 24 * 60);  // 3 days
        break;
      case 'low':
      default:
        event.addEmailReminder(7 * 24 * 60);  // 7 days
        break;
    }
  }
}

function getExistingDeadlineEvents(calendar) {
  const now = new Date();
  const fourYearsFromNow = new Date(now.getFullYear() + 4, now.getMonth(), now.getDate());
  const events = calendar.getEvents(now, fourYearsFromNow);
  
  // Create a map of existing events by their identifier
  const existingEvents = new Map();
  
  events.forEach(event => {
    if (event.getTitle().includes('EXPIRES')) {
      // Extract item name from title more reliably
      const title = event.getTitle();
      const date = event.getStartTime().toDateString();
      
      // Create multiple possible keys to catch different title formats
      const normalizedTitle = normalizeEventTitle(title);
      const primaryKey = `${normalizedTitle}_${date}`;
      
      // If we already have an event with this key, we found a potential duplicate
      if (existingEvents.has(primaryKey)) {
        Logger.log(`Potential duplicate detected: ${title} on ${date}`);
      }
      
      existingEvents.set(primaryKey, event);
    }
  });
  
  Logger.log('Found ' + existingEvents.size + ' existing deadline events');
  return existingEvents;
}

// Function to manually trigger sync (for testing)
function manualSync() {
  syncDeadlinesToCalendar();
}

// Function to update only statuses without calendar sync
function updateStatusesOnly() {
  try {
    const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
    Logger.log('Active spreadsheet: ' + spreadsheet.getName());
    
    const sheet = spreadsheet.getSheetByName(SHEET_NAME);
    if (!sheet) {
      Logger.log('Sheet "' + SHEET_NAME + '" not found. Available sheets: ' + spreadsheet.getSheets().map(s => s.getName()).join(', '));
      return;
    }
    
    Logger.log('Found sheet: ' + sheet.getName());
    updateStatusColumn(sheet);
    Logger.log('Status column updated successfully');
  } catch (error) {
    Logger.log('Error updating statuses: ' + error.toString());
  }
}

// Set up automatic daily sync
function createDailyTrigger() {
  // Delete existing triggers
  const triggers = ScriptApp.getProjectTriggers();
  triggers.forEach(trigger => {
    if (trigger.getHandlerFunction() === 'syncDeadlinesToCalendar') {
      ScriptApp.deleteTrigger(trigger);
    }
  });
  
  // Create new daily trigger
  ScriptApp.newTrigger('syncDeadlinesToCalendar')
    .timeBased()
    .everyDays(1)
    .atHour(9) // 9 AM
    .create();
    
  Logger.log('Created daily sync trigger for 9 AM');
}

// Function to remove duplicate events from the calendar
function removeDuplicateEvents(calendar) {
  const now = new Date();
  const fourYearsFromNow = new Date(now.getFullYear() + 4, now.getMonth(), now.getDate());
  const events = calendar.getEvents(now, fourYearsFromNow);
  
  // Group events by normalized identifier
  const eventGroups = new Map();
  
  events.forEach(event => {
    if (event.getTitle().includes('EXPIRES')) {
      const normalizedTitle = normalizeEventTitle(event.getTitle());
      const date = event.getStartTime().toDateString();
      const key = `${normalizedTitle}_${date}`;
      
      if (!eventGroups.has(key)) {
        eventGroups.set(key, []);
      }
      eventGroups.get(key).push(event);
    }
  });
  
  let duplicatesRemoved = 0;
  
  // Remove duplicates, keeping the most recent one
  eventGroups.forEach((eventList, key) => {
    if (eventList.length > 1) {
      Logger.log(`Found ${eventList.length} duplicate events for: ${key}`);
      
      // Sort by creation time (most recent first) and keep the first one
      eventList.sort((a, b) => {
        const aDate = a.getDateCreated() || new Date(0);
        const bDate = b.getDateCreated() || new Date(0);
        return bDate.getTime() - aDate.getTime();
      });
      
      // Delete all but the first (most recent) event
      for (let i = 1; i < eventList.length; i++) {
        try {
          eventList[i].deleteEvent();
          duplicatesRemoved++;
          Logger.log(`Deleted duplicate event: ${eventList[i].getTitle()}`);
        } catch (error) {
          Logger.log(`Error deleting duplicate event: ${error.toString()}`);
        }
      }
    }
  });
  
  return duplicatesRemoved;
}

// Function to normalize event titles for better duplicate detection
function normalizeEventTitle(title) {
  // Remove common variations that might cause false non-matches
  return title
    .replace(/\s*\(Auto-Renewing\)\s*/g, '')
    .replace(/\s*\(MANUAL ACTION REQUIRED\)\s*/g, '')
    .replace(/\s+/g, ' ')
    .trim()
    .toLowerCase();
}

// Standalone function to clean up duplicates (can be run manually)
function cleanupDuplicates() {
  try {
    const calendar = getOrCreateCalendar();
    const duplicatesRemoved = removeDuplicateEvents(calendar);
    
    if (duplicatesRemoved > 0) {
      Logger.log(`Successfully removed ${duplicatesRemoved} duplicate events`);
    } else {
      Logger.log('No duplicate events found');
    }
    
    return duplicatesRemoved;
  } catch (error) {
    Logger.log('Error cleaning up duplicates: ' + error.toString());
    return 0;
  }
}

// Enhanced function to detect potential duplicates before creation
function isDuplicateEvent(calendar, eventTitle, eventDate) {
  const normalizedNewTitle = normalizeEventTitle(eventTitle);
  const newDateString = eventDate.toDateString();
  
  // Get events for the specific date to minimize search scope
  const dayStart = new Date(eventDate);
  dayStart.setHours(0, 0, 0, 0);
  const dayEnd = new Date(eventDate);
  dayEnd.setHours(23, 59, 59, 999);
  
  const eventsOnDate = calendar.getEvents(dayStart, dayEnd);
  
  for (const event of eventsOnDate) {
    if (event.getTitle().includes('EXPIRES')) {
      const normalizedExistingTitle = normalizeEventTitle(event.getTitle());
      
      if (normalizedExistingTitle === normalizedNewTitle) {
        Logger.log(`Duplicate detected: "${eventTitle}" already exists on ${newDateString}`);
        return true;
      }
    }
  }
  
  return false;
}

// Utility function to get summary of upcoming deadlines
function getUpcomingDeadlines() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME);
  const data = sheet.getRange(2, 1, sheet.getLastRow() - 1, 10).getValues();
  
  const now = new Date();
  const thirtyDaysFromNow = new Date(now.getTime() + (30 * 24 * 60 * 60 * 1000));
  
  const upcomingDeadlines = data.filter(row => {
    const expiryDate = new Date(row[2]);
    return expiryDate >= now && expiryDate <= thirtyDaysFromNow;
  });
  
  Logger.log('Upcoming deadlines in next 30 days: ' + upcomingDeadlines.length);
  upcomingDeadlines.forEach(row => {
    const [itemName, type, expiryDate, owner, status, needsManualAction] = row;
    Logger.log(`${itemName} (${type}) - Expiry/Due: ${expiryDate} - Owner: ${owner} - Manual Action: ${needsManualAction || 'N/A'}`);
  });
  
  return upcomingDeadlines;
}