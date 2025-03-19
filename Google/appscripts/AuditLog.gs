/**
 * Store the AuditLog information in a Google Drive
 * Google Sheet.
 */

const now = new Date();
const formattedDate = now.toISOString();
let sheet = SpreadsheetApp.create(`IdentityMigration-AuditLog_${formattedDate}`).getActiveSheet();
sheet.appendRow(['Justice Digital Email', 'Justice Email', 'Message', 'Function Name', 'Log Type']);
let data = [];

function AddLog(justiceDigitalEmail, justiceEmail, message, functionName, logType) {
  data.push([justiceDigitalEmail, justiceEmail, message, functionName, logType]);
  sheet.getRange(2, 1, data.length, data[0].length).setValues(data);
}
