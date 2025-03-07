/**
 * Change the email address of the Google user to match their
 * Entra ID UPN.
 */

function changeEmailAddress() {
  for (i = 0; i < userMigrationList.length; i++) {
    const justiceDigitalEmailAddress = `${userMigrationList[i].jdeprefix}@${userMigrationList[i].jdesuffix}`;
    const justiceEmailAddress = `${userMigrationList[i].jeprefix}@${userMigrationList[i].jesuffix}`;

    try {
      let user = getUser(justiceDigitalEmailAddress)
      user.primaryEmail = justiceEmailAddress;
      user = AdminDirectory.Users.update(user, justiceDigitalEmailAddress);
      AddLog(justiceDigitalEmailAddress, justiceEmailAddress, `User ${justiceDigitalEmailAddress} email changed to ${justiceEmailAddress}`, "changeEmailAddress", "log");
    } catch (err) {
      AddLog(justiceDigitalEmailAddress, justiceEmailAddress, `Failed to change user email ${justiceDigitalEmailAddress} to ${justiceEmailAddress} with error ${err.message}`, "changeEmailAddress", "error");
    }
  }
}
