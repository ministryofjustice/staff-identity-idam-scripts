# Access Token Lifetime Policies

Jira Ticket: [IDAM-1743](https://dsdmoj.atlassian.net/browse/IDAM-1743)

## Description

Allows the manipulation of Access Token Lifetime Policies within Entra ID Application Registrations. Scripts include getting existing applications and policies as well as creating and assigning policies. These scripts will mainly be used for situations like extending Token Lifetime from the default 4 hours.

The scripts within this directory allow you to do the following.

| Name | Description | Link |
|------|-------------|------|
| Get all policies | Get all policies available in the tenent. | [Link](./GetPolicies.ps1) |
| Get all policies assigned to Application | Get any policies that are assigned to an Application. If returns no results then it is using the default policy. | [Link](./GetApplicationPolicy.ps1) |
| Create Policy | Creates a new Policy to be used with Application Registrations. Ensure you check for existing policies before creating a new one to reduce technical debt. | [Link](./CreatePolicy.ps1) |
| Assign Policy to Application | Assigns a policy to an Application. You will need to provide the Policy ID, obtained from [GetPolicies.ps1](./GetPolicies.ps1) and the Application ID from Entra ID. | [Link](./AssignPolicyToApplication.ps1) |
