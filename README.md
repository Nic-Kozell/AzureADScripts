# AzureADScripts

# PA account creation module

Run from a desktop to create Azure PA Accounts 

## Description

This module is intended to be run from a desktop and gives the user the PowerShell Commandlet New-PaAccount

## Getting Started

### Dependencies

* Windows 10/11
* Windows PowerShell
* Outlook Client
* DotNet Assemblies used Microsoft.Office.Interop.Outlook and System.Web

### Installing

* Save .psm1 file to Documents\WindowsPowerShell\Modules

### Executing program

* New-PaAccount 
* Expects one paramter WebHookData, expects a Json block of user parameters
* On account creation an output will tell you to apply the user manager in the Azure Portal
* sample-input: 
$json = @"
{
  "UserPrincipalName": 'First.Last@agency.oregon.gov',
  "HomeAgency": 'EIS',
  "SecondaryContact": '5555551234@vtext.net',
  "UserEmail": 'First.Last@agency.oregon.gov',
  "RequestOrTask": 'Task',
  "IsmNumber": 12345
}
"@

## Authors

Contributors names and contact info

Nicholas Kozell  
Nicholas.J.Kozell@das.oregon.gov

## Version History

* 0.1
    * Initial Release
