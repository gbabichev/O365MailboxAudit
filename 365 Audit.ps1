<#

## O365 Audit Script
## George Babichev
## 11-20-19
## Version 0.3

# PRE REQ's #
"Install-Module MSOnline"
Copy MSSKus.csv to C:\
# 

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

#>

## Start Parameters
$SKUPath = "C:\MSSKUs.csv"
if (!(Test-Path $SKUPath))
{
    Write-Host "Please place MSSKUs.csv into C:\"
    Exit
}
## End Start Parameters

##Connect to 365 Services
$UserCredential = Get-Credential
Connect-MsolService -Credential $UserCredential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -DisableNameChecking
## End 365

## More Parameters
$CSVPath = "C:\365Audit.csv" # Output file
# Find local AD users, filter out disabled & MS Exchange System Objects
$localADUsers = Get-ADUser -Filter  {(Enabled -eq "True")} | where {($_.distinguishedname -notlike '*Microsoft Exchange System Objects*') -and ($_.UserPrincipalName -ne $null)} | Select-Object UserPrincipalName, Name, Enabled
## End Parameters




$MSSKus = Import-CSV $SKUPath # CSV which holds the MS License SKU's 
Remove-Item -Path $CSVPath -ErrorAction SilentlyContinue # Deletes if one existed
Add-Content -Path $CSVPath -Value '"User","In 365","License?","OnPrem Remote Mailbox?","Mailbox in EO?"' # Creates headers
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn #Imports EX modules.

Function ShowRealMSName {
# Checks MS Account SKU CSV & converts License codes to license names.
    param($MSCodeInput)

    if ($MSCodeInput -eq $null){
        Return "No License"
    }

    $parsedInput = $MSCodeInput.split(':')
    Return $MSSKus | Where-Object {$_.MSCode -like $parsedInput[1]} | Select-Object -ExpandProperty FullName
}

Foreach ($user in $localADUsers){

    $UPN = $user.UserPrincipalName
    $csvEntry = $UPN
    Write-Host "Processing: "$UPN

    $CheckAzureAD = Get-MsolUser -UserPrincipalName $UPN -ErrorAction SilentlyContinue # Checks if account exists in 365

    if ($CheckAzureAD)
    {
    # User exists in Azure AD, lets get what license user has
        $input = $CheckAzureAD.Licenses | Select-Object -ExpandProperty AccountSkuID
        $csvEntry += ",Y,"
        $csvEntry += ShowRealMSName -MSCodeInput $input
    }
    else {
    # User not in Azure AD
        $csvEntry += ",N,No License"
    }
	#----
	# Checking EX On Prem, to see if user is listed as a remote mailbox
    if (Get-RemoteMailbox -Identity $UPN -ErrorAction SilentlyContinue)
    {
		# User exists as a remote mailbox on prem
        $csvEntry += ",Yes"
    }
    else
    {
		# Does not exist as a remote mailbox on prem
        $csvEntry += ",No"
    }
	#----
	# Checking EX Online to see if mailbox exists
    if (Get-Mailbox -Identity $UPN -ErrorAction SilentlyContinue)
    {
		# Mailbox exists in 365
        $csvEntry += ",Yes"
    }
    else
    {
		# Mailbox does not exist in 365
        $csvEntry += ",No"
    }
# Add our findings to CSV
Add-Content -Path $CSVPath -value $csvEntry
}


## Disconnect from 365
# There is no 'Disconnect-MsolService' so we will just skip it
Remove-PSSession $Session
Remove-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
## End 365

