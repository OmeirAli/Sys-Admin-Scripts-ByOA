# Sys-Admin-Scripts-ByOA
 A collection of advanced PowerShell scripts I designed thus far in my IT career to automate, streamline, and enhance various IT administrative tasks, including Active Directory (AD) management, Azure Active Directory (Azure AD) guest account provisioning, Microsoft Teams group creation, and SharePoint group management.

A collection of advanced PowerShell scripts designed to automate, streamline, and enhance various IT administrative tasks, including Active Directory (AD) management, Azure Active Directory (Azure AD) guest account provisioning, Microsoft Teams group creation, and SharePoint group management.

## Scripts

### 1. AD and AzureAD Unlocker.ps1
Unlocks user accounts in both Active Directory (AD) and Azure Active Directory (Azure AD).

- Features comprehensive account unlocking across both on-premises AD and cloud-based Azure AD environments.
- Includes detailed logging for tracking and auditing purposes.

### 2. Add Multiple Users To Same SG.ps1
Adds multiple users to a specified Security Group (SG) in Active Directory.

- Streamlines the bulk addition of users, reducing manual workload.
- Validates user accounts and logs errors to ensure consistent membership management.

### 3. Bulk SharePoint Group Owner Retriever.ps1
Retrieves and exports a list of SharePoint group owners in bulk.

- Queries SharePoint to gather and export ownership data for large sets of groups.
- Generates a comprehensive CSV report, facilitating effective owner management.

### 4. Create Shared Mailbox and Add Multiple Users To It.ps1
Creates a shared mailbox and assigns access to multiple specified users.

- Fully automates the creation process of shared mailboxes, ensuring uniform configurations.
- Grants full mailbox access and Send As permissions to a list of predefined users.

### 5. Delegation Level Retriever.ps1
Retrieves the delegation level to identify an employee's role or level within the company.

- Provides insights into access rights and delegation levels of employees.
- Offers a complete overview of an employee's hierarchical level within the organization.

### 6. Disable Users Fully.ps1
Disables user accounts completely by removing access and setting account flags.

- Automates account disabling, mailbox access removal, and group membership cleanup.
- Logs all actions taken for compliance and audit purposes.

### 7. Dynamic Distribution Group Recipient Filter.ps1
Creates or modifies a dynamic distribution group based on a recipient filter.

- Offers flexibility in defining dynamic membership criteria using custom filters.
- Ensures accurate and up-to-date membership lists for targeted communication.

### 8. Guest Creator.ps1
An advanced end-to-end script that automates the creation of guest accounts in Azure AD.

- Facilitates streamlined guest onboarding with automated invite and provisioning.
- Applies consistent access policies and monitors guest activity for compliance.

### 9. Guest Status Checker.ps1
Checks and reports the status of guest accounts in Azure AD.

- Generates detailed reports on guest account activity and compliance status.
- Identifies inactive or non-compliant guest accounts for appropriate action.

### 10. Lockout Status.ps1
Retrieves and reports the lockout status of user accounts in Active Directory.

- Monitors account lockout events and provides root cause analysis.
- Offers recommendations for resolving recurrent lockout issues.

### 11. Mailbox Hold Management and Archive Activation.ps1
An advanced end-to-end script that manages mailbox holds and activates archives for specific mailboxes.

- Automates mailbox hold application and archiving policy activation.
- Generates comprehensive reports on mailbox holds and archival status for compliance.

### 12. MS Teams Group and Channel Creator.ps1
Automates the creation of Microsoft Teams groups and channels.

- Offers bulk creation of Teams groups and channels with predefined policies.
- Provides flexible channel structures and ensures consistent team configurations.

### 13. Multiple Users SG Checker.ps1
Checks and reports which security groups a list of users are members of.

- Validates user memberships across multiple security groups simultaneously.
- Generates comprehensive membership reports for auditing and compliance.
