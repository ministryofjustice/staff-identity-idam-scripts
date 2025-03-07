/**
 * Get a user by their Google UPN
 */

function getUser(justiceDigitalEmailAddress) {
  try {
    return AdminDirectory.Users.get(justiceDigitalEmailAddress);
  } catch (err) {
    AddLog(justiceDigitalEmailAddress, "", `Failed to get user ${justiceDigitalEmailAddress} with error ${err.message}`, "getUser", "error");
  }
}
