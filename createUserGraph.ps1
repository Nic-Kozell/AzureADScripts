Function New-PAAccount {
  param (
    [Parameter (Mandatory = $false)]
    [object] $WebHookData
  )
  $ErrorActionPreference = 'Stop'

  $InputData = ConvertFrom-Json -InputObject $WebHookData
  
  try{
  # region Validating Parameters
  # $InputData = (ConvertFrom-Json -InputObject $WebHookData.RequestBody)  
  [ValidateSet("pa", "test")]
  [Parameter(Mandatory = $false)][string]$AccountType = 'pa'
  [ValidatePattern("^\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$")]
  [Parameter(Mandatory = $true)][string]$UserPrincipalName = $InputData.UserPrincipalName 
  }
  catch{
    Write-Output "Issue validating parameters :"$_
    Exit
  }

  $newUserParams = @{
    accountEnabled    = $true
    displayName       = ""
    mailNickname      = ""
    userPrincipalName = ""
    givenName         = ""
    surname           = ""
    companyName       = ""
    userType          = "Member"
    usageLocation     = "US"
    otherMails        = ""
    showInAddressList = $false
    passwordProfile   = @{
      forceChangePasswordNextSignIn = $true
      password                      = ''
    }
  }
  #endregion Validating Parameters
  #region Account Creation
  try {
    Connect-AzAccount
    $context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
    $token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.microsoft.com/").AccessToken
    
  $authHeader = @{
    'Content-Type'= 'application/json'
    'Authorization'= $token
  }

  }
  catch {
    Write-Output "Issue connecting with managed identity: " $_
    exit
  }

  $domainSuffix = @{
    "aa3f6932-fa7c-47b4-a0ce-a598cad161cf" = "stateoforegon.onmicrosoft.com"
    "3f781cf3-3792-477b-abf5-ff27250dd659" = "oregondoc.onmicrosoft.com"
    "b4f51418-b269-49a2-935a-fa54bf584fc8" = "odemail.onmicrosoft.com"
    "ed20e773-9774-43f4-9113-0bc00d2cbf78" = "oya.onmicrosoft.com"
    "776738eb-4f9b-444f-bc33-4dd4e8e1a9b5" = "oregonstatepolice.onmicrosoft.com"
    "28b0d013-46bc-4a64-8d86-1c8a31cf590d" = "ordot.onmicrosoft.com"
    "860f660b-1578-45aa-8e77-aa9b68a0c0dd" = "oregonpers.onmicrosoft.com"
    "77ff421d-7a2f-4b5b-be44-f7601d4e1685" = "kozelltest.onmicrosoft.com"
  }
  #region Gather User Information
  
  Write-Output "Getting user account"
  try {
    $user = Invoke-RestMethod -Method Get -Headers $authHeader -Uri "https://graph.microsoft.com/v1.0/users/$UserPrincipalName`?`$select=id,givenName,surname,displayName,companyName,userPrincipalName,mail"
     
  }
  catch {
    Write-Error -Message "Error gathering user information: "$_
    Exit
  }
  Write-Output "Building PA account parameters"
  $i = $null
  do {
    $userCheck = $false
    try {
      $paUPNCheck = $("$($AccountType.ToLower())_$($($user.companyName).ToLower())_$(($user.givenName.Substring(0,1)+$user.surname).toLower()+$i)@$($domainSuffix.$($context.tenant.id))") 
      Invoke-RestMethod -Method Get -Headers $authHeader -Uri "https://graph.microsoft.com/v1.0/users/$paUPNCheck" | Out-Null
      $i += 1
    }
    catch {
        $userCheck = $true
    }
  }while ($userCheck -eq $false)

  $newUserParams.UserPrincipalName = $("$($AccountType.ToLower())_$($($user.companyName).ToLower())_$(($user.givenName.Substring(0,1)+$user.surname).toLower()+$i)@$($domainSuffix.$($context.tenant.id))") 
  $newUserParams.GivenName = $user.givenName
  $newUserParams.Surname = $user.surname
  $newUserParams.OtherMails = @($user.mail)
  $newUserParams.DisplayName = "$($AccountType.ToUpper()) * $($($user.companyName).ToUpper()) * $(($user.givenName.Substring(0,1)+$user.surname).toUpper()+$i)"
  $newUserParams.MailNickname = "$($AccountType.ToLower())_$($($user.companyName).ToLower())_$(($user.givenName.Substring(0,1)+$user.surname).toLower()+$i)"
  $newUserParams.companyName = $user.companyName

  Add-Type -AssemblyName System.Web
  $newUserParams.PasswordProfile.Password = [System.Web.Security.Membership]::GeneratePassword(16,2)
  
  #endregion Gather User Information
  #region Create User
  Write-Output "Creating new user $($newUserParams.UserPrincipalName)"
  try {
    $newPaUser = Invoke-RestMethod -Method Post -Uri https://graph.microsoft.com/v1.0/users -Headers $authHeader -Body $(ConvertTo-Json -InputObject $newUserParams)
  }
  catch {
    Write-Error -Message "Error in user creation: " $_
  }

  Write-Output "Setting PA user manager"
  try {
    $userManager = Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/v1.0/users/$($user.id)/manager" -Headers $authHeader 
    $managerUpn = $userManager.userPrincipalName
    # $params = @{
    #   "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($newPaUser.id)"
    # }
    # try {
    #   Invoke-RestMethod -Method Put -Uri "https://graph.microsoft.com/v1.0/users/$($userManager.id)/manager/`$ref" -Headers $authHeader -Body $(ConvertTo-Json $params)
    # }
    # catch {
    #   Write-Error -Message "Error in assigning manager: " $_
    # }  
  }
  catch {
    Write-Error -Message "Error getting manager: " $_
      Write-Output "$($user.userPrincipalName) has no manager listed."
  }

  Write-Output "Set manager for $($newPaUser.UserPrincipalName) to $managerUpn"

$credVar = @"

  $($newPaUser.UserPrincipalName) 
  $($newUserParams.passwordProfile.password)
"@
  return $credVar
}