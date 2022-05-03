param (
    [Parameter (Mandatory = $true)]
    [object] $WebHookData
)
if ($WebHookData) {
write-output $WebHookData


$InputData = (ConvertFrom-Json -InputObject $WebHookData.RequestBody)

[ValidatePattern("^\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$")]
[Parameter(Mandatory = $true)][string]$UserPrincipalName = $InputData.userPrincipalName
[Parameter(Mandatory = $true)][string]$TenantID = $InputData.tenantId 
$runCounter = 0

Connect-AzAccount -Identity

Switch ($TenantID)
{
	'77ff421d-7a2f-4b5b-be44-f7601d4e1685'{
        $keyAppName = 'kozelltestMfaEnrollmentAppId'
        $keyAppSecretName = 'kozelltestMfaEnrollmentAppSecret'
	}
}

$request = @{
    Method = 'POST'
    URI    = "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token"
    body   = @{
        grant_type    = "client_credentials"
        scope         = "https://graph.microsoft.com/.default"
        client_id     = Get-AzKeyVaultSecret -VaultName kozellvault -Name $keyAppName -AsPlainText
        client_secret = Get-AzKeyVaultSecret -VaultName kozellvault -Name $keyAppSecretName -AsPlainText
    }
}

# Get the access token
$token = (Invoke-RestMethod @request).access_token

$authHeader = @{
'Content-Type'  = 'application/json'
'Authorization' = "bearer $token"
}

$uriString = "https://graph.microsoft.com/beta/reports/credentialUserRegistrationDetails?`$filter=userPrincipalName eq '$UserPrincipalName'"

$mfaEnabled = (Invoke-RestMethod -Method Get -Headers $authHeader -Uri $uriString).value.isMfaRegistered

write-output $UserPrincipalName

return $mfaEnabled
}

# do {
#     $token = (Invoke-RestMethod @request).access_token
#     $authHeader = @{
#         'Content-Type'  = 'application/json'
#         'Authorization' = "bearer $token"
#         }
        
#         $mfaEnabled = (Invoke-RestMethod -Method Get -Headers $authHeader -Uri $uriString).value.isMfaRegistered
        
#         if ( $mfaEnabled -eq $True -and $runCounter -lt 10 ){
#             $runCounter = 10
#             $fromAddress = 'nicholas.kozell@kozelltest.onmicrosoft.com'
#             $toAddress = 'nicholas.kozell@kozelltest.onmicrosoft.com'
#             $mailSubject = "MFA for $UserPrincipalName" 
#             $mailMessage = "MFA has been enabled you can do things now."

#         }
#         elseif ($mfaEnabled -eq $False -and $runCounter -lt 10){
#             $runCounter += 1
#             $fromAddress = 'nicholas.kozell@kozelltest.onmicrosoft.com'
#             $toAddress = 'nicholas.kozell@kozelltest.onmicrosoft.com'
#             $mailSubject = "MFA has not been enrolled"
#             $mailMessage = "MFA has not been enrolled on your PA account $UserPrincipalName FYI no access can be provisioned untill this has been completed. Email $runCounter out of 10."

#         }
#         elseif ($mfaEnabled -eq $False -and $runCounter -eq 10){
#             $runCounter += 1
#             $fromAddress = 'nicholas.kozell@kozelltest.onmicrosoft.com'
#             $toAddress = 'nicholas.kozell@kozelltest.onmicrosoft.com'
#             $mailSubject = "MFA has not been enrolled cancel"
#             $mailMessage = "MFA has not been enrolled and 10 notifications have passed, this Task will now be closed with no further action."
#         }
#         # Build the Microsoft Graph API request
#         $params = @{
#           "URI"         = "https://graph.microsoft.com/v1.0/users/$fromAddress/sendMail"
#           "Headers"     = @{
#             "Authorization" = ("Bearer {0}" -F $token)
#           }
#           "Method"      = "POST"
#           "ContentType" = 'application/json'
#           "Body" = (@{
#             "message" = @{
#               "subject" = $mailSubject
#               "body"    = @{
#                 "contentType" = 'Text'
#                 "content"     = $mailMessage
#               }
#               "toRecipients" = @(
#                 @{
#                   "emailAddress" = @{
#                     "address" = $toAddress
#                   }
#                 }
#               )
#             }
#           }) | ConvertTo-JSON -Depth 10
#         }
        
#         #Send the message
#         Invoke-RestMethod @params -Verbose
#         #endregion
#       Start-Sleep -Seconds 2
    
# } until ($runCounter -eq 11)

    
    