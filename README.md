# O365 Mailbox Audit

PRE REQ's
"Install-Module MSOnline"
Copy MSSKus.csv to C:\

RUN THIS ON AN EXCHANGE SERVER!

This script:
1) Gets AD users
2) Confirms they are in O365
3) Does the user have a license? Prints out which license.
4) Checks if user has a mailbox setup as a remote mailbox in OnPrem Exchange
5) Checks if user has a mailbox in Exchange Online
- This checks Azure AD with the UserPrincipalName. This generally requires everyone to have the same domain in the Account dropdown in AD

ToDo:
- Adjust script to take custom input for user OU's, instead of my guessing game to filter stuff out.
- Test against users with multiple licenses
- Test against clients with more than one UPN in Exchange.


