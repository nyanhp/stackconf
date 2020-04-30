[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $LabName = $env:LabName,

    [Parameter()]
    [ValidateSet('HyperV', 'Azure')]
    [string]
    $VirtualizationEngine = $env:Engine,

    [string]
    $Password = $env:Password
)

Set-PSFConfig -Module 'AutomatedLab' -Name DisableConnectivityCheck -Value $true -PassThru | Register-PSFConfig
Import-Module AutomatedLab

#region Configure the lab
$null = New-Item -ErrorAction SilentlyContinue -Path /AutomatedLab-VMs -ItemType Directory
New-LabDefinition -Name $LabName -DefaultVirtualizationEngine $VirtualizationEngine -VmPath /AutomatedLab-VMs

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2019 Datacenter'
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:Memory' = 3gb
}

if ($VirtualizationEngine -eq 'Azure')
{
    Add-LabAzureSubscription -DefaultLocationName 'West Europe' -SubscriptionName 'JHPaaS'
    $PSDefaultParameterValues['Add-LabMachineDefinition:AzureProperties'] = @{RoleSize = 'Standard_DS2_v2'}
}
#endregion

Add-LabDomainDefinition -Name contoso.com -AdminUser JHP -AdminPassword $Password
Set-LabInstallationCredential -Username JHP -Password $Password

Add-LabMachineDefinition -Name CICD-DC01 -Roles RootDC
Add-LabMachineDefinition -Name CICD-CA01 -Roles CaRoot

# The web server should host our ASP.NET app which we will test with Pester
Add-LabMachineDefinition -Name CICD-WB01 -Roles WebServer

Install-Lab

#region Customizations
Remove-LabPSSession -All

if ($VirtualizationEngine -eq 'Azure')
{
    # All Azure labs use a load balancer - we can add ports to it
    $null = Add-LWAzureLoadBalancedPort -ComputerName CICD-WB01 -Port 4711 -DestinationPort 443
}

Write-Host 'Download NetCore'
$netcore = Get-LabInternetFile -Uri https://download.visualstudio.microsoft.com/download/pr/ff658e5a-c017-4a63-9ffe-e53865963848/15875eef1f0b8e25974846e4a4518135/dotnet-hosting-3.1.3-win.exe -Path $pwd.Path -PassThru -NoDisplay -Force
$thumbprint = (Request-LabCertificate -ComputerName CICD-WB01 -Subject 'CN=*.contoso.com' -TemplateName WebServer -PassThru).Thumbprint

Write-Host 'Copy build output'
Copy-LabFileItem -ComputerName CICD-WB01 -Path ./buildoutput/Api/* -Recurse -DestinationFolderPath C:\inetpub\wwwroot

Write-Host 'Install NetCore'
Install-LabSoftwarePackage -ComputerName CICD-WB01 -Path $netcore.FullName -NoDisplay -CommandLine '/quiet /norestart' -PassThru

Write-Host 'Deploying WebApp'
Invoke-LabCommand -ComputerName CICD-WB01 -ActivityName WebAppDeployment -Variable (Get-Variable thumbprint) -ScriptBlock {
    Get-Website | Remove-WebSite
    New-WebSite -Name AutomatedTest -PhysicalPath C:\inetpub\wwwroot
    New-WebBinding -Name AutomatedTest -Protocol https
    $binding = Get-WebBinding -Name AutomatedTest -Protocol https
    $binding.AddSslCertificate($thumbprint, 'my')
    Start-IISCommitDelay
    $verbs = Get-IISConfigSection -SectionPath 'system.webServer/security/requestFiltering' | Get-IISConfigCollection -CollectionName 'verbs'
    Set-IISConfigAttributeValue -ConfigElement $verbs -AttributeName 'allowUnlisted' -AttributeValue $true
    New-IISConfigCollectionElement -ConfigCollection $verbs -ConfigAttribute @{ 'verb' = 'PUT'; 'allowed' = $true }
    New-IISConfigCollectionElement -ConfigCollection $verbs -ConfigAttribute @{ 'verb' = 'GET'; 'allowed' = $true }
    New-IISConfigCollectionElement -ConfigCollection $verbs -ConfigAttribute @{ 'verb' = 'POST'; 'allowed' = $true }
    New-IISConfigCollectionElement -ConfigCollection $verbs -ConfigAttribute @{ 'verb' = 'DELETE'; 'allowed' = $true }
    Stop-IISCommitDelay
    Get-WebHandler -Name WebDav | Remove-WebHandler
    Get-WebGlobalModule -Name WebDavModule | Remove-WebGlobalModule
}
exit 0
#endregion