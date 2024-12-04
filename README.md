# Staff Identity IDAM Scripts

This repo holds PowerShell scripts that are used to manage areas of Entra ID. These scripts should be kept up to date in this locations as the source of truth maintaining an audit trail of changes and detailed explanations of what each one does.

## Structure

Each script should sit within its own folder and include

- README.md
- Associated PowerShell files

The table below should be kept up to date with any additions or removals of scripts.


| Name | Description | Link |
|------|-------------|------|
| Disable M365 Group Creation Assign Security Group | Disables the default setting for allowing all users to be able to create Microsoft 365 Groups. | [Link](./DisableM365GroupCreationAssignSecurityGroup/DisableM365GroupCreationAssignSecurityGroup.ps1) |
| Per User MFA | Allows you to manage Per User MFA for users in the tenent. | [Link](./PerUserMfa) |
| Service Principle | Queries all Service Principles and outputs 4 documents with details on SPs with less than 2 owners and SAML Apps notification emails. | [Link](./SP) |
| Prison Identities | Queries every user in the tenent that belong to a Privately owned prison. Output is saved to a JSON and CSV file for later consumption. | [Link](./PrisonIdentities) |
| Get all users in tenent that are active. | Queries the tenant for all active users and outputs as a JSON and CSV file. | [Link](./AllEnabledUsers.ps1) |
| Access Token Lifetime Policies | Allows the manipulation of Access Token Lifetime Policies within Entra ID Application Registrations. | [Link](./AccessTokenLifetimePolicy) |
