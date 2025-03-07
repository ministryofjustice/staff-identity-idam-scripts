/**
 * Remove the Google Workspace Licence from all users as 
 * defined in data.gs
 */

function removeLicence() {
  for (i = 0; i < userMigrationList.length; i++) {
    const justiceDigitalEmailAddress = `${userMigrationList[i].jdeprefix}@${userMigrationList[i].jdesuffix}`;
    const justiceEmailAddress = `${userMigrationList[i].jeprefix}@${userMigrationList[i].jesuffix}`;

    try {

      AdminLicenseManager.LicenseAssignments.remove(PRODUCT_ID, SKU_ID, justiceEmailAddress);
      AddLog(justiceEmailAddress, justiceDigitalEmailAddress, `User licence removed for: ${justiceEmailAddress}`, "removeLicence", "log");

    } catch (err) {
      AddLog(justiceDigitalEmailAddress, justiceEmailAddress, `Failed for user ${justiceEmailAddress} with error ${err.message}`, "removeLicence", "error");
    }
  }
}
