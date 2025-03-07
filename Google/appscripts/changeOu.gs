/**
 * Change the default OU of users to 
 * Entra ID Automation Users as defined in data.gs.
 */

function changeOu() {
  for (i = 0; i < userMigrationList.length; i++) {
    const justiceDigitalEmailAddress = `${userMigrationList[i].jdeprefix}@${userMigrationList[i].jdesuffix}`;
    const justiceEmailAddress = `${userMigrationList[i].jeprefix}@${userMigrationList[i].jesuffix}`;

    try {

      let user = getUser(justiceEmailAddress)
      user.orgUnitPath = ORG_UNIT_PATH;
      user = AdminDirectory.Users.update(user, user.primaryEmail);
      AddLog(justiceEmailAddress, justiceDigitalEmailAddress, `User ${justiceEmailAddress} OU Updated`, "changeOu", "log");

    } catch (err) {
      AddLog(justiceDigitalEmailAddress, justiceEmailAddress, `Failed to change user ${justiceEmailAddress} OU with error ${err.message}`, "changeOu", "error");
    }
  }
}
