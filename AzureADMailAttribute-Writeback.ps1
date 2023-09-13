<#
	.SYNOPSIS
	Writes the cloud user object mail attribute back to the on-prem ad user object.
  This script is used in circumstances where an on-prem Exchange server (or Offline Recipient Management via Exchange 2019 Management Tools CU12+) is not being used to stamp the Exchange attributes on an on-prem AD object and no on-prem recipient management is being done. Exchange mailboxes are being entirely managed in the cloud with no customized email address policy.
  Remove -Whatif on Set-ADUser to enable updating the AD user.


	.PARAMETER AzureEnvironmentName
	The Azure cloud environment to connect to. Valud values are: "AzureCloud", "AzureChinaCloud", "AzureUSGovernment", "AzureGermanyCloud"
    If no value is provided it will default to "AzureCloud"
	.PARAMETER TenantID
	The Azure AD tenant ID.
	.PARAMETER credentialAssetName
	The name of the Azure Automation credential (& certificate if using certificate auth).

	#>
Param (
    [parameter(Mandatory = $false)]$AzureEnvironmentName,
    [parameter(Mandatory = $false)]$TenantID,
    [parameter(Mandatory = $false)]$credentialAssetName
)
$Credential = Get-AutomationPSCredential -Name $credentialAssetName
$Certificate = Get-AutomationCertificate -Name $credentialAssetName

if (!(Get-Module -Name "AzureAD")) {
    Import-Module -Name "AzureAD" -Force -MinimumVersion 2.0.2.50 -ErrorAction Stop
}

#Validate possible values for Azure clouds
$AzureEnvironments = @("AzureCloud", "AzureChinaCloud", "AzureUSGovernment", "AzureGermanyCloud")
if ([string]::IsNullOrEmpty($AzureEnvironmentName)) {
    #Default to US Consumer Cloud
    $AzureEnvironmentName = "AzureCloud"
} elseif ($AzureEnvironments -notcontains $AzureEnvironmentName) {
    throw "ERROR: '$AzureEnvironmentName' is not a valid Azure Cloud Environment"
}

#Force TLS 1.2 connection
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Connect to Azure
try { 
    if ($Credential.Username -notmatch '@') {
        # Get Token from Azure Service Principal authentication
        if ($Certificate) {
            $AADCon = Connect-AzureAD -AzureEnvironmentName $AzureEnvironmentName -CertificateThumbprint $Certificate.Thumbprint -ApplicationId $Credential.Username -Tenant $TenantID -ErrorAction Stop
        } else {
            #$AADCon = Connect-AzureAD -AzureEnvironmentName $AzureEnvironmentName -Credential $Credential -Tenant $TenantID -ServicePrincipal -ErrorAction Stop
            #Get Token from Azure Service Principal authentication
            $AzCon = Connect-AzAccount -Credential $Credential -Tenant $TenantID -ServicePrincipal -ErrorAction Stop -Scope Process
            $context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
            $aadToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.windows.net").AccessToken
            $connection = Connect-AzureAD -AadAccessToken $aadToken -AccountId $context.Account.Id -TenantId $context.tenant.id -AzureEnvironmentName $AzureEnvironmentName -ErrorAction Stop
        }
    } else {
        if ($TenantID) {
            $AADCon = Connect-AzureAD -AzureEnvironmentName $AzureEnvironmentName -Credential $Credential -ErrorAction Stop -Tenant $TenantID
        } else {
            $AADCon = Connect-AzureAD -AzureEnvironmentName $AzureEnvironmentName -Credential $Credential -ErrorAction Stop
        }
    }
} catch {
    if ($_.Exception.Message -like '*unknown_user_type: Unknown User Type') {
        throw "ERROR: Service principal authentication failed or incorrect subscription specified"
    } else {
        throw $_
    }
}

$AADusers = Get-AzureADUser -All $true | Where-Object { $_.DirSyncEnabled -eq $true -and $_.AccountEnabled -eq $true }
$connection = @{Server = (Get-ADDomainController -Discover -Writable).Name }

foreach ($AADuser in $AADusers) {
    Write-Verbose "Processing $($AADuser.UserPrincipalName)"
    try { 
        $onpremuser = Get-ADUser @Connection -ErrorAction Stop -Identity $AADuser.OnPremisesSecurityIdentifier 
    } catch {
        Write-Warning "Unable to find user $($AADuser.UserPrincipalName) on server $($connection.server) with SID $($AADuser.OnPremisesSecurityIdentifier)"
        continue
    }
    if ($onpremuser) {
        if ($onpremuser.mail -ne $AADuser.mail) {
            Write-Verbose "Updating mail attribute for:`t$($onpremuser.UserPrincipalName)`t from:`t$($onpremuser.mail)`tto:`t$($aaduser.mail)"
            try { 
                Set-ADUser @Connection -ErrorAction Stop -Identity $onpremuser -EmailAddress $aaduser.mail -WhatIf
            } catch {
                Write-Warning "Unable to update $($onpremuser.UserPrincipalName):`t$($_.Exception.Message -join(";"))"
            }
        }
    }
}

Disconnect-AzureAD
